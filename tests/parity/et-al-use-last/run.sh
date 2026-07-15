#!/usr/bin/env bash
# `et-al-use-last` 与 citeproc-lua 的对拍：同一条规则、同一份语料，比对**哪些责任者被显示、
# 哪些被省掉**。
#
# 权威是 citeproc-lua（真 CSL 引擎）+ Zotero 中文社区的《心理学报》样式——它的
# `<bibliography et-al-min="8" et-al-use-first="6" et-al-use-last="true">` 是本功能在中文语料里
# 的真实用例（心理科学进展同款；傳播與社會學刊、四川外国语大学、海南大学是 APA 7 的 21 / 19 / true）。
# omni 这边照搬：bib-et-al-min: 8, bib-et-al-use-first: 6, bib-et-al-use-last: 1
#（CSL 的 use-last 是布尔、只留末 1 位，映射到本包的整数就是 1）。
#
# 三条语料各钉一件事：
#   en8（8 位，恰好达到 et-al-min）→ 前 6 + 省略号 + 末 1，省掉第 7 位（Golf）
#   en7（7 位，不到阈值）          → 不截断，7 位全出（Golf 本就不在名单里）
#   en9（9 位）                    → 前 6 + 省略号 + 末 1，省掉第 7、8 位（Golf、Hotel）
#
# ⚠️**只比姓的序列，不比姓名形态与整条格式**——心理学报是 APA 中文变体（`Alpha, A.` 带缩写点、
#   题名斜体、年份加括号），与 GB 著录形态天差地别，那些差异是两个样式的差异，不是本功能的。
#   本对拍要回答的只有一个问题：*省略号截掉的是不是同一批人*。
#
# 依赖：citeproc-lua + xelatex（TeX Live 的 citation-style-language 包）、typst。
# 用法：bash tests/parity/et-al-use-last/run.sh
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../../.. && pwd)"
TYPST="${TYPST:-$ROOT/tests/bin/typst-0.15.0}"
[ -x "$TYPST" ] || TYPST=typst

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# ── 权威侧：citeproc-lua ──
cp psy.csl refs.json "$WORK/"
cat > "$WORK/ref.tex" <<'TEX'
\documentclass{article}
\usepackage[style=psy]{citation-style-language}
\addbibresource{refs.json}
\begin{document}
\cite{en8} \cite{en7} \cite{en9}
\printbibliography
\end{document}
TEX
(cd "$WORK" && xelatex -interaction=nonstopmode ref.tex >/dev/null 2>&1
              citeproc-lua ref.aux >/dev/null 2>&1
              xelatex -interaction=nonstopmode ref.tex >/dev/null 2>&1)
if [ ! -f "$WORK/ref.pdf" ]; then
  echo "FAIL: citeproc-lua 侧没有产出 PDF（工具链缺失？）"
  exit 1
fi

# ── 我们这侧 ──
"$TYPST" compile --root "$ROOT" omni.typ "$WORK/omni.pdf" >/dev/null 2>&1 || {
  echo "FAIL: omni 侧编译失败"
  "$TYPST" compile --root "$ROOT" omni.typ "$WORK/omni.pdf" 2>&1 | grep -m2 '^error' | sed 's/^/  /'
  exit 1; }

# ── 抽「题名 → 显示出来的姓序列」逐条比 ──
# 语料的姓都是北约字母表（Alpha…Zulu），在两边的输出里都是独立的大写词，正则抓得干净。
# 题名（English Eight / Seven / Nine）用来对齐行；省略号本身不比（citeproc 恒单个 U+2026，
# 我们默认同款、但可被 custom-punct 改成六点——那是配置项，不是本功能的正确性）。
extract() {  # $1 = pdf
  pdftotext -layout "$1" - 2>/dev/null | python3 extract.py
}

a="$(extract "$WORK/ref.pdf")"
b="$(extract "$WORK/omni.pdf")"

if [ -z "$a" ] || [ -z "$b" ]; then
  echo "FAIL: 有一侧抽不出条目（citeproc $(echo "$a" | grep -c .) 行，omni $(echo "$b" | grep -c .) 行）"
  exit 1
fi

diff_out="$(diff <(echo "$a") <(echo "$b"))"
if [ -n "$diff_out" ]; then
  echo "FAIL: et-al-use-last 的省略结果与 citeproc-lua 不一致（左 citeproc / 右 omni）："
  echo "$diff_out" | sed 's/^/  /'
  fail=1
fi

if [ $fail -eq 0 ]; then
  echo "et-al-use-last: 3 条语料（8 位截 / 7 位不截 / 9 位省 2 个）省掉的责任者与 citeproc-lua 逐条一致"
fi
exit $fail
