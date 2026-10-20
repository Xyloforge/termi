#!/usr/bin/env bash
# tmux-continuum expects an executable path, without shell arguments.
exec python3 "$(dirname "${BASH_SOURCE[0]}")/session_state.py" auto
