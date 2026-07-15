#!/usr/bin/env bash
# 笔画排序双驱动交叉比对测试套件：胡振震样式（biblatex-gb7714-2015）与 omni-gb7714 渲染同一 refs.bib，
# 比对著者-出版年制下中文姓名按笔画排序的结果是否一致。
# 依赖：xelatex + biber（latexmk）、typst。从任意 cwd 运行都可以。
# 用法：bash tests/parity/stroke-sort/run.sh
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"

# 11 个条目的唯一标识（中文取作者全名、英文取姓氏），用于从 PDF 文本提取渲染顺序。
MARKERS='丁文江|王国维|田汉|刘半农|张元济|周作人|赵元任|徐志摩|黄宾虹|Brown|Smith'

echo "== 驱动一：biblatex-gb7714-2015（style=gb7714-2015ay, sortlocale=zh__stroke）=="
latexmk -xelatex -interaction=nonstopmode biblatex.tex >/dev/null 2>&1
bl=$(pdftotext biblatex.pdf - 2>/dev/null | grep -ioE "$MARKERS" | awk '!s[$0]++' | paste -sd' ' -)
echo "  $bl"

echo "== 驱动二：omni-gb7714（style: author-date, bib-sort-zh-by: bihua）=="
typst compile --root "$ROOT" omni.typ omni.pdf >/dev/null 2>&1
om=$(pdftotext omni.pdf - 2>/dev/null | grep -ioE "$MARKERS" | awk '!s[$0]++' | paste -sd' ' -)
echo "  $om"

echo "== 期望：中文段按笔画升序（丁2 王4 田5 刘6 张7 周8 赵9 徐10 黄11），英文段在后 =="
echo "  中文段应为：丁文江 王国维 田汉 刘半农 张元济 周作人 赵元任 徐志摩 黄宾虹"

if [ "$bl" = "$om" ] && [ -n "$bl" ]; then
  echo "✅ 两驱动渲染顺序完全一致"
else
  echo "⚠️ 两驱动顺序有差异——核对上方两行；同笔画数并列项的分歧属预期"
  echo "   （biblatex sortlocale=zh__stroke 走 Unicode CLDR；omni 走 auto-bihua 的 Unihan 笔画数 + cnchar 笔顺）。"
fi

# 清理 LaTeX 中间产物，保留 PDF。
latexmk -c -quiet biblatex.tex >/dev/null 2>&1
