"""检查全局／逐表日期设置在完整引用、脚注及原生路由中的实际继承。"""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from html.parser import HTMLParser

ROOT = Path(__file__).resolve().parents[3]
BIB = '@online{one,title={Entry},date={1996-01-01/2026-05-17},urldate={2026-06-01/2026-06-30},langid={english}}'
SLASH = '1996-01-01/2026-05-17'
WORD = '1996-01-01to2026-05-17'


class PlainHTML(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def source(body, global_value='"—"'):
    return '''#import "/lib.typ": *
#set page(width: 700pt, height: auto, margin: 20pt)
#set text(font: "Libertinus Serif", size: 11pt)
#show: gb7714(date-range-separator: VALUE, note-ibid: false, note-repeat-style: "full")
'''.replace('VALUE', global_value) + body


def main():
    first = Path(shutil.which(os.environ.get('TYPST', 'typst')) or os.environ['TYPST']).resolve()
    binaries = list(dict.fromkeys((first, ROOT / 'tests/bin/typst-0.15.0')))
    bib = json.dumps(BIB)
    jobs = [
        ('full-global', source('#cite(<one>, form: "full")\n#bibliography(' + bib + ', title: none, full: true)', '"/"'), 2, 0, False),
        ('full-local', source('#cite(<one>, form: "full")\n#bibliography(' + bib + ', title: none, full: true, date-range-separator: "/")'), 2, 0, False),
        ('note-local', source('#cite(<one>, note: "foot")\n#bibliography(' + bib + ', title: none, full: true, date-range-separator: "/")'), 2, 0, False),
    ]
    left = json.dumps(BIB.replace('{one,', '{left,'))
    right = json.dumps(BIB.replace('{one,', '{right,'))
    for form in ('full', 'foot'):
        option = 'form: "full"' if form == 'full' else 'note: "foot"'
        body = '#cite(<left>, bib-label: "left", ' + option + ')\n\n#cite(<right>, bib-label: "right", ' + option + ')\n'
        body += '#bibliography(' + left + ', title: none, full: true, label: "left", date-range-separator: "/")\n'
        body += '#bibliography(' + right + ', title: none, full: true, label: "right", date-range-separator: " to ")\n'
        jobs.append(('named-' + form, source(body), 2, 2, False))
        body = '#cite(<one>, ' + option + ')\n#bibliography(' + bib + ', title: none, full: true, date-range-separator: "/")\n'
        body += '#cite(<one>, ' + option + ')\n#bibliography(' + bib + ', title: none, full: true, date-range-separator: " to ")\n'
        jobs.append(('native-duplicate-' + form, source(body), 2, 2, True))
        body = '#cite(<one>, ' + option + ')\n#[] <split>\n#cite(<one>, ' + option + ')\n'
        body += '#bibliography(' + bib + ', title: none, full: true, target: selector(std.cite).before(<split>), date-range-separator: "/")\n'
        body += '#bibliography(' + bib + ', title: none, full: true, target: selector(std.cite).after(<split>), date-range-separator: " to ")\n'
        jobs.append(('native-target-' + form, source(body), 2, 2, True))
    body = '@left @right\n'
    body += '#bibliography(' + left + ', title: none, full: true, target: std.cite.where(key: <left>), date-range-separator: "/")\n'
    body += '#bibliography(' + right + ', title: none, full: true, target: std.cite.where(key: <right>), date-range-separator: " to ")\n'
    jobs.append(('native-markup-merged-note', source(body).replace('note-ibid: false', 'note: "foot", note-ibid: false'), 2, 2, True))
    json_bib = json.dumps([dict(id='json', type='webpage', title='JSON range',
        issued={'date-parts': [[1996, 1, 1], [2026, 5, 17]]}, accessed={'date-parts': [[2026, 6, 1], [2026, 6, 30]]})])
    jobs.append(('json', source('#bibliography(' + json.dumps(json_bib) + ', title: none, full: true)', '"/"'), 1, 0, False))
    with tempfile.TemporaryDirectory(prefix='omni-date-range-') as directory:
        out = Path(directory)
        for binary in binaries:
            version = tuple(map(int, re.search(r'(\d+)\.(\d+)\.(\d+)', subprocess.check_output([str(binary), '--version'], text=True)).groups()))
            count = 0
            for name, text, slash_count, word_count, native in jobs:
                if native and version < (0, 15, 0): continue
                pdf = out / (name + '.pdf')
                proc = subprocess.run([str(binary), 'compile', '--root', str(ROOT), '-', str(pdf)],
                                      input=text, cwd=ROOT, capture_output=True, text=True, timeout=120)
                assert proc.returncode == 0 and 'warning:' not in proc.stderr, (binary, name, proc.stderr)
                actual = subprocess.check_output(['pdftotext', '-layout', str(pdf), '-'], text=True)
                compact = ''.join(actual.split())
                assert compact.count(SLASH) == slash_count and compact.count(WORD) == word_count, (binary, name, actual)
                assert '2026-06-01/2026-06-30' not in compact, (name, actual)
                count += 1
            if version >= (0, 15, 0):
                for name, text, slash_count, word_count, _ in jobs:
                    if name not in ('full-local', 'named-foot', 'json'): continue
                    html = out / (name + '.html')
                    proc = subprocess.run([str(binary), 'compile', '--features', 'html', '--format', 'html', '--root', str(ROOT), '-', str(html)],
                                          input=text, cwd=ROOT, capture_output=True, text=True, timeout=120)
                    warnings = re.findall(r'^warning: (.+)', proc.stderr, re.M)
                    unexpected = [w for w in warnings if w != 'html export is under active development and incomplete'
                                  and not w.endswith('was ignored during HTML export')]
                    assert proc.returncode == 0 and not unexpected, (name, proc.stderr)
                    parser = PlainHTML()
                    parser.feed(html.read_text())
                    compact = ''.join(''.join(parser.parts).split())
                    assert compact.count(SLASH) == slash_count and compact.count(WORD) == word_count, (name, compact)
                count += 3
            print('   ✅', binary.name, count, '项日期区间继承、完整引用、脚注及JSON检查通过，无警告', flush=True)


if __name__ == '__main__':
    main()
