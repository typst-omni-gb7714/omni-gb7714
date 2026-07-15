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

echo "   ─────"
[ "$fail" -eq 0 ] && { echo "   ✅ $pass 项结构不变量全部成立"; exit 0; }
echo "   ❌ 失败 $fail · 通过 $pass"; exit 1
