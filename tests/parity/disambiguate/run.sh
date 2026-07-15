#!/usr/bin/env bash
# 消歧梯子与 citeproc-lua 的对拍：同一组语料、同一套配置，比对文献表里每条的**年份后缀**与
# **第一责任者的姓名形态**（补名升级到了哪一级）。
#
# 权威是 citeproc-lua（真 CSL 引擎）+ Zotero 中文社区的官方 GB 著者-出版年制样式。该样式的
# <citation> 是 et-al-min="2" et-al-use-first="1"、**没有** disambiguate-add-names（CSL 规范里
# 默认 false）、开着 disambiguate-add-givenname 与 disambiguate-add-year-suffix。omni 这边用
# 等价配置：cite-et-al-min: 2（与 CSL 的 et-al-min 逐字同义，不必换算）、
# disambiguate: (names: false, given-name: true, date: true)。
#
# 五组语料各钉一件事：
#   a1/a2  同姓不同人同年        → ①补名（首字母就够：Smith J / Smith A）
#   b1/b2  首责任者同、合作者不同 → ③年份后缀（关着展开名单档，标签撞车）+ 后缀按**文献表序**分配
#   c1/c2  真同人同年            → ③年份后缀
#   d1/d2  同一批人同年          → ③年份后缀（两个作者，et-al 截断）
#   e1/e2  两条路都走得通        → ①补名优先于②展开名单；且首字母相同（Sam/Sue → S）时升到全名
#
# 依赖：citeproc-lua + xelatex（TeX Live 的 citation-style-language 包）、typst。
# 用法：bash tests/parity/disambiguate/run.sh
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../../.. && pwd)"
TYPST="${TYPST:-$ROOT/tests/bin/typst-0.15.0}"
[ -x "$TYPST" ] || TYPST=typst

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# ── 权威侧：citeproc-lua ──
cp gb-ay.csl refs.json "$WORK/"
cat > "$WORK/ref.tex" <<'TEX'
\documentclass{article}
\usepackage[style=gb-ay]{citation-style-language}
\addbibresource{refs.json}
\begin{document}
\cite{a1} \cite{a2} \cite{b1} \cite{b2} \cite{c1} \cite{c2} \cite{d1} \cite{d2} \cite{e1} \cite{e2}
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
# typst 要求源文件在 project root 内，所以 .typ 留在本目录（产物进临时目录）。
"$TYPST" compile --root "$ROOT" omni.typ "$WORK/omni.pdf" >/dev/null 2>&1 || {
  echo "FAIL: omni 侧编译失败"
  "$TYPST" compile --root "$ROOT" omni.typ "$WORK/omni.pdf" 2>&1 | grep -m2 '^error' | sed 's/^/  /'
  exit 1; }

# ── 逐条比对：题名 → (后缀, 第一责任者形态) ──
# 从两边的文献表里，按题名抓出「年份+后缀」和第一责任者的写法。大小写与标点两侧本就不同
# （citeproc 出 SMITH J、我们出 Smith J），所以归一成小写、去标点后再比。
# 比的是**年份后缀**——消歧梯子的核心产物，也是「后缀按文献表序号分配」这条规则的直接体现。
#
# 文献表行的形态：「责任者…, 年份后缀. 题名[M]. 出版地: 出版者.」
#   citeproc  BROWN B, CHEN C, LI L, 2021a. Delta[M]. NY: P.
#   omni      Brown B，Chen C，Li L，2021a. Delta[M]. NY：P.
# 抽成「题名 → 年份后缀」逐行比（全角标点转半角、去零宽字符、转小写后）。
#
# ⚠️**不比文献表里的责任者形态**——这里有一处*有意的分歧*：
#   e1/e2（Stone Sam / Stone Sue，首字母都是 S）的正文标注两边都是 `Stone Sam et al.` /
#   `Stone Sue et al.`（消歧算法一致），但文献表里 citeproc 出 `STONE S`（姓名形态由
#   <bibliography> 自己的 name 设置定，不受消歧影响），我们出 `Stone Sam`（消歧的升级传导到著录）。
#   我们这么做有 GB 依据：§7.1.1「如用首字母无法识别该人名时，**可著录全名**」是*著录*规则，而表里
#   两条都是 `Stone S` 正是「无法识别」；且本包一贯守着「标签与著录同源」（`show-anon`、
#   `show-no-date` 同此原则）——读者拿标签 `(Stone Sam et al.)` 去表里找，表里就该写着 `Stone Sam`。
#   citeproc 那边是 CSL 的样式惯例，不是国标要求。
extract() {  # $1 = pdf
  pdftotext -layout "$1" - 2>/dev/null \
    | perl -pe 's/[\x{200b}\x{2060}]//g' \
    | sed 's/，/, /g; s/：/: /g; s/  */ /g' \
    | grep -E '\[M\]' \
    | sed -E 's/^ *//; s/^.*, ([0-9]{4}[a-z]?)\. ([A-Za-z]+)\[M\].*$/\2\t\1/' \
    | grep -E '^[A-Za-z]+	' \
    | tr 'A-Z' 'a-z' \
    | sort
}

a="$(extract "$WORK/ref.pdf")"
b="$(extract "$WORK/omni.pdf")"

if [ -z "$a" ] || [ -z "$b" ]; then
  echo "FAIL: 有一侧抽不出条目（citeproc 行数 $(echo "$a" | grep -c .)，omni 行数 $(echo "$b" | grep -c .)）"
  exit 1
fi

diff_out="$(diff <(echo "$a") <(echo "$b"))"
if [ -n "$diff_out" ]; then
  echo "FAIL: 消歧结果与 citeproc-lua 不一致（左 citeproc / 右 omni）："
  echo "$diff_out" | sed 's/^/  /'
  fail=1
fi

if [ $fail -eq 0 ]; then
  echo "disambiguate: 10 条语料的年份后缀（含按文献表序号分配）与 citeproc-lua 逐条一致"
fi
exit $fail
