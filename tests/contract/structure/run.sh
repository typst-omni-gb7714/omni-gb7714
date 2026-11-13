#!/usr/bin/env bash
# 渲染结构的不变量——这些东西在文本 golden 里*看不见*，只能验结构本身。
#
# ① 单框：整张文献表 = **一个** block（对齐原生）。用户 `#set block(fill: ..)` 只该命中一次，
#    且不随条目数增长。曾经用 grid 画表，被 `set block` 命中套出一堆框。
# ② show 规则透明：用户对 `grid.cell` 的 show 规则该命中条目正文、*不该*命中编号列。
# ③ HTML 语义：导出 HTML 时带上 `role="doc-bibliography"` / `<ul list-style:none>` / `<li>`，
#    顺序编码制加 `<span class="prefix">`，著者-出版年制加 `class="hanging-indent"`，
#    `back-ref` 开时有 `role="doc-biblioref"` 与 `role="doc-backlink"`（对齐原生 typst 的 HTML 导出）。
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../../.. && pwd)"
source "$ROOT/tests/fonts/env.sh" || exit 1
TYPST="${TYPST:-typst}"
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
pass=0; fail=0

# ① 单框：数 SVG 里标记色 #123456 出现几次——omni 与原生都应恰好 1 次（3 条与 5 条都一样）。
count-box() {
  $TYPST compile --root "$ROOT" "$1" "$TMPD/sb.svg" --format svg >/dev/null 2>&1 \
    && grep -o '#123456' "$TMPD/sb.svg" | wc -l | tr -d ' ' || echo ERR
}
o=$(count-box setblock-omni.typ); n=$(count-box setblock-native.typ); o5=$(count-box setblock-omni-5.typ)
if [ "$o" = 1 ] && [ "$n" = 1 ] && [ "$o5" = 1 ]; then
  echo "   ✅ 单框一致（omni=$o 原生=$n omni五条=${o5}，都是 1）"; pass=$((pass+1))
else
  echo "   ❌ 框数 omni=$o 原生=$n omni五条=${o5}（都该是 1）"; fail=$((fail+1))
fi

# ② show 规则透明：`show grid.cell.where(x: 1)` 该命中正文、不该命中编号列。
if $TYPST compile --root "$ROOT" grid-cell-postprocess.typ "$TMPD/g.pdf" >/dev/null 2>"$TMPD/g.err"; then
  # 先把空格与换行全抹掉再比对：pdftotext 会在编号列与正文列之间断行，
  # 「MARKX 紧贴 AA」这种「紧贴」关系不抹掉空白就看不出来。
  t=$(pdftotext "$TMPD/g.pdf" - 2>/dev/null | tr -d ' \n')
  hits=$(grep -o 'MARKX' <<<"$t" | wc -l | tr -d ' ')
  if [ "$hits" -ge 2 ] && grep -qF "MARKXAA" <<<"$t" && ! grep -qF "MARKX[1]" <<<"$t"; then
    echo "   ✅ show 规则只命中条目正文、不碰编号列（命中 $hits 次）"; pass=$((pass+1))
  else
    echo "   ❌ show 规则命中 $hits 次，或误伤了编号列"; fail=$((fail+1))
  fi
else
  echo "   ❌ grid-cell-postprocess 编译失败"; fail=$((fail+1))
fi

# ④ 两端对齐：条目行顶到内容区右缘。
#    文本 golden 看不见对齐——`pdftotext -layout` 落的是字符网格，行尾差半个字它照样一模一样。
#    这里量真几何：页宽 300pt、边距 20pt，内容区右缘 = 280pt；条目里有一长串挤不下的数字，
#    断行只能落在它前面，留下的空当必须由两端对齐吃掉。内容列若是 `auto`（取最长行的自然宽度），
#    列宽会被这个早断点压窄，最宽的行只到 ~236pt。
jf_max=$($TYPST compile --root "$ROOT" justify-flush.typ "$TMPD/jf.pdf" >/dev/null 2>"$TMPD/jf.err" \
  && pdftotext -bbox "$TMPD/jf.pdf" - 2>/dev/null \
  | grep -o 'xMax="[0-9.]*"' | sed 's/[^0-9.]//g' | sort -g | tail -1)
if [ -z "$jf_max" ]; then
  echo "   ❌ 两端对齐：justify-flush.typ 编译或取数失败"; sed 's/^/      /' "$TMPD/jf.err" | head -2; fail=$((fail+1))
elif awk -v v="$jf_max" 'BEGIN{exit !(v>=278)}'; then
  echo "   ✅ 两端对齐：条目行顶到内容区右缘（最右 ${jf_max}，右缘 280）"; pass=$((pass+1))
else
  echo "   ❌ 两端对齐：最宽的行只到 ${jf_max}，没顶到内容区右缘 280（内容列宽被最长行的自然宽度压窄了）"; fail=$((fail+1))
fi

# ⑤ 编号列对齐：每条编号的左缘落在同一条竖线上。
#    `number-width: auto` 只量末号时，Times 的「11」字距对让 `［11］` 比 `［10］` 窄，列宽塞不下 `［10］`，
#    行首全角括号被压半格、那一条独自左探 6pt。文本 golden 看不见半格。这里取所有以「［」起头的词的
#    xMin，断言全相等（容差 0.1pt）。
ncf_xs=$($TYPST compile --root "$ROOT" number-column-flush.typ "$TMPD/ncf.pdf" >/dev/null 2>"$TMPD/ncf.err" \
  && pdftotext -bbox "$TMPD/ncf.pdf" - 2>/dev/null \
  | grep -o 'xMin="[0-9.]*"[^>]*>［' | grep -o 'xMin="[0-9.]*"' | sed 's/[^0-9.]//g' | sort -g | uniq)
ncf_n=$(printf '%s\n' "$ncf_xs" | grep -c .)
if [ -z "$ncf_xs" ]; then
  echo "   ❌ 编号列对齐：number-column-flush.typ 编译或取数失败"; sed 's/^/      /' "$TMPD/ncf.err" | head -2; fail=$((fail+1))
elif [ "$ncf_n" -eq 1 ] || awk -v lo="$(printf '%s\n' "$ncf_xs" | head -1)" -v hi="$(printf '%s\n' "$ncf_xs" | tail -1)" 'BEGIN{exit !(hi-lo<0.1)}'; then
  echo "   ✅ 编号列对齐：11 条编号左缘同一竖线（x=$(printf '%s' "$ncf_xs" | head -1)）"; pass=$((pass+1))
else
  echo "   ❌ 编号列对齐：编号左缘不齐，出现了 $ncf_n 个不同的 x：$(printf '%s' "$ncf_xs" | tr '\n' ' ')（列宽只量了末号？）"; fail=$((fail+1))
fi

# ③ HTML 语义标签。
html-has() {
  local label="$1" file="$2"; shift 2
  if ! $TYPST compile --features html --format html --root "$ROOT" "$file" "$TMPD/h.html" --input target=html >/dev/null 2>"$TMPD/h.err"; then
    echo "   ❌ $label HTML 编译失败"; fail=$((fail+1)); return
  fi
  local miss=""
  for sub in "$@"; do grep -qF "$sub" "$TMPD/h.html" || miss="${miss}「${sub}」"; done
  if [ -z "$miss" ]; then echo "   ✅ $label"; pass=$((pass+1))
  else echo "   ❌ $label 的 HTML 缺 $miss"; fail=$((fail+1)); fi
}
html-has "HTML 语义 · 顺序编码制" setblock-omni.typ \
  '<section role="doc-bibliography"' '<ul style="list-style-type: none"' '<li>' '<span class="prefix">'
html-has "HTML 语义 · 著者-出版年制" html-semantic-ay.typ \
  '<section role="doc-bibliography" class="hanging-indent"' '<ul style="list-style-type: none"'
html-has "HTML 语义 · 条目反跳（back-ref）" html-backref.typ \
  'role="doc-biblioref"' 'role="doc-backlink"'

# ④ label-only 多列表过滤：只用 cite(bib-label:) + bibliography(label:)、不调 set-bib-label 时，
#    每张命名表仍只打属于自己的条目。作者名各出现*一次*（各在自己表）；bug 时出现*两次*（两表都打）。
if $TYPST compile --root "$ROOT" label-only-multibib.typ "$TMPD/lo.pdf" >/dev/null 2>"$TMPD/lo.err"; then
  t=$(pdftotext "$TMPD/lo.pdf" - 2>/dev/null)
  naa=$(grep -o 'Qxaa' <<<"$t" | wc -l | tr -d ' ')
  nzz=$(grep -o 'Qxzz' <<<"$t" | wc -l | tr -d ' ')
  if [ "$naa" = 1 ] && [ "$nzz" = 1 ]; then
    echo "   ✅ label-only 多列表：各表只打自己的条目（Qxaa=${naa} Qxzz=${nzz}，都是 1）"; pass=$((pass+1))
  else
    echo "   ❌ label-only 多列表过滤失效（Qxaa=${naa} Qxzz=${nzz}，都该是 1；=2 即两表都打全部）"; fail=$((fail+1))
  fi
else
  echo "   ❌ label-only-multibib 编译失败"; fail=$((fail+1))
fi

echo "   ─────"
[ "$fail" -eq 0 ] && { echo "   ✅ $pass 项结构不变量全部成立"; exit 0; }
echo "   ❌ 失败 $fail · 通过 $pass"; exit 1
