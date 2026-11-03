"""Version-neutral documents never hard-code the current release.

Release records (VERSION, BASELINE, HANDOFF, VALIDATION, KNOWN-ISSUES, ROADMAP, the
release notes and appcast) carry version numbers; guides, READMEs and the website link
to BASELINE or the latest release instead, so a release does not need to edit them.
"""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
assert re.fullmatch(r'\d+\.\d+\.\d+', version)
NEUTRAL = ['README.md', 'README.zh-CN.md', 'docs/index.html'] + [
    'documentation/' + name for name in (
        'INSTALLATION.md', 'INSTALLATION.en.md', 'USAGE.md', 'USAGE.en.md', 'CONFIGURATION.md',
        'PROMOTION.md', 'DEVELOPMENT.md', 'DISTRIBUTION.md')]
pattern = re.compile(r'(?<![\d.])' + re.escape(version) + r'(?![\d.])')
problems = []
for name in NEUTRAL:
    for number, line in enumerate((root / name).read_text().splitlines(), 1):
        if pattern.search(line):
            problems.append(f'{name}:{number}: {line.strip()[:100]}')
assert not problems, 'Current version hard-coded in version-neutral files:\n' + '\n'.join(problems)
print(f'Version {version} appears only in release records; {len(NEUTRAL)} guides and pages stay version-neutral')
