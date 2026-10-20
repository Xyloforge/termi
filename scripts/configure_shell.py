#!/usr/bin/env python3
"""Replace only Termi's startup block; keep other user shell settings intact."""
import os
from pathlib import Path
import re
import shlex
import shutil
import sys
import tempfile

START = '# >>> Termi auto-tmux >>>'
END = '# <<< Termi auto-tmux <<<'


def updated(text, source):
    block = START + '\nsource ' + shlex.quote(str(source)) + '\n' + END
    if START in text:
        pattern = re.escape(START) + r'.*?' + re.escape(END)
        if END not in text:
            raise ValueError('Unclosed Termi startup block; refusing to change .zshrc')
        return re.sub(pattern, lambda _: block, text, count=1, flags=re.S)
    marker = '# Auto-Tmux Configuration (Added by Install Script)'
    if marker in text:
        start = text.index(marker)
        end = re.search(r'^fi[ \t]*$', text[start:], re.M)
        if not end:
            raise ValueError('Unrecognized legacy startup block; refusing to change .zshrc')
        return text[:start] + block + text[start + end.end():]
    return text.rstrip() + '\n\n' + block + '\n'


def remove(text):
    if START not in text and '# Auto-Tmux Configuration (Added by Install Script)' not in text:
        return text
    # Use the same strict boundary detection as migration, then remove the block.
    migrated = updated(text, Path('/unused'))
    return re.sub(re.escape(START) + r'.*?' + re.escape(END) + r'\n?', '', migrated, count=1, flags=re.S)


def configure(path, source):
    path = path.resolve()
    old = path.read_text() if path.exists() else ''
    new = remove(old) if source is None else updated(old, source.resolve())
    if new == old:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        fd, backup = tempfile.mkstemp(prefix=path.name + '.termi-backup-', dir=path.parent)
        os.close(fd)
        shutil.copy2(path, backup)
        print('Shell backup: ' + backup)
    fd, temporary = tempfile.mkstemp(prefix=path.name + '.termi-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(new)
        if path.exists():
            shutil.copymode(path, temporary)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == '__main__':
    configure(Path(sys.argv[1]), None if sys.argv[2] == '--remove' else Path(sys.argv[2]))
