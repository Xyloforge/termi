"""Integration regressions on private tmux sockets; never uses the user's server."""
import os
import pathlib
import pty
import shlex
import shutil
import subprocess
import tempfile
import threading
import time
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
TMUX = shutil.which('tmux')

class TmuxTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='termi-test-')
        self.base = pathlib.Path(self.tmp.name).resolve()
        self.socket = str(self.base / 'socket')
        self.env = dict(os.environ, TMUX='', TERM='xterm-256color')
        self.env.pop('TMUX_PANE', None)
        config = (ROOT / 'config/tmux/tmux.conf').read_text()
        config = '\n'.join(line for line in config.splitlines() if not line.startswith(("run '~/.tmux/plugins/tpm/tpm'", "run-shell 'python3", "set-hook -g client-attached[40]", "set-hook -g after-new-session[40]")))
        config = config.replace('~/.config/tmux/', str(ROOT / 'config/tmux') + '/')
        self.config = self.base / 'tmux.conf'
        config += '\nset -g @termi-state-dir \"' + str(self.base / 'state') + '\"\n'
        self.config.write_text(config)
        self.t('new-session', '-d', '-s', 'alpha', '-x', '120', '-y', '40', 'sleep 600')
        self.t('set-option', '-g', 'default-command', 'sleep 600')
        self.t('set-option', '-g', '@termi-state-dir', str(self.base / 'state'))
        self.env['TMUX'] = self.t('display-message', '-p', '#{socket_path},#{pid},0')
        self.clients = []

    def tearDown(self):
        self.t('set-option', '-g', '@termi-session-ready', '0', check=False)
        time.sleep(.1)
        self.t('kill-server', check=False)
        for process, master in self.clients:
            process.wait(timeout=5)
            os.close(master)
        self.tmp.cleanup()

    def t(self, *args, check=True):
        result = subprocess.run([TMUX, '-S', self.socket, '-f', str(self.config), *args], env=self.env, text=True, capture_output=True, timeout=15)
        if check and result.returncode:
            self.fail(f'tmux {args}: {result.stderr}')
        return result.stdout.strip()

    @staticmethod
    def drain(master):
        # A real terminal continuously reads output. Without this, a full PTY
        # buffer can block tmux redraw/exit and make otherwise correct tests flaky.
        def read():
            try:
                while os.read(master, 65536):
                    pass
            except OSError:
                pass
        threading.Thread(target=read, daemon=True).start()

    def client(self, session):
        master, slave = pty.openpty()
        process = subprocess.Popen([TMUX, '-S', self.socket, 'attach-session', '-t', session], stdin=slave, stdout=slave, stderr=slave, env=self.env, start_new_session=True)
        tty = os.ttyname(slave)
        os.close(slave)
        self.clients.append((process, master))
        self.drain(master)
        for _ in range(100):
            if tty in self.t('list-clients', '-F', '#{client_name}').splitlines():
                return master, tty
            time.sleep(.02)
        self.fail('client failed to attach')

    def key(self, master, value):
        os.write(master, value)
        time.sleep(.3)

    def test_splits_and_new_windows_follow_focused_pane_after_cd(self):
        master, tty = self.client('alpha')
        start = self.base / 'starting directory'
        start.mkdir()
        for key, direction in ((b'\x00%', 'right'), (b'\x00"', 'down'), (b'\x00c', 'window')):
            with self.subTest(direction=direction):
                current = self.base / (direction + " directory with ' quote")
                current.mkdir()
                source = self.t('new-window', '-t', 'alpha', '-c', str(start), '-P', '-F', '#{pane_id}', '/bin/sh')
                window = self.t('display-message', '-p', '-t', source, '#{window_id}')
                self.t('send-keys', '-t', source, '-l', 'cd ' + shlex.quote(str(current)))
                self.t('send-keys', '-t', source, 'Enter')
                for _ in range(100):
                    if self.t('display-message', '-p', '-t', source, '#{pane_current_path}') == str(current):
                        break
                    time.sleep(.02)
                self.assertEqual(self.t('display-message', '-p', '-t', source, '#{pane_current_path}'), str(current))

                self.key(master, key)
                created = self.t('display-message', '-p', '-t', 'alpha', '#{pane_id}')
                self.assertNotEqual(created, source)
                self.assertEqual(self.t('display-message', '-p', '-t', created, '#{pane_current_path}'), str(current))
                created_window = self.t('display-message', '-p', '-t', created, '#{window_id}')
                if direction == 'window':
                    self.assertNotEqual(created_window, window)
                else:
                    self.assertEqual(created_window, window)
                    source_xy = self.t('display-message', '-p', '-t', source, '#{pane_left}:#{pane_top}')
                    created_xy = self.t('display-message', '-p', '-t', created, '#{pane_left}:#{pane_top}')
                    sx, sy = map(int, source_xy.split(':'))
                    cx, cy = map(int, created_xy.split(':'))
                    if direction == 'right':
                        self.assertGreater(cx, sx)
                        self.assertEqual(cy, sy)
                    else:
                        self.assertEqual(cx, sx)
                        self.assertGreater(cy, sy)

    def test_previous_window_tracks_navigation(self):
        master, tty = self.client('alpha')
        first = self.t('display-message', '-p', '-t', 'alpha', '#{window_id}')
        second = self.t('new-window', '-P', '-F', '#{window_id}', '-t', 'alpha')
        self.key(master, b'\x00a')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_id}'), first)
        self.key(master, b'\x00a')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_id}'), second, self.t('show-options', '-g').split('activity-action')[0])

    def test_zoom_after_resize_repeat(self):
        master, tty = self.client('alpha')
        pane = self.t('split-window', '-h', '-P', '-F', '#{pane_id}', '-t', 'alpha')
        self.key(master, b'\x00H')
        self.key(master, b'\x00z')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_zoomed_flag}:#{pane_id}'), '1:' + pane)
        self.key(master, b'\x00z')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_zoomed_flag}'), '0')

    def test_zoom_is_client_local(self):
        first, first_tty = self.client('alpha')
        pane = self.t('split-window', '-h', '-P', '-F', '#{pane_id}', '-t', 'alpha')
        self.t('new-session', '-d', '-s', 'beta', 'sleep 600')
        second, second_tty = self.client('beta')
        self.t('split-window', '-h', '-t', 'beta')
        self.key(first, b'\x00z')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_zoomed_flag}:#{pane_id}'), '1:' + pane)
        self.assertEqual(self.t('display-message', '-p', '-t', 'beta', '#{window_zoomed_flag}'), '0')

    def test_recent_layout_is_saved_without_waiting_five_minutes(self):
        fake = self.base / 'save.sh'
        fake.write_text('#!/bin/sh\ntmux list-panes -a -F "#{pane_id}" > "' + str(self.base / 'saved') + '"\n')
        fake.chmod(0o755)
        self.t('set-option', '-g', '@resurrect-save-script-path', str(fake))
        self.t('set-option', '-g', '@termi-session-ready', '1')
        self.t('split-window', '-h', '-t', 'alpha')
        saved = self.base / 'saved'
        for _ in range(150):
            if saved.exists() and saved.stat().st_size:
                break
            time.sleep(.02)
        self.assertTrue(saved.exists(), 'Layout change was not checkpointed')
        self.assertEqual(len(saved.read_text().splitlines()), 2)

    def test_previous_window_survives_renumbering_and_closed_target(self):
        master, tty = self.client('alpha')
        first = self.t('display-message', '-p', '-t', 'alpha', '#{window_id}')
        second = self.t('new-window', '-P', '-F', '#{window_id}', '-t', 'alpha')
        third = self.t('new-window', '-P', '-F', '#{window_id}', '-t', 'alpha')
        self.t('kill-window', '-t', first)
        self.key(master, b'\x00a')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_id}'), second, self.t('show-options', '-g').split('activity-action')[0])
        self.t('kill-window', '-t', third)
        self.key(master, b'\x00a')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_id}'), second, self.t('show-options', '-g').split('activity-action')[0])

    def test_cross_session_history_is_per_client(self):
        first, first_tty = self.client('alpha')
        self.t('new-session', '-d', '-s', 'beta', 'sleep 600')
        self.t('new-session', '-d', '-s', 'gamma', 'sleep 600')
        second, second_tty = self.client('gamma')
        self.t('switch-client', '-c', first_tty, '-t', 'beta')
        self.t('new-window', '-t', 'gamma')
        self.assertEqual(self.t('display-message', '-p', '-t', '$0:@0', '#{window_id}'), '@0')
        self.key(first, b'\x00a')
        clients = self.t('list-clients', '-F', '#{client_name}|#{session_name}').splitlines()
        self.assertIn(first_tty + '|alpha', clients, self.t('show-options', '-g').split('activity-action')[0])
        self.assertIn(second_tty + '|gamma', clients)
        self.key(first, b'\x00a')
        self.assertIn(first_tty + '|beta', self.t('list-clients', '-F', '#{client_name}|#{session_name}').splitlines())

    def test_auto_resize_does_not_cancel_manual_zoom_or_touch_other_client(self):
        first, tty = self.client('alpha')
        pane = self.t('split-window', '-h', '-P', '-F', '#{pane_id}', '-t', 'alpha')
        self.t('new-session', '-d', '-s', 'beta', 'sleep 600')
        second, other_tty = self.client('beta')
        self.t('split-window', '-h', '-t', 'beta')
        layout = self.t('display-message', '-p', '-t', 'beta', '#{window_layout}')
        self.t('resize-pane', '-Z', '-t', pane)
        subprocess.run(['bash', str(ROOT / 'config/tmux/auto_resize.sh'), 'in', pane], env=self.env, check=True)
        subprocess.run(['bash', str(ROOT / 'config/tmux/auto_resize.sh'), 'out', pane], env=self.env, check=True)
        self.assertEqual(self.t('display-message', '-p', '-t', pane, '#{window_zoomed_flag}'), '1')
        self.assertEqual(self.t('display-message', '-p', '-t', 'beta', '#{window_layout}'), layout)

    def plugin_setup(self):
        override = os.environ.get('TERMI_RESURRECT_PATH')
        candidates = [pathlib.Path(override)] if override else [pathlib.Path.home() / '.config/tmux/plugins/tmux-resurrect', pathlib.Path.home() / '.tmux/plugins/tmux-resurrect']
        plugin = next((p for p in candidates if (p / 'scripts/save.sh').is_file()), None)
        if not plugin:
            self.skipTest('Install tmux-resurrect or set TERMI_RESURRECT_PATH for restart integration tests')
        self.t('set-option', '-g', '@termi-save-script', str(plugin / 'scripts/save.sh'))
        self.t('set-option', '-g', '@termi-restore-script', str(plugin / 'scripts/restore.sh'))
        self.t('set-option', '-g', '@resurrect-capture-pane-contents', 'on')
        self.t('set-option', '-g', '@resurrect-processes', 'false')
        self.t('set-option', '-g', '@resurrect-dir', str(self.base / 'state'))

    def state(self, action, check=True):
        result = subprocess.run([shutil.which('python3'), str(ROOT / 'config/tmux/session_state.py'), action], env=self.env, text=True, capture_output=True, timeout=30)
        if check and result.returncode:
            self.fail(result.stderr)
        return result

    def restart(self):
        self.t('set-option', '-g', '@termi-session-ready', '0')
        self.t('kill-server')
        for process, master in self.clients:
            process.wait(timeout=5)
            os.close(master)
        self.clients.clear()
        time.sleep(.1)
        self.env['TMUX'] = ''
        self.t('new-session', '-d', '-s', '0', '-x', '120', '-y', '40', 'sleep 600')
        self.t('set-option', '-g', 'default-command', 'sleep 600')
        self.env['TMUX'] = self.t('display-message', '-p', '#{socket_path},#{pid},0')
        self.plugin_setup()
        self.client('0')
        self.state('restore')

    def test_two_restarts_restore_newest_checkpoint_and_focused_session(self):
        self.plugin_setup()
        first, tty = self.client('alpha')
        self.t('split-window', '-h', '-t', 'alpha')
        self.t('new-session', '-d', '-s', 'beta', 'sleep 600')
        self.t('switch-client', '-c', tty, '-t', 'beta')
        self.t('set-option', '-g', '@termi-session-ready', '1')
        self.state('save')
        root = self.base / 'state'
        old = (root / 'last').resolve()
        self.restart()
        self.assertEqual(self.t('list-sessions', '-F', '#{session_name}').splitlines(), ['alpha', 'beta'])
        self.assertEqual(len(self.t('list-panes', '-a').splitlines()), 3)
        self.assertEqual(self.t('list-clients', '-F', '#{session_name}'), 'beta')
        self.t('set-option', '-g', '@termi-session-ready', '0')
        self.t('new-window', '-t', 'beta', '-n', 'LATEST')
        self.t('split-window', '-h', '-t', 'beta:LATEST')
        self.t('set-option', '-g', '@termi-session-ready', '1')
        self.state('save')
        self.assertNotEqual((root / 'last').resolve(), old)
        self.restart()
        self.assertEqual(len(self.t('list-panes', '-a').splitlines()), 5)
        self.assertEqual(self.t('display-message', '-p', '-t', 'beta', '#{window_name}'), 'LATEST')
        self.assertEqual(self.t('list-clients', '-F', '#{session_name}'), 'beta')

    def test_failed_save_cannot_replace_last_complete_checkpoint(self):
        self.plugin_setup()
        self.client('alpha')
        self.t('set-option', '-g', '@termi-session-ready', '1')
        self.state('save')
        original = (self.base / 'state/last').resolve()
        failure = self.base / 'broken-save.sh'
        failure.write_text('#!/bin/sh\ndir=$(tmux show-option -gqv @resurrect-dir)\nprintf "pane\\tpartial\\n" > "$dir/broken.txt"\nln -s broken.txt "$dir/last"\n')
        self.t('set-option', '-g', '@termi-save-script', str(failure))
        self.assertNotEqual(self.state('save', check=False).returncode, 0)
        self.assertEqual((self.base / 'state/last').resolve(), original)
        self.assertEqual(self.t('show-option', '-gqv', '@resurrect-dir'), str(self.base / 'state'))
        self.restart()
        self.assertEqual(self.t('list-sessions', '-F', '#{session_name}'), 'alpha')

    def test_config_reload_does_not_restore_old_snapshot(self):
        self.plugin_setup()
        self.t('set-option', '-g', '@termi-session-ready', '1')
        self.state('save')
        self.t('new-window', '-t', 'alpha', '-n', 'UNSAVED')
        self.state('init')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{window_name}'), 'UNSAVED')

    def test_full_config_startup_restores_once_before_saving(self):
        self.plugin_setup()
        tpm = pathlib.Path.home() / '.tmux/plugins/tpm/tpm'
        if not tpm.exists():
            self.skipTest('TPM is required for full startup integration')
        self.client('alpha')
        self.t('split-window', '-h', '-t', 'alpha')
        self.t('set-option', '-g', '@termi-session-ready', '1')
        self.state('save')
        snapshot = (self.base / 'state/last').resolve()
        self.t('set-option', '-g', '@termi-session-ready', '0')
        self.t('kill-server')
        for process, master in self.clients:
            process.wait(timeout=5)
            os.close(master)
        self.clients.clear()
        time.sleep(.1)
        full = (ROOT / 'config/tmux/tmux.conf').read_text().replace('~/.config/tmux/', str(ROOT / 'config/tmux') + '/')
        full = 'set -g @termi-state-dir "' + str(self.base / 'state') + '"\nset -g default-command "sleep 600"\n' + full
        self.config.write_text(full)
        env = dict(self.env, TMUX='', TERMI_BOOTSTRAP='1')
        master, slave = pty.openpty()
        process = subprocess.Popen([TMUX, '-S', self.socket, '-f', str(self.config), 'new-session', '-A', '-s', '0'], stdin=slave, stdout=slave, stderr=slave, env=env, start_new_session=True)
        os.close(slave)
        self.clients.append((process, master))
        self.drain(master)
        for _ in range(250):
            if self.t('show-option', '-gqv', '@termi-session-ready', check=False) == '1':
                break
            time.sleep(.02)
        self.assertEqual(self.t('show-option', '-gqv', '@termi-session-ready'), '1', self.t('show-option', '-gqv', '@termi-session-error'))
        self.assertEqual(self.t('list-sessions', '-F', '#{session_name}'), 'alpha')
        self.assertEqual(len(self.t('list-panes', '-a').splitlines()), 2)
        self.assertEqual((self.base / 'state/last').resolve(), snapshot)
        self.t('source-file', str(self.config))
        self.assertEqual(len(self.t('list-panes', '-a').splitlines()), 2)
        self.assertEqual(self.t('show-option', '-gqv', '@resurrect-save-script-path'), str(ROOT / 'config/tmux/session_save.sh'))

    def test_broken_restore_pauses_saving_and_keeps_evidence(self):
        self.plugin_setup()
        root = self.base / 'state'
        root.mkdir(exist_ok=True)
        (root / 'last').symlink_to('missing-snapshot')
        self.t('set-option', '-g', '@termi-session-ready', '1')
        self.assertNotEqual(self.state('restore', check=False).returncode, 0)
        self.assertEqual(self.t('show-option', '-gqv', '@termi-session-ready'), '0')
        self.state('auto')
        self.assertEqual(os.readlink(root / 'last'), 'missing-snapshot')

    def test_event_burst_coalesces_into_one_checkpoint(self):
        self.plugin_setup()
        self.t('set-option', '-g', '@termi-session-ready', '1')
        for i in range(5):
            self.t('new-window', '-t', 'alpha', '-n', 'burst' + str(i))
        for _ in range(300):
            if self.t('show-option', '-gqv', '@termi-last-save'):
                break
            time.sleep(.02)
        self.assertEqual(len(list((self.base / 'state').glob('termi-checkpoint-*'))), 1)
        rows = (self.base / 'state/last').read_text().splitlines()
        self.assertEqual(sum(row.startswith('pane\t') for row in rows), 6)

    def test_pane_picker_keeps_already_focused_pane_zoomed(self):
        self.client('alpha')
        pane = self.t('split-window', '-h', '-P', '-F', '#{pane_id}', '-t', 'alpha')
        window = self.t('display-message', '-p', '-t', pane, '#{window_index}')
        self.t('resize-pane', '-Z', '-t', pane)
        binary = self.base / 'bin'
        binary.mkdir()
        fzf = binary / 'fzf'
        fzf.write_text('#!/bin/sh\nprintf "%s\\n" "' + pane + '"\n')
        fzf.chmod(0o755)
        env = dict(self.env, PATH=str(binary) + os.pathsep + self.env['PATH'])
        subprocess.run(['bash', str(ROOT / 'config/tmux/pane_viewer.sh'), 'alpha', window], env=env, check=True, capture_output=True, timeout=10)
        self.assertEqual(self.t('display-message', '-p', '-t', pane, '#{window_zoomed_flag}'), '1')

    def test_legacy_snapshot_migrates_without_losing_sessions(self):
        self.plugin_setup()
        self.client('alpha')
        script = self.t('show-option', '-gqv', '@termi-save-script')
        subprocess.run(['bash', script, 'quiet'], env=self.env, check=True, capture_output=True, timeout=15)
        root = self.base / 'state'
        legacy = (root / 'last').resolve()
        self.assertEqual(legacy.parent, root)
        self.restart()
        self.assertEqual(self.t('list-sessions', '-F', '#{session_name}'), 'alpha')
        self.state('save')
        self.assertTrue(legacy.exists())
        self.assertNotEqual((root / 'last').resolve().parent, root)

    def test_ctrl_tab_escape_sequences_cycle_panes(self):
        master, tty = self.client('alpha')
        first = self.t('display-message', '-p', '-t', 'alpha', '#{pane_id}')
        second = self.t('split-window', '-h', '-P', '-F', '#{pane_id}', '-t', 'alpha')
        self.key(master, b'\x1b[25~')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{pane_id}'), first)
        self.key(master, b'\x1b[26~')
        self.assertEqual(self.t('display-message', '-p', '-t', 'alpha', '#{pane_id}'), second)

if __name__ == '__main__':
    unittest.main(verbosity=2)
