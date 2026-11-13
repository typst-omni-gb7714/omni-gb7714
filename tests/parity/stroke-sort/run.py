"""在独立工作目录编译双驱动，严格校验11条作者的完整次序。"""
import argparse
from collections import Counter
import contextlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import signal
import subprocess
import tempfile
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
EXPECTED = ('丁文江', '王国维', '田汉', '刘半农', '张元济', '周作人', '赵元任', '徐志摩', '黄宾虹', 'BROWN', 'SMITH')
PATTERN = re.compile('|'.join(map(re.escape, EXPECTED)), re.I)


def run(label, command, work, env, records, timeout=120, required=True):
    start = time.monotonic()
    proc = subprocess.Popen(command, cwd=work, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, start_new_session=True)
    timed_out = False
    try:
        output = proc.communicate(timeout=timeout)[0]
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(proc.pid, signal.SIGTERM)
        try: output = proc.communicate(timeout=5)[0]
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            output = proc.communicate(timeout=5)[0]
    (work / f'{label}.log').write_text(output)
    records.setdefault('commands', {})[label] = dict(command=command, returncode=proc.returncode,
        timed_out=timed_out, seconds=time.monotonic()-start)
    (work / 'results.json').write_text(json.dumps(records, ensure_ascii=False, indent=2)+'\n')
    if required and (proc.returncode or timed_out):
        raise RuntimeError(f'{label} failed (exit={proc.returncode}, timeout={timed_out})\n{output}')
    return proc.returncode, output


def tool(name, override=None):
    value = override or name
    resolved = shutil.which(value)
    if resolved is None: raise RuntimeError(f'找不到工具：{value}')
    return str(Path(resolved).resolve())


def biber_command(work, env, records):
    original = tool('biber', os.environ.get('BIBER'))
    code, output = run('biber-version', [original, '--version'], work, env, records, timeout=30, required=False)
    if code == 0: return original
    if platform.system() != 'Darwin' or 'binary with lipo failed' not in output:
        raise RuntimeError('Biber无法启动：\n'+output)
    # 部分macOS的lipo不支持Biber启动器所用的extract_family；只在本次临时目录提取同一程序的本机架构。
    native = work / 'biber-native'
    arch = 'arm64' if platform.machine().startswith('arm64') else platform.machine()
    run('biber-thin', [tool('lipo'), '-thin', arch, original, '-output', str(native)], work, env, records)
    run('biber-native-version', [str(native), '--version'], work, env, records, timeout=30)
    records['biber_native_extraction'] = dict(source=original, architecture=arch)
    return str(native)


def author_order(text):
    names = [name.upper() for name in PATTERN.findall(text)]
    if Counter(names) != Counter(EXPECTED):
        raise AssertionError(f'作者必须完整出现且各一次，实际为：{names}')
    if tuple(names) != EXPECTED:
        raise AssertionError(f'笔画／语种顺序不符：{names}，期望：{list(EXPECTED)}')
    return names


def execute(work):
    env = os.environ.copy()
    (work / 'tmp').mkdir()
    env.update(TMPDIR=str(work / 'tmp')+'/', PAR_TMPDIR=str(work / 'tmp'))
    records = dict(expected=EXPECTED)
    for name in ('biblatex.tex', 'refs.bib'): shutil.copy2(HERE / name, work / name)
    typst = tool('typst', os.environ.get('TYPST', str(ROOT / 'tests/bin/typst-0.14.2')))
    run('typst-version', [typst, '--version'], work, env, records)
    run('xelatex-version', [tool('xelatex'), '--version'], work, env, records)
    biber = biber_command(work, env, records)
    command = shlex.quote(biber)+' %O %B'
    rc = "$biber = '"+command.replace('\\', '\\\\').replace("'", "\\'")+"';\n"
    (work / 'latexmkrc').write_text(rc)
    run('latexmk', [tool('latexmk'), '-norc', '-r', 'latexmkrc', '-xelatex', '-interaction=nonstopmode',
        '-halt-on-error', 'biblatex.tex'], work, env, records)
    final_tex_log = (work / 'biblatex.log').read_text(errors='replace')
    if 'Missing character:' in final_tex_log: raise AssertionError('LaTeX缺字：\n'+final_tex_log)
    _, output = run('typst', [typst, 'compile', '--root', str(ROOT), '--ignore-system-fonts',
        '--font-path', str(ROOT / 'tests/fonts'), str(HERE / 'omni.typ'), str(work / 'omni.pdf')], work, env, records)
    if re.search(r'^warning:', output, re.M): raise AssertionError('Typst编译警告：\n'+output)
    for name in ('biblatex', 'omni'):
        assert (work / f'{name}.pdf').is_file(), name
        _, text = run(f'{name}-text', [tool('pdftotext'), str(work / f'{name}.pdf'), '-'], work, env, records)
        records[name] = author_order(text)
        print(name+':', ' '.join(records[name]), flush=True)
    assert records['biblatex'] == records['omni']
    records['passed'] = True
    (work / 'results.json').write_text(json.dumps(records, ensure_ascii=False, indent=2)+'\n')
    print('✅ 两驱动11条作者完整、唯一，笔画及中英分组顺序完全一致', flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, help='保留全部日志和PDF；目标目录须不存在')
    args = parser.parse_args()
    with contextlib.ExitStack() as stack:
        if args.output:
            work = args.output.resolve()
            assert work.parent.is_dir() and not work.exists(), work
            work.mkdir()
        else:
            work = Path(stack.enter_context(tempfile.TemporaryDirectory(prefix='omni-stroke-')))
        execute(work)


if __name__ == '__main__':
    main()
