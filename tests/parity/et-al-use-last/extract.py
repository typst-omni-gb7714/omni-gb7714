"""从两侧的 PDF 文本里抽出「题名 → 显示出来的姓序列」。

责任者串里本来就有句点（citeproc 的 `Alpha, A.,` 是缩写点），所以不能按句点切；改成按*题名*
切段——每条的责任者区就是「上一条题名结束」到「本条题名开始」之间那一段。

citeproc 侧的 PDF 含正文引用（`(Alpha et al., 2021)`），会污染第一条的责任者区，所以先从
`References` 之后截断。我们这侧 `title: none` 且不写正文引用，天然只有文献表。
"""
import re
import sys

NATO = r"\b(Alpha|Bravo|Charlie|Delta|Echo|Foxtrot|Golf|Hotel|Zulu)\b"
TITLE = r"English (Eight|Seven|Nine)"

text = sys.stdin.read()
if "References" in text:
    text = text.split("References", 1)[1]

rows, prev = [], 0
for m in re.finditer(TITLE, text):
    names = re.findall(NATO, text[prev:m.start()])
    rows.append(m.group(1) + "\t" + " ".join(names))
    prev = m.end()

for row in sorted(rows):
    print(row)
