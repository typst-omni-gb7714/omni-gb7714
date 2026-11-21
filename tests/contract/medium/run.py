"""从公共API检查自动载体、严格筛选与实际完整引用／脚注输出。"""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from html.parser import HTMLParser

ROOT = Path(__file__).resolve().parents[3]
BIB = (ROOT / 'tests/_fixture/medium.bib').read_text()


class PlainHTML(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def clean(value):
    return re.sub(r'[\s\u00ad\u200b\u2060\ufeff]', '', value)


def jobs(year):
    json_data = json.dumps([dict(id='json', type='article-journal', title='JSON DOI',
        **{'container-title':'Journal'}, issued={'date-parts':[[2020]]}, DOI='10.1234/json')])
    rows = [
        ('reported', 'medium-issue', '', 'cite', BIB, '[J/OL]', 1, None, None),
        ('hidden', 'medium-issue', ',show-url:false,show-pid:(rest:false)', 'cite', BIB, '[J/OL]', 1, False, False),
        ('filtered', 'medium-issue', ',show-url:"online-only",show-pid:(doi:"online-only")', 'cite', BIB, '[J/OL]', 1, False, False),
        ('doi-through', 'medium-issue', ',show-url:"online-only",show-pid:(doi:true)', 'cite', BIB, '[J/OL]', 1, False, True),
        ('max-zero', 'medium-issue', ',show-url:false,show-pid:(doi:true,max:0)', 'cite', BIB, '[J/OL]', 1, False, False),
        ('hidden-medium', 'medium-issue', ',show-medium:false', 'cite', BIB, '[J]', 1, True, None),
        ('full', 'medium-issue', '', 'full', BIB, '[J/OL]', 2, None, None),
        ('note', 'medium-issue', '', 'note', BIB, '[J/OL]', 2, None, None),
        ('template', 'medium-issue', ',custom-drivers:(article:"<title><mark-medium>. <access>")', 'cite', BIB, '[J/OL]', 1, None, None),
        ('url-no-access-date', 'medium-url', '', 'cite', BIB, '[J/OL]', 1, None, None),
        ('explicit-cd', 'medium-cd', '', 'cite', BIB, '[J/CD]', 1, None, None),
        ('json-doi', 'json', '', 'cite', json_data, '[J]' if year == 2005 else '[J/OL]', 1, None, None),
    ]
    for name, key, options, form, data, mark, count, url, doi in rows:
        cite = f'#cite(<{key}>' + (',form:"full"' if form == 'full' else ',note:"foot"' if form == 'note' else '') + ')'
        source = '#import "/lib.typ": *\n#set page(width:700pt,height:auto,margin:20pt)\n#set text(font:"Libertinus Serif",size:11pt)\n'
        source += f'#show: gb7714(version:{year}{options})\n{cite}\n#bibliography({json.dumps(data,ensure_ascii=False)},title:none,full:false)\n'
        yield name, source, mark, count, url, doi


def verify(actual, mark, count, url, doi):
    compact = clean(actual)
    assert re.findall(r'\[J(?:/[A-Z]+)?\]', compact) == [mark] * count, actual
    if url is not None:
        assert ('pubs.acs.org' in compact) == url, actual
    if doi is not None:
        assert ('10.1021/cb3005325' in compact) == doi, actual


def main():
    first = Path(shutil.which(os.environ.get('TYPST', 'typst')) or os.environ['TYPST']).resolve()
    binaries = list(dict.fromkeys((first, ROOT / 'tests/bin/typst-0.15.0')))
    with tempfile.TemporaryDirectory(prefix='omni-medium-') as directory:
        out = Path(directory)
        for binary in binaries:
            version = tuple(map(int,re.search(r'(\d+)\.(\d+)\.(\d+)',subprocess.check_output([str(binary),'--version'],text=True)).groups()))
            count = 0
            for year in (2005,2015,2025):
                for name, source, mark, expected, url, doi in jobs(year):
                    pdf = out / f'{year}-{name}.pdf'
                    proc = subprocess.run([str(binary),'compile','--root',str(ROOT),'-',str(pdf)], input=source,
                                          cwd=ROOT,capture_output=True,text=True,timeout=120)
                    assert proc.returncode == 0 and not proc.stderr, (binary,name,proc.stderr)
                    actual = subprocess.check_output(['pdftotext','-layout',str(pdf),'-'],text=True)
                    verify(actual,mark,expected,url,doi)
                    count += 1
                    if version >= (0,15,0) and name in ('filtered','full','template','json-doi'):
                        html = pdf.with_suffix('.html')
                        proc = subprocess.run([str(binary),'compile','--features','html','--format','html','--root',str(ROOT),'-',str(html)],
                                              input=source,cwd=ROOT,capture_output=True,text=True,timeout=120)
                        warnings = re.findall(r'^warning: (.+)',proc.stderr,re.M)
                        assert proc.returncode == 0 and all(w == 'html export is under active development and incomplete' or w.endswith('was ignored during HTML export') for w in warnings), proc.stderr
                        parser = PlainHTML()
                        parser.feed(html.read_text())
                        verify(''.join(parser.parts),mark,expected,url,doi)
                        count += 1
            print('   ✅',binary.name,count,'项载体推导、online-only筛选、完整引用和脚注检查通过，无意外警告',flush=True)


if __name__ == '__main__':
    main()
