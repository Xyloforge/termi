import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('configure_shell', ROOT / 'scripts/configure_shell.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class ShellTests(unittest.TestCase):
    def test_old_directory_based_startup_is_replaced_and_other_settings_survive(self):
        old = 'alias mine=true\n# Auto-Tmux Configuration (Added by Install Script)\nexport PATH=x\nif [[ -z "$TMUX" ]]; then\n    if true; then\n        exec tmux -s "$PWD"\n    fi\nfi\n# Termi Features\nalias other=false\n'
        new = module.updated(old, Path('/repo with spaces/zsh/auto-tmux.zsh'))
        self.assertIn('alias mine=true', new)
        self.assertIn('alias other=false', new)
        self.assertNotIn('exec tmux', new)
        self.assertIn("source '/repo with spaces/zsh/auto-tmux.zsh'", new)
        self.assertEqual(module.updated(new, Path('/repo with spaces/zsh/auto-tmux.zsh')), new)

    def test_unrecognized_legacy_block_is_not_destroyed(self):
        with self.assertRaises(ValueError):
            module.updated('# Auto-Tmux Configuration (Added by Install Script)\nuser content\n', Path('/source'))

    def test_configuration_is_backed_up_once_and_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / '.zshrc'
            target.write_text('alias keep=true\n')
            module.configure(target, ROOT / 'zsh/auto-tmux.zsh')
            module.configure(target, ROOT / 'zsh/auto-tmux.zsh')
            backups = list(Path(directory).glob('.zshrc.termi-backup-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), 'alias keep=true\n')

    def test_uninstall_removes_only_managed_startup(self):
        old = 'alias keep=true\n'
        managed = module.updated(old, Path('/repo/zsh/auto-tmux.zsh'))
        removed = module.remove(managed)
        self.assertIn('alias keep=true', removed)
        self.assertNotIn('source', removed)
        self.assertNotIn(module.START, removed)
