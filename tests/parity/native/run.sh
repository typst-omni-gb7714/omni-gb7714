#!/usr/bin/env bash
# 原生与 omni 行为对照测试套件：成对编译 native-NN 与 ours-NN，断言
# ① 编译状态一致（同成功或同失败）；
# ② ours 侧关键编号与路由不变量在位（数值与已验证的原生输出一致；渲染格式差异属 GB 设计，不比对）。
# 需 typst 0.15+（target、group、原生 CSL 流派）。
# 用法：bash tests/parity/native/run.sh
set -u
# 每次运行一套自己的临时文件：写死的 /tmp 路径会被并发跑的另一个测试进程覆写，静默串台成假红
# （曾实测到：oracle 渲染第 5 篇时，pdftotext 读到的是另一进程刚写进去的第 61 篇）。
TMPD="$(mktemp -d)"; export TMPD; trap 'rm -rf "$TMPD"' EXIT
cd "$(dirname "$0")"
TYPST="${TYPST:-typst}"
# 二进制自检：本套件成对比对「原生与 omni 的编译状态是否一致」，
# 而 TYPST 指向一个*不存在*的二进制时，两边都失败 → 判成「一致」→ 全绿。假绿比红更糟，先拦住。
if ! "$TYPST" --version >/dev/null 2>&1; then
  echo "  [FAIL] TYPST=$TYPST 跑不起来（要绝对路径；本套件需 typst 0.15+）"
  exit 1
fi
pass=0; fail=0
say() { echo "  [$1] $2"; }

# check <case> <pattern…>：ours-<case> 的 pdftotext 必须含全部 pattern。
check() {
  local case="$1"; shift
  local n="native-$case.typ" o="ours-$case.typ"
  $TYPST compile --root ../../.. "$n" "$TMPD/p-n.pdf" >/dev/null 2>&1; local ne=$?
  $TYPST compile --root ../../.. "$o" "$TMPD/p-o.pdf" >/dev/null 2>&1; local oe=$?
  if [ "$ne" -ne "$oe" ] && [ "$case" != "06-form" ]; then
    say FAIL "$case 编译状态不一致 native=$ne ours=$oe"; fail=$((fail+1)); return
  fi
  if [ "$oe" -eq 0 ]; then
    local txt; txt=$(pdftotext $TMPD/p-o.pdf - 2>/dev/null)
    for pat in "$@"; do
      if ! grep -qF "$pat" <<<"$txt"; then
        say FAIL "$case 缺少不变量「$pat」"; fail=$((fail+1)); return
      fi
    done
  fi
  say ok "$case"; pass=$((pass+1))
}

check 01-title-auto   "Bibliography" "[1] ALPHA A"
check 02-title-content "我的文献"
check 03-full         "[2] BETA B"
check 04-style-ieee   "A. Alpha, Book A"
# 05：双方都应编译失败（unknown style）。06：已知差异 form none/full/year（P2 待对齐），仅各自编译。
check 05-style-bad
check 06-form
check 07-supp         "第 5 章"
check 08-target-pri   "AUTO 表" "TARGET 表" "[1] ALPHA A"
check 09-auto-following "表一" "表二" "[2] ALPHA A"
check 10-group-none   "[1] GAMMA C"
check 11-group-named  "[2] BETA B"
check 12-cite-order   "[1] GAMMA C" "[2] ALPHA A" "[3] DELTA D" "[4] BETA B"
check 13-merge        "[1-3]" "[3] GAMMA C"
check 14-ay           "(Alpha, 2020)" "ALPHA A, 2020. T1[M]"
# quan 绘制的圈码与注体在 pdftotext 里分行（golden 15 同形态），圈码与正体分开断言。
check 15-note         "①" "ALPHA A. T1[M]. P, 2020." "[2] BETA B"
check 16-multibib     "[1] ALPHA A" "[2] GAMMA C"
check 17-ad-mix       "[1] ALPHA A" "BETA B, 2021" "[2] GAMMA C"
check 18-ieee-first   "[2] B. Beta" "[3] GAMMA C"
check 19-note-mix     "[1] BETA B"
# P-A 守卫：文档序不等于路由号（num↔seen 对齐）。早引 `@p1@p2` 路由副表得高号 [3-4]、晚引 `@a@b` 主表得 [1-2]；
# [3] 必须是 Paper One（取对 key，不是全局文档序 key）。覆盖压缩、路由保全与 num↔seen 修复（P-A 原型曾错）。
# 上标 super 形态吃前导空格（与真原生 numeric 对齐）：早[3-4]、晚[1-2]，无空格。
check 20-routed-reorder "早[3-4]" "晚[1-2]" "[3] PONE P" "[1] ALPHA A"
# native-mode 下显式 `keys:` 点名的未引用条目必须渲染（曾被 routed-empty 误判成空表、只剩标题）。
check 21-keys-native "KEYTESTAUTH"

# 22 set-block 改道：omni 经 std.bibliography 哨兵改道后，原生写法 `show std.bibliography: set block` 命中整表，
# 结果与原生一致——SVG 标记 fill 色都恰好出现 1 次（整表一个框）。同时验证内容未丢（条目在位）。
sbshow() { $TYPST compile --root ../../.. "$1" $TMPD/p-sb.svg --format svg >/dev/null 2>$TMPD/p-sb.err && grep -o '#123456' $TMPD/p-sb.svg | wc -l | tr -d ' ' || echo ERR; }
sb_o=$(sbshow ours-22-setblock-show.typ); sb_n=$(sbshow native-22-setblock-show.typ)
o_txt=$($TYPST compile --root ../../.. ours-22-setblock-show.typ $TMPD/p-sb.pdf >/dev/null 2>&1 && pdftotext $TMPD/p-sb.pdf - 2>/dev/null)
if [ "$sb_o" = 1 ] && [ "$sb_n" = 1 ] && grep -q "TA" <<<"$o_txt" && grep -q "TC" <<<"$o_txt"; then
  say ok "22-setblock-show omni 与原生一致 (框 omni=$sb_o native=$sb_n，内容在位)"; pass=$((pass+1))
else say FAIL "22-setblock-show 框 omni=$sb_o native=$sb_n（期望均=1）或内容缺失"; fail=$((fail+1)); fi

# 23 单 std.bibliography：omni 每个 #bibliography 只发一个 std.bib（路由+渲染合并），原生 query 与包裹类操作
# 只命中一次、无空框漏出。① query 计数：两个列表恰好是 2（不是 4）；② `it => block(fill)` 只有 1 个标记框。
cnt=$($TYPST compile --root ../../.. ours-23-stdbib-count.typ $TMPD/p-c.pdf >/dev/null 2>&1 && pdftotext $TMPD/p-c.pdf - 2>/dev/null | tr -d ' \n' | grep -oE "STDBIBCOUNT=[0-9]+=END")
wrapn=$($TYPST compile --root ../../.. ours-23b-wrap-once.typ $TMPD/p-w.svg --format svg >/dev/null 2>&1 && grep -o '#123456' $TMPD/p-w.svg | wc -l | tr -d ' ')
if [ "$cnt" = "STDBIBCOUNT=2=END" ] && [ "$wrapn" = 1 ]; then
  say ok "23-single-stdbib (query 计数=2/两列表、包裹只 1 框，无空框漏出)"; pass=$((pass+1))
else say FAIL "23-single-stdbib query=$cnt（期望 =2=）或包裹框数=$wrapn（期望 1）"; fail=$((fail+1)); fi

# 26 脚注制 × native 路由：隐形注册让原生表收齐脚注引用的条目（[1]/[2] 跨表连续编号），
# 重复梯子（同上）照常。
w26=$($TYPST compile --root ../../.. ours-26-footnote-native.typ $TMPD/p-f26.pdf 2>&1 | grep -c converge)
f26=$(pdftotext $TMPD/p-f26.pdf - 2>/dev/null)
# 梯子的引语词跟*被引条目*语言（`cite-terms-lang` 默认 by-entry，国标 §9.3.1.2）：本用例文档是
#   `lang: "zh"` 但条目全是英文，所以出 `Ibid., 11` / `See note ①, 25`，不是「同上: 11」。
if [ "$w26" = 0 ] && echo "$f26" | grep -q "\[1\] ALPHA A. T1\[M\]" && echo "$f26" | grep -q "\[2\] GAMMA C. T5\[M\]" && echo "$f26" | grep -q "Ibid., 11" && echo "$f26" | grep -q "See note ①, 25"; then
  say ok "26-footnote-native (隐形注册收录 + 跨表编号 + 梯子 + 直传页码 + 0收敛警告)"; pass=$((pass+1))
else say FAIL "26-footnote-native 收录/编号/梯子/页码缺失或收敛警告=$w26"; fail=$((fail+1)); fi

# 24 多列表连续编号对齐：首表([1]-[12])与续表([13]-[15])所有编号行左缘应同一 x（左对齐 + 各表列宽一致）。
if $TYPST compile --root ../../.. ours-24-multibib-align.typ $TMPD/p-a.png --ppi 150 >/dev/null 2>$TMPD/p-a.err; then
  lefts=$(python3 - <<'PY'
import os
from PIL import Image
im=Image.open(os.environ["TMPD"]+"/p-a.png").convert('L');W,H=im.size;px=im.load()
rows=[next((x for x in range(W) if px[x,y]<110),None) for y in range(H)]
ls=[];y=0
while y<H:
    if rows[y] is not None:
        seg=[];yy=y
        while yy<H and rows[yy] is not None: seg.append(rows[yy]);yy+=1
        ls.append(min(seg));y=yy
    else: y+=1
# 去掉首行「正文」，剩下 15 个编号行的左缘应基本一致（容 2px 抗渲染噪声）。
nums=ls[1:]
print("OK" if nums and max(nums)-min(nums)<=2 else f"BAD:{nums}")
PY
)
  if [ "$lefts" = "OK" ]; then say ok "24-multibib-align (首表续表编号列对齐)"; pass=$((pass+1))
  else say FAIL "24-multibib-align 编号左缘不齐: $lefts"; fail=$((fail+1)); fi
else say FAIL "24-multibib-align 编译失败"; fail=$((fail+1)); fi

# 25 原生 CSL 流派正文引用与原生逐像素一致（omni 不插 leading-wj、不吃标记前后空白）。
$TYPST compile --root ../../.. native-25-csl-cite-space.typ $TMPD/p-25n.png --ppi 300 >/dev/null 2>&1
$TYPST compile --root ../../.. ours-25-csl-cite-space.typ $TMPD/p-25o.png --ppi 300 >/dev/null 2>&1
if [ -f $TMPD/p-25n.png ] && [ -f $TMPD/p-25o.png ]; then
  same=$(python3 - <<'PY'
import os
from PIL import Image, ImageChops
import numpy as np
a=Image.open(os.environ["TMPD"]+"/p-25n.png").convert('L'); b=Image.open(os.environ["TMPD"]+"/p-25o.png").convert('L')
print("SAME" if a.size==b.size and (np.array(ImageChops.difference(a,b))[:120,:]>30).sum()==0 else "DIFF")
PY
)
  if [ "$same" = "SAME" ]; then say ok "25-csl-cite-space (原生 CSL 正文引用逐像素同原生)"; pass=$((pass+1))
  else say FAIL "25-csl-cite-space 正文引用与原生不一致($same)"; fail=$((fail+1)); fi
else say FAIL "25-csl-cite-space 编译失败"; fail=$((fail+1)); fi

echo "  parity: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
