#!/usr/bin/env python3
"""将实际preview包映射到临时测试根，保持开发套件的全部检查。"""
import argparse
import contextlib
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def manifest(root):
    return {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted(root.rglob('*')) if path.is_file()}


def binary(value, version):
    path = shutil.which(str(value))
    if path is None: raise RuntimeError(f'缺Typst {version}：{value}；请设置TYPST和TYPST15，或放入tests/bin。')
    path = Path(path).resolve()
    output = subprocess.check_output([str(path), '--version'], text=True)
    if not output.startswith(f'typst {version} '):
        raise RuntimeError(f'精确测试需要Typst {version}，实际为：{output.strip()}')
    return path


def execute(repo, work, arguments):
    support = repo / 'tests/_support'
    config = json.loads((support / 'package.json').read_text())
    package = (repo / config['package']).resolve()
    assert package.is_relative_to(repo) and (package / 'typst.toml').is_file(), package
    primary = binary(os.environ.get('TYPST', repo / 'tests/bin/typst-0.14.2'), '0.14.2')
    secondary = binary(os.environ.get('TYPST15', repo / 'tests/bin/typst-0.15.0'), '0.15.0')
    original = manifest(package)
    shutil.copytree(package, work, dirs_exist_ok=True)
    shutil.copytree(repo / 'tests', work / 'tests', ignore=shutil.ignore_patterns('_support', '__pycache__', '.DS_Store'))
    # 支持材料只补包中不存在的文件，不允许覆盖被测运行代码。
    for path in sorted((support / 'root').rglob('*')):
        if not path.is_file(): continue
        relative = path.relative_to(support / 'root')
        target = work / relative
        if target.exists():
            if str(relative) in original: continue
            raise RuntimeError(f'测试支持材料冲突：{relative}')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
    shutil.copy2(support / 'run-source.sh', work / 'tests/run.sh')
    bin_dir = work / 'tests/bin'
    bin_dir.mkdir(exist_ok=True)
    for source, name in ((primary, 'typst-0.14.2'), (secondary, 'typst-0.15.0')):
        shutil.copy2(source, bin_dir / name)
    for name, digest in original.items():
        assert hashlib.sha256((work / name).read_bytes()).hexdigest() == digest, name
    env = os.environ.copy()
    env['TYPST'] = str(bin_dir / 'typst-0.14.2')
    env['TYPST15'] = str(bin_dir / 'typst-0.15.0')
    env.pop('TYPST_FONT_PATHS', None)
    command = ['bash', 'tests/run.sh', *arguments]
    print('被测发布包：', package, flush=True)
    print('临时测试根：', work, flush=True)
    result = subprocess.run(command, cwd=work, env=env)
    for name, digest in original.items():
        assert hashlib.sha256((work / name).read_bytes()).hexdigest() == digest, ('运行代码被测试修改', name)
    assert manifest(package) == original, '发布包在测试期间改变'
    (work / 'preview-test-result.json').write_text(json.dumps(dict(package=str(package),
        command=command, returncode=result.returncode, runtime_files=original), indent=2)+'\n')
    return result.returncode


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--workdir', type=Path, help='保留测试工作区；目录须不存在')
    parser.add_argument('arguments', nargs='*', help='原tests/run.sh的层和分组参数')
    args = parser.parse_args()
    with contextlib.ExitStack() as stack:
        if args.workdir:
            work = args.workdir.resolve()
            assert work.parent.is_dir() and not work.exists(), work
            work.mkdir()
        else:
            work = Path(stack.enter_context(tempfile.TemporaryDirectory(prefix='omni-preview-tests-')))
        return execute(args.repo.resolve(), work, args.arguments)


if __name__ == '__main__':
    raise SystemExit(main())
