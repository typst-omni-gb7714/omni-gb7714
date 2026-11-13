"""检查完整引用、临时列表恢复和测试身份；拒绝收敛及其他意外警告。"""
import collections
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def invoke(binary, source, output, html=False):
    command = [str(binary), 'compile', '--root', str(ROOT), '--jobs', '1', '-', str(output)]
    if html: command += ['--features', 'html', '--format', 'html', '--input', 'target=html']
    proc = subprocess.run(command, input=source, cwd=ROOT, capture_output=True, text=True, timeout=120)
    warnings = re.findall(r'^warning: (.+)', proc.stderr, re.M)
    allowed = {'html export is under active development and incomplete'} if html else set()
    assert proc.returncode == 0 and not (set(warnings) - allowed), proc.stderr
    return output.read_text() if html else subprocess.check_output(['pdftotext', '-layout', str(output), '-']).decode()


def main():
    first = Path(shutil.which(os.environ.get('TYPST', 'typst')) or os.environ['TYPST']).resolve()
    binaries = list(dict.fromkeys((first, ROOT / 'tests/bin/typst-0.15.0')))
    assert all(binary.is_file() for binary in binaries)
    versions = {binary: tuple(map(int, re.search(r'(\d+)\.(\d+)\.(\d+)',
        subprocess.check_output([str(binary), '--version']).decode()).groups())) for binary in binaries}
    with tempfile.TemporaryDirectory() as directory:
        out = Path(directory)
        for binary in binaries:
            for relative, token, minimum in (
                ('03-names/prefix-last.typ', 'VANDERBERGJ,DELACRUZM', 2),
                ('06-display/show-series.typ', '(示例丛书,3)', 2),
                ('08-punct/custom-punct.typ', '正文：[1]张三###李四###王五###等', 1),
                ('16-combo/pages-and-imprint.typ', 'BROWNB,GREENG', 2),
            ):
                source = (ROOT / 'tests/matrix' / relative).read_text()
                source = source.replace('"/tests/_fixture/probe.typ"', '"/tests/contract/convergence/dynamic-probe.typ"')
                source = source.replace('gb7714.with(', 'gb7714.with(cite-form: "full", ')
                text = invoke(binary, source, out / 'dynamic.pdf')
                compact = ''.join(text.split())
                assert compact.count(token) >= minimum, (binary, relative, token, text)
            for relative in ('13-per-list/label.typ', '16-combo/multi-list.typ'):
                source = (ROOT / 'tests/matrix' / relative).read_text().replace(
                    '"/tests/_fixture/probe.typ"', '"/tests/contract/convergence/dynamic-probe.typ"')
                invoke(binary, source, out / 'named.pdf')
            for name in ('case-ids', 'list-restore'):
                text = invoke(binary, (HERE / f'{name}.typ').read_text(), out / f'{name}.pdf')
                for token in (('Firstbook', 'Secondbook') if name == 'case-ids' else ('Parentbook', 'Otherbook')):
                    assert text.count(token) == 1, (binary, name, token, text)
            html = invoke(binary, (HERE / 'list-restore.typ').read_text(), out / 'restore.html', html=True)
            assert html.count('Parentbook') == html.count('Otherbook') == 1
            assert 'role="doc-backlink"' in html and 'role="doc-biblioref"' in html
            print('   ✅', binary.name, '动态完整引用、父列表恢复、同名区块及HTML通过，无收敛警告', flush=True)

        # 对实际矩阵的身份做独立校验；重复显示名必须显式提供不同id。
        count = 0
        for path in sorted((ROOT / 'tests/matrix').rglob('*.typ')):
            pinned = re.search(r'^//! typst: 0\.15', '\n'.join(path.read_text().splitlines()[:5]), re.M)
            binary = ROOT / 'tests/bin/typst-0.15.0' if pinned else first
            if versions[binary] >= (0, 15, 0):
                command = [str(binary), 'eval', 'query(<gb7714-matrix-case>).map(it => it.value)', '--in', str(path), '--root', str(ROOT)]
            else:
                command = [str(binary), 'query', '--root', str(ROOT), str(path), '<gb7714-matrix-case>', '--field', 'value']
            proc = subprocess.run(command, capture_output=True, text=True, timeout=120)
            assert proc.returncode == 0 and not re.search(r'^warning:', proc.stderr, re.M), (path, proc.stderr)
            rows = json.loads(proc.stdout)
            counts = collections.Counter(row['id'] for row in rows)
            assert all(value == 1 for value in counts.values()), (path, counts)
            count += len(rows)
        print('   ✅ 矩阵区块身份唯一：', count, '个区块', flush=True)


if __name__ == '__main__':
    main()
