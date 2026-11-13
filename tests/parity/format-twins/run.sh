#!/usr/bin/env bash
# 内建条目格式「孪生」对拍：手册里逐类型展示的那些「内建条目格式」模板串，
# 当作 `custom-drivers` 跑一遍，必须**逐字复现**内置渲染。
#
# 两条硬规矩，都是被真事故逼出来的：
#
# ① **模板串从手册用的那份数据现取，不在这里手抄。**
#    曾经手抄一份放在本文件里，于是手册改了、这里没改，闸照样绿——它验的是「手抄那份」
#    与内置一致，而不是「手册那份」与内置一致。手册窗口与代码脱钩，正是本闸要防的事。
#    格式串原先写在手册正文的类型卡片里（本闸按 `entrytype:` / `bib-fields:` 正则抽出来），
#    后来搬进 `src/drivers/templates.typ`、手册改成 import 那份字典来显示，取数口随之改成
#    直接 import 同一份字典：验的东西没变（手册显示的就是它），也不再依赖手册的排版结构。
#    ⚠️配套两道自检，缺一不可：手册必须确实 import 它（否则手册哪天把串写死回去，本闸会
#    安静地验一份没人显示的数据）；字典里的类型数必须够（空字典让 `custom-drivers` 什么都
#    不覆盖，两侧都是内置渲染、diff 恒相等——闸会绿得毫无意义）。
#
# ② **语料必须含「可选字段缺失」的条目。**
#    曾经语料里每个字段都齐全（`number={7}`、`date` 都在），于是模板里 `volume（number）`
#    这种「字段缺了、包着它的括号要不要跟着消失」的路径*一次都没走到*——12/12 全绿，
#    却什么都没验着。现在每类都配一条「只有必备字段」的瘦条目。
#
# ③ **「有 A 无 B」的形状要戳得到。**
#    模板里 `<（date）>urldate`（date 空）与 `address：publisher`（address 空）这两处，
#    考的是「一个 token 空掉时，它两侧的字面量怎么塌缩」。语料里的 @online 曾只有
#    「date 与 urldate 都有」和「都没有」两条——**「有 urldate 无 date」一次都没走到**，
#    于是段间句点被整个吃掉（`[EB/OL][2025-05-06]`）还全绿。
#    现在补 `online-nodate`（有 urldate 无 date）与 `book-noimprint`（出版地、出版者皆缺——
#    测出版项整段塌缩；⚠️不能只缺其一：`show-sine-*` 默认 `auto` 会在另一项在场时补
#    「[出版地不详]／[出版者不详]」，那是内置条件补白、手册静态格式串不表达，两侧本就该不同）。
#
# ④ **取值链（fallback）要有条目戳得穿。**
#    `publisher` token 的链是 `publisher → school → organization → institution`（学位论文 D、
#    档案 A、连续出版物是 `institution → publisher → school → organization`）。
#    手册曾把链*手写*成 `institution|school|organization`——**漏了 `publisher` 那一档**，
#    而语料里的 thesis 恰好没有 `publisher` 字段，于是闸绿着、错着。
#    现在补 `thesis-pub` / `archive-pub`（publisher 与 school 并存）与 `patent-both`
#    （holder 与 author 并存）三条，专戳取值链。
#
# ⑤ **字典的类型与语料的类型必须一一对上。**
#    实测过的漏洞：把键 `"@article"` 拼成 `"@artcle"`，本闸照样报绿——拼错的键匹配不到任何
#    条目，两侧都走内置渲染，diff 恒相等。反向同理：字典里加一条模板却忘了配语料，那条串
#    从头到尾没被验过，闸也不吭声。所以两个方向都查：语料里的每个类型在字典里要有模板，
#    字典里的每条模板在语料里要有条目。
#
# 用法：bash tests/parity/format-twins/run.sh
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../../.." && pwd)"
source "$ROOT/tests/fonts/env.sh" || exit 1
TYP="${TYPST:-typst}"
cd "$ROOT"

tmp="$DIR/.tmp"; mkdir -p "$tmp"; trap 'rm -rf "$tmp"' EXIT
# 根相对路径：typst 的 read 以 --root 为根解析以 `/` 开头的路径。
rel="/tests/parity/format-twins/.tmp"

# ── ① 定位格式串数据，并确认手册用的就是它 ────────────────────────────────
tpl="src/drivers/templates.typ"
grep -q "$tpl" easy-zh-manual/template/main.typ || {
  echo "  [FAIL] 手册没有 import $tpl —— 它显示的格式串已另有来源，本闸的取数口要跟着改"; exit 1; }
# 类型条数 = 字典里 `"@…":` 键的个数。低于 12 视为「数据搬家或被清空」，见文件头 ①。
n_type=$(grep -cE '^[[:space:]]*"@[^"]*":' "$tpl")
[ "$n_type" -ge 12 ] || {
  echo "  [FAIL] $tpl 里只数到 $n_type 个类型 —— 数据搬家了？本闸的取数口要跟着改"; exit 1; }

# ── ② 语料：每类两条——「字段齐全」与「只有必备字段」（可选字段全缺） ────────
cat > "$tmp/e.bib" <<'BIB'
@book{book, author={{甲}}, editor={{编}}, translator={{译}}, title={题}, subtitle={副}, titleaddon={辅}, edition={2}, location={地}, publisher={社}, date={2020}, pages={11-22}, url={https://u.cn}, doi={10.1/d}, langid={chinese}}
@book{book-thin, author={{甲}}, title={题}, location={地}, publisher={社}, date={2020}, langid={chinese}}
@book{book-noimprint, author={{甲}}, title={题}, edition={2}, date={2020}, langid={chinese}}
@inbook{inbook, author={{甲}}, translator={{译}}, bookauthor={{原}}, title={题}, subtitle={副}, booktitle={母题}, volume={6}, location={地}, publisher={社}, date={2020}, pages={11-22}, langid={chinese}}
@inbook{inbook-thin, author={{甲}}, title={题}, booktitle={母题}, location={地}, publisher={社}, date={2020}, langid={chinese}}
@article{article, author={{甲}}, translator={{译}}, title={题}, journaltitle={刊}, journalsubtitle={刊副}, date={2019}, volume={9}, number={7}, pages={11-22}, langid={chinese}}
@article{article-thin, author={{甲}}, title={题}, journaltitle={刊}, date={2019}, langid={chinese}}
@inproceedings{conf, author={{甲}}, title={题}, subtitle={副}, eventtitle={会}, date={2017}, pages={11-22}, langid={chinese}}
@inproceedings{conf-thin, author={{甲}}, title={题}, langid={chinese}}
@thesis{thesis, author={{甲}}, title={题}, location={地}, institution={机构}, school={校}, date={2016}, pages={11-22}, langid={chinese}}
@thesis{thesis-thin, author={{甲}}, title={题}, langid={chinese}}
@thesis{thesis-pub, author={{甲}}, title={题}, publisher={出版社}, school={某校}, location={地}, date={2016}, langid={chinese}}
@report{report, author={{甲}}, title={题}, number={7}, date={2015}, pages={11-22}, langid={chinese}}
@report{report-thin, author={{甲}}, title={题}, langid={chinese}}
@standard{standard, number={GB 1}, title={题}, langid={chinese}}
@standard{standard-thin, title={题}, langid={chinese}}
@patent{patent, holder={{持}}, author={{甲}}, title={题}, subtitle={副}, number={CN9}, date={2014}, langid={chinese}}
@patent{patent-thin, author={{甲}}, title={题}, langid={chinese}}
@patent{patent-both, author={{甲}}, holder={{持}}, title={题}, number={CN8}, date={2013}, langid={chinese}}
@online{online, author={{甲}}, title={题}, date={2013}, urldate={2021-01-01}, url={https://u.cn}, doi={10.9/x}, langid={chinese}}
@online{online-thin, author={{甲}}, title={题}, url={https://u.cn}, langid={chinese}}
@online{online-nodate, author={{甲}}, title={题}, url={https://u.cn}, urldate={2025-05-06}, langid={chinese}}
@archive{archive, author={{甲}}, title={题}, number={A9}, location={地}, institution={机构}, date={2012}, langid={chinese}}
@archive{archive-thin, author={{甲}}, title={题}, langid={chinese}}
@archive{archive-pub, author={{甲}}, title={题}, publisher={出版社}, school={某校}, location={地}, date={2012}, langid={chinese}}
@map{map, author={{甲}}, title={题}, scale={1:5万}, edition={2}, location={地}, publisher={社}, date={2011}, dimensions={30cm}, langid={chinese}}
@map{map-thin, author={{甲}}, title={题}, langid={chinese}}
@dataset{dataset, author={{甲}}, title={题}, version={1.0}, publisher={社}, date={2010}, url={https://u.cn}, langid={chinese}}
@dataset{dataset-thin, author={{甲}}, title={题}, langid={chinese}}
@periodical{periodical, editor={{编}}, title={题}, journaltitle={刊}, volume={9}, number={7}, date={2009}, location={地}, publisher={社}, langid={chinese}}
@periodical{periodical-thin, title={题}, langid={chinese}}
@preprint{preprint, author={{甲}}, title={题}, eprint={2301.1}, archiveprefix={arXiv}, date={2008}, url={https://u.cn}, langid={chinese}}
@preprint{preprint-thin, author={{甲}}, title={题}, langid={chinese}}
BIB

# ── ②b 字典与语料双向核对（见文件头 ⑤） ─────────────────────────────────────
#   键可能并列别名（`"@thesis / @mastersthesis / @phdthesis"`），拆开后逐个比。
sed -nE 's/^[[:space:]]*"(@[^"]*)":.*/\1/p' "$tpl" | tr '/' '\n' | tr -d ' @' | sort -u > "$tmp/dict-types.txt"
grep -oE '^@[a-z]+' "$tmp/e.bib" | tr -d '@' | sort -u > "$tmp/corpus-types.txt"
orphan_corpus=$(comm -13 "$tmp/dict-types.txt" "$tmp/corpus-types.txt" | tr '\n' ' ')
[ -z "$orphan_corpus" ] || {
  echo "  [FAIL] 语料里的类型「$orphan_corpus」在 $tpl 里没有模板（键拼错了？）——这类条目两侧都走内置渲染，本闸验不到它"
  exit 1; }
while IFS= read -r key; do
  hit=0
  for t in $(printf '%s' "$key" | tr '/' ' ' | tr -d '@'); do
    grep -q "^@$t{" "$tmp/e.bib" && { hit=1; break; }
  done
  [ "$hit" -eq 1 ] || {
    echo "  [FAIL] 模板「$key」在语料里没有条目，从来没被验证过——补一条语料"
    exit 1; }
done < <(sed -nE 's/^[[:space:]]*"(@[^"]*)":.*/\1/p' "$tpl")

common='#import "/lib.typ": *
#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
#set text(lang: "zh")
#set page(width: 40cm, height: auto)'

cat > "$tmp/bi.typ" <<EOF
$common
// 本闸对比「字段→格式串映射」，固定在完整格式串语境（show-mark/show-end-period 恒 true）——
//   单块退化（auto）会按 token 粒度让内置与模板的块数不同（内置 [S] 嵌题名算一块、模板 <mark-medium>
//   是独立 token 算一块），那是单块行为、由 matrix 的 show-mark/show-end-period 用例验，不属本闸。
#show: gb7714.with(full: true, version: 2025, show-mark: true, show-end-period: true)
#bibliography(read("$rel/e.bib"), title: none, full: true)
EOF

# 字典的键是手册的显示写法，可能并列别名（`"@thesis / @mastersthesis / @phdthesis"`）：
#   拆开逐个登记成 `custom-drivers` 的键（去掉 `@`）——别名共用一条模板，本就是它要表达的。
{
  echo "$common"
  echo '#import "/src/drivers/templates.typ": built-in-templates-2025'
  echo '#let _drivers = (:)'
  echo '#for (k, v) in built-in-templates-2025 { for t in k.split("/") { _drivers.insert(t.trim().trim("@"), v) } }'
  echo '#show: gb7714.with(full: true, version: 2025, show-mark: true, show-end-period: true, custom-drivers: _drivers)'
  echo "#bibliography(read(\"$rel/e.bib\"), title: none, full: true)"
} > "$tmp/ov.typ"

for f in bi ov; do
  if ! $TYP compile --root . "$tmp/$f.typ" "$tmp/$f.pdf" 2>"$tmp/$f.err"; then
    echo "  [FAIL] $f 编译失败（内建格式串里有拼错的 token？）："
    grep -iE "panic|error" "$tmp/$f.err" | head -2
    exit 1
  fi
  pdftotext -raw "$tmp/$f.pdf" - 2>/dev/null | grep -E '^\[[0-9]' > "$tmp/$f.txt"
done

if diff -q "$tmp/bi.txt" "$tmp/ov.txt" >/dev/null; then
  n_entry=$(grep -c '^@' "$tmp/e.bib")
  echo "  built-in-format-twins: $n_type 类 / $n_entry 条语料（字段齐全 · 只有必备字段 · 专戳取值链）逐字复现内置"
  exit 0
fi

echo "  [FAIL] 手册的内建格式串与内置渲染不一致（左=内置，右=手册格式串）："
diff "$tmp/bi.txt" "$tmp/ov.txt" | head -30
exit 1
