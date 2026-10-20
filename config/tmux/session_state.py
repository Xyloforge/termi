#!/usr/bin/env python3
"""Coordinate resurrect with atomic checkpoints and one restore per server.

Resurrect still owns the snapshot format. Each save runs in an unpublished
folder; only a complete layout + scrollback generation becomes `last`.
"""
import contextlib
import fcntl
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time

HERE = Path(__file__).resolve().parent


def tmux(*args, check=True):
    result = subprocess.run(['tmux', *args], text=True, capture_output=True, timeout=15)
    if check and result.returncode:
        raise RuntimeError(result.stderr.strip() or 'tmux command failed')
    return result.stdout.strip()


def option(name):
    return tmux('show-option', '-gqv', name)


def set_option(name, value):
    tmux('set-option', '-gq', name, str(value))


def storage():
    configured = option('@termi-state-dir') or option('@resurrect-dir')
    if configured:
        return Path(os.path.expandvars(os.path.expanduser(configured)))
    legacy = Path.home() / '.tmux/resurrect'
    data = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share')))
    root = legacy if legacy.is_dir() else data / 'tmux/resurrect'
    # Different tmux servers must never replace each other's snapshots.
    socket = Path(tmux('display-message', '-p', '#{socket_path}'))
    if socket.name != 'default':
        import hashlib
        root = root / 'servers' / hashlib.sha256(str(socket).encode()).hexdigest()[:16]
    return root


@contextlib.contextmanager
def locked(root, blocking=True):
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (root / '.termi.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | (0 if blocking else fcntl.LOCK_NB))
        except BlockingIOError:
            yield False
            return
        yield True


def run_plugin(path):
    if not path or not Path(path).is_file():
        raise RuntimeError('tmux-resurrect is missing; install plugins with Prefix + I')
    # Kill the whole subprocess group on timeout so no late writer can publish.
    with tempfile.TemporaryFile(mode='w+') as output:
        process = subprocess.Popen(['bash', path, 'quiet'], stdout=output,
                                   stderr=output, start_new_session=True)
        try:
            result = process.wait(timeout=180)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise RuntimeError('tmux-resurrect timed out')
        if result:
            output.seek(0)
            raise RuntimeError('tmux-resurrect failed: ' + output.read()[-1500:])


def validate(snapshot, contents=False):
    rows = [line.split('\t') for line in snapshot.read_text().splitlines()]
    panes = [row for row in rows if row[0] == 'pane']
    windows = [row for row in rows if row[0] == 'window']
    if not panes or not windows or any(len(row) < 10 for row in panes) or any(len(row) < 7 for row in windows):
        raise RuntimeError('Incomplete session snapshot; previous checkpoint preserved')
    if not any(row[0] == 'state' for row in rows):
        raise RuntimeError('Session snapshot has no state record')
    if contents:
        with tarfile.open(snapshot.parent / 'pane_contents.tar.gz', 'r:gz') as archive:
            # Read every member, including the gzip trailer, to detect truncation.
            for member in archive:
                if member.isfile():
                    with archive.extractfile(member) as stream:
                        while stream.read(1024 * 1024):
                            pass
    return rows


def atomic_link(path, target):
    temporary = path.with_name('.' + path.name + f'.{os.getpid()}')
    try:
        temporary.symlink_to(target)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def sync_directory(path):
    fd = os.open(path, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def topology():
    return tmux('list-panes', '-a', '-F', '#{session_id}:#{window_id}:#{pane_id}').splitlines()


class LayoutChanged(RuntimeError):
    pass


def save(root, delayed=False, blocking=True):
    # Wait *inside* the lock: a burst of events needs only one capture.
    with locked(root, blocking=blocking) as acquired:
        if not acquired or option('@termi-session-ready') != '1':
            return
        if delayed:
            time.sleep(1)
        for attempt in range(3):
            try:
                save_checkpoint(root)
                return True
            except LayoutChanged:
                if attempt == 2:
                    raise
                time.sleep(1)


def save_checkpoint(root):
    stage = Path(tempfile.mkdtemp(prefix='.termi-stage-', dir=root))
    try:
        before = topology()
        set_option('@resurrect-dir', stage)
        run_plugin(option('@termi-save-script') or option('@resurrect-save-script-path'))
        snapshot = (stage / 'last').resolve(strict=True)
        rows = validate(snapshot, option('@resurrect-capture-pane-contents') == 'on')
        if before != topology():
            raise LayoutChanged('Layout kept changing during save; previous checkpoint preserved')
        # Remember actual user focus, rather than whichever client a
        # background `display-message` happens to resolve.
        session_id = option('@termi-last-session')
        if session_id:
            name = tmux('display-message', '-p', '-t', session_id, '#{session_name}', check=False)
            if name and name in {row[1] for row in rows if row[0] in ('pane', 'grouped_session')}:
                lines = snapshot.read_text().splitlines()
                snapshot.write_text('\n'.join('state\t' + name + '\t' if line.startswith('state\t') else line for line in lines) + '\n')
        for path in stage.iterdir():
            if path.is_file() and not path.is_symlink():
                with path.open('rb') as stream:
                    os.fsync(stream.fileno())
        generation = root / ('termi-checkpoint-' + str(time.time_ns()))
        stage.rename(generation)
        sync_directory(generation)
        # `last` is the commit point. Restore resolves its generation so
        # layout and scrollback always come from the same completed save.
        atomic_link(root / 'last', str(generation.relative_to(root) / snapshot.name))
        sync_directory(root)
        set_option('@termi-last-save', int(time.time()))
        set_option('@termi-session-error', '')
        # Keep legacy snapshots untouched and the latest 20 generations.
        generations = sorted(root.glob('termi-checkpoint-*'), reverse=True)
        for old in generations[20:]:
            if old.is_dir() and not old.is_symlink():
                shutil.rmtree(old)
    finally:
        set_option('@resurrect-dir', root)
        if stage.exists():
            shutil.rmtree(stage)


def restore(root, startup=False):
    with locked(root):
        if startup and option('@termi-restore-pending') != '1':
            return
        set_option('@termi-session-ready', '0')
        set_option('@termi-restore-pending', '0')
        snapshot_link = root / 'last'
        if not snapshot_link.exists():
            if snapshot_link.is_symlink():
                raise RuntimeError('Saved session link is broken; automatic saving paused')
            set_option('@termi-session-ready', '1')
            return
        set_option('@termi-session-ready', '0')
        snapshot = snapshot_link.resolve(strict=True)
        generation = snapshot.parent
        # Old resurrect snapshots keep the archive alongside `last` too.
        rows = validate(snapshot, option('@resurrect-capture-pane-contents') == 'on' and (generation / 'pane_contents.tar.gz').exists())
        try:
            set_option('@resurrect-dir', generation)
            run_plugin(option('@termi-restore-script'))
            expected = {(row[1], row[2], row[5]) for row in rows if row[0] == 'pane'}
            actual = {tuple(line.split('\t')) for line in tmux(
                'list-panes', '-a', '-F', '#{session_name}\t#{window_index}\t#{pane_index}').splitlines()}
            if not expected.issubset(actual):
                raise RuntimeError('Restore is incomplete; automatic saving paused to preserve the checkpoint')
            saved_session = next((row[1] for row in rows if row[0] == 'state' and len(row) > 1), '')
            sessions = dict(line.split('\t', 1) for line in tmux(
                'list-sessions', '-F', '#{session_name}\t#{session_id}').splitlines())
            if saved_session in sessions:
                set_option('@termi-last-session', sessions[saved_session])
            set_option('@termi-session-ready', '1')
            set_option('@termi-session-error', '')
        finally:
            set_option('@resurrect-dir', root)


def initialize():
    if not tmux('list-sessions', '-F', '#{session_id}', check=False):
        return  # Initial config runs before new-session; finish on client attach.
    root = storage()
    with locked(root):
        set_option('@termi-state-dir', root)
        set_option('@resurrect-dir', root)
        raw_save = option('@resurrect-save-script-path')
        raw_restore = option('@resurrect-restore-script-path')
        if raw_save and raw_save != str(HERE / 'session_save.sh'):
            set_option('@termi-save-script', raw_save)
        if raw_restore:
            set_option('@termi-restore-script', raw_restore)
        set_option('@resurrect-save-script-path', HERE / 'session_save.sh')
        # Reloading configuration must never replay an older snapshot over live work.
        if option('@termi-session-ready'):
            return
        set_option('@termi-session-ready', '0')
    started = int(tmux('display-message', '-p', '#{start_time}'))
    requested = tmux('show-environment', '-g', 'TERMI_BOOTSTRAP', check=False) == 'TERMI_BOOTSTRAP=1'
    tmux('set-environment', '-gu', 'TERMI_BOOTSTRAP')
    if requested or time.time() - started <= 15:
        # Configuration is loaded before new-session creates its first pane.
        # Restore on attach, after that bootstrap exists, so it can be removed.
        set_option('@termi-restore-pending', '1')
        if tmux('list-clients', '-F', '#{client_name}'):
            restore(root)
    else:
        set_option('@termi-session-ready', '1')


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'save'
    try:
        if action == 'init':
            initialize()
        elif action in ('save', 'event', 'auto', 'detach'):
            if option('@termi-session-ready') == '1':
                saved = save(storage(), delayed=action == 'event', blocking=action in ('save', 'detach'))
                if action == 'save' and saved:
                    tmux('display-message', 'Termi session saved')
            elif action == 'save':
                raise RuntimeError('Saving is paused until session recovery succeeds')
        elif action == 'attach':
            initialize()
            if option('@termi-restore-pending') == '1':
                restore(storage(), startup=True)
        elif action == 'restore':
            restore(storage())
        else:
            raise RuntimeError('Unknown session action: ' + action)
    except Exception as error:
        message = str(error)
        print('Termi session: ' + message, file=sys.stderr)
        try:
            set_option('@termi-session-error', message)
            tmux('display-message', 'Termi session: ' + message, check=False)
        except Exception:
            pass
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
