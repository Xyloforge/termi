#!/bin/bash
# Backwards-compatible entry point. Use setup.sh for full control.
exec "$(dirname "${BASH_SOURCE[0]}")/setup.sh" uninstall "$@"
