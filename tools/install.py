#!/usr/bin/env python3
"""Install the configuration snapshot and keep existing component directories."""
import argparse
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
COMPONENTS = tuple(sorted(p.name for p in (ROOT / 'config').iterdir() if p.is_dir()))


def install(home, components, *, apply=False):
    config = home / '.config'
    backup = home / '.local/state/dark-angel-dotfiles' / datetime.now().strftime('desktop-config-backup-%Y%m%d-%H%M%S-%f')
    for component in components:
        source, target = ROOT / 'config' / component, config / component
        print(f'{component}: {target}')
        if not apply:
            continue
        config.mkdir(parents=True, exist_ok=True)
        if component == 'systemd':
            # The user service directory also contains unrelated applications.
            for item in sorted(p for p in source.rglob('*') if p.is_file()):
                relative = item.relative_to(source)
                destination = target / relative
                if destination.exists() or destination.is_symlink():
                    saved = backup / component / relative
                    saved.parent.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(destination), saved)
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(item, destination)
        else:
            if target.exists() or target.is_symlink():
                backup.mkdir(parents=True, exist_ok=True)
                shutil.move(str(target), backup / component)
            shutil.copytree(source, target, symlinks=True)
    if apply and 'dark-angel' in components:
        environment = dict(os.environ, HOME=str(home))
        subprocess.run([sys.executable, str(config / 'dark-angel/scripts/apply-theme.py'), 'dark'],
                       env=environment, check=True, stdout=subprocess.DEVNULL)
    if apply and 'hypr' in components:
        units = config / 'systemd/user'
        units.mkdir(parents=True, exist_ok=True)
        for source in sorted((config / 'hypr/systemd').glob('*')):
            destination = units / source.name
            if destination.exists() or destination.is_symlink():
                saved = backup / 'systemd/user' / source.name
                saved.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(destination), saved)
            shutil.copy2(source, destination)
    if apply:
        print(f'Installed configuration. Existing files, if any: {backup}')
    else:
        print('Preview only. Use --apply to install.')
    return backup


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', type=Path, default=Path.home(), help='Destination home directory')
    parser.add_argument('--component', action='append', choices=COMPONENTS, help='Install selected components; default: all')
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument('--apply', action='store_true', help='Install and back up existing configuration')
    actions.add_argument('--dry-run', action='store_true', help='Preview without writing (default)')
    args = parser.parse_args()
    install(args.home.expanduser().resolve(), tuple(dict.fromkeys(args.component)) if args.component else COMPONENTS, apply=args.apply)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
