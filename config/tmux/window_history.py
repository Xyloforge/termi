#!/usr/bin/env python3
"""Keep previous-window history for each actual client, across sessions."""
import fcntl
import json
from pathlib import Path
import sys

from session_state import tmux


def main():
    socket = tmux('display-message', '-p', '#{socket_path}')
    # The socket directory is private to the user; flock releases even on a crash.
    with Path(socket + '.termi-history.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        raw = tmux('show-option', '-gqv', '@termi-window-history')
        history = json.loads(raw) if raw else {}
        if sys.argv[1] == 'seed':
            pid, position = sys.argv[2:4]
            record = history.get(pid, {})
            if not record:
                history[pid] = {'current': position, 'previous': ''}
            elif record.get('current') != position and not record.get('previous'):
                record['previous'] = position
            tmux('set-option', '-gq', '@termi-window-history', json.dumps(history))
            return
        clients = tmux('list-clients', '-F', '#{client_pid}|#{session_id}:#{window_id}')
        live = {}
        for line in clients.splitlines():
            pid, position = line.split('|', 1)
            record = history.get(pid, {})
            if record.get('current') != position:
                record = {'current': position, 'previous': record.get('current', '')}
            live[pid] = record
        tmux('set-option', '-gq', '@termi-window-history', json.dumps(live))
        if sys.argv[1] == 'track':
            if len(sys.argv) > 2 and sys.argv[2] in live:
                tmux('set-option', '-gq', '@termi-last-session', live[sys.argv[2]]['current'].split(':')[0])
            return
        client, pid, session = sys.argv[1:4]
        previous = live.get(pid, {}).get('previous', '')
    # Release before navigation: switching fires another tracking hook.
    if previous and tmux('display-message', '-p', '-t', previous, '#{window_id}', check=False):
        tmux('switch-client', '-c', client, '-t', previous)
    else:
        # A shortcut can arrive before the initial attach hook finishes. Native
        # history is already available and also covers a closed previous target.
        windows = tmux('list-windows', '-t', session, '-F', '#{window_last_flag}')
        if '1' in windows.splitlines():
            tmux('last-window', '-t', session, check=False)
        else:
            tmux('switch-client', '-c', client, '-l', check=False)


if __name__ == '__main__':
    main()
