#!/usr/bin/env python3
"""提取从项目 errors.typ 定向导入的 raise／message 字面量调用。"""
import importlib.util
from pathlib import Path
import re
import sys

ROOT = Path(sys.argv[1]).resolve()
spec = importlib.util.spec_from_file_location('comment_scanner', ROOT / 'scripts/strip-comments.py')
scanner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scanner)
target = (ROOT / 'src/errors.typ').resolve()
for path in [ROOT / 'lib.typ', *sorted((ROOT / 'src').rglob('*.typ'))]:
    source = path.read_text()
    code = '\n'.join(source[start:end] for kind, start, end in scanner.scan(source) if kind == 'code')
    aliases = set()
    for match in re.finditer(r'(?m)^[ \t]*#?import\s+"([^"]+)"\s*:\s*([^\n]+)', code):
        name = match[1]
        if name.startswith('@'):
            continue
        imported = (ROOT / name.lstrip('/') if name.startswith('/') else path.parent / name).resolve()
        if imported != target:
            continue
        for item in match[2].split(','):
            member = re.fullmatch(r'\s*(raise|message)(?:\s+as\s+([\w-]+))?\s*', item)
            if member:
                aliases.add(member[2] or member[1])
    for alias in sorted(aliases):
        pattern = r'(?<![\w.-])'+re.escape(alias)+r'\("([a-z-]+\.[a-z-]+)"'
        for match in re.finditer(pattern, code):
            print('"'+match[1]+'"')
