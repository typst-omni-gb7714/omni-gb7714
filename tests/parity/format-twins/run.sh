#!/usr/bin/env bash
# 内建条目格式「孪生」对拍：手册里逐类型展示的那些「内建条目格式」模板串，
# 当作 `custom-drivers` 跑一遍，必须**逐字复现**内置渲染。
#
# 两条硬规矩，都是被真事故逼出来的：
#
# ① **模板串从手册里现抽，不在这里手抄。**
#    曾经手抄一份放在本文件里，于是手册改了、这里没改，闸照样绿——它验的是「手抄那份」
#    与内置一致，而不是「手册那份」与内置一致。手册窗口与代码脱钩，正是本闸要防的事。
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
#    现在补 `online-nodate`（有 urldate 无 date）与 `book-noloc`（无出版地）。
#
# ④ **取值链（fallback）要有条目戳得穿。**
#    `publisher` token 的链是 `publisher → school → organization → institution`（学位论文 D、
#    档案 A、连续出版物是 `institution → publisher → school → organization`）。
#    手册曾把链*手写*成 `institution|school|organization`——**漏了 `publisher` 那一档**，
#    而语料里的 thesis 恰好没有 `publisher` 字段，于是闸绿着、错着。
#    现在补 `thesis-pub` / `archive-pub`（publisher 与 school 并存）与 `patent-both`
#    （holder 与 author 并存）三条，专戳取值链。
#
# 用法：bash tests/parity/format-twins/run.sh
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../../.." && pwd)"
TYP="${TYPST:-typst}"
cd "$ROOT"

tmp="$DIR/.tmp"; mkdir -p "$tmp"; trap 'rm -rf "$tmp"' EXIT
# 根相对路径：typst 的 read 以 --root 为根解析以 `/` 开头的路径。
rel="/tests/parity/format-twins/.tmp"

# ── ① 从手册现抽 (entrytype, bib-fields) 对 ────────────────────────────────
python3 - "$ROOT" "$tmp" <<'PY'
import re, sys
root, tmp = sys.argv[1], sys.argv[2]
src = open(f"{root}/easy-zh-manual/template/main.typ").read()
# 每张类型卡片是一个字典字面量，含 `entrytype:` 与 `bib-fields:`。
# `entrytype` 可能列多个别名（`"@thesis / @mastersthesis / @phdthesis"`）——取第一个作驱动键。
# 两者必须*成对*抽：先按 `entrytype` 切段，再在段内找 `bib-fields`，
# 免得某张卡片的 entrytype 与另一张的 bib-fields 错配（正则一路 `.*?` 找过去正会这样）。
chunks = re.split(r'\n\s*entrytype:\s*"', src)[1:]
cards = []
for ch in chunks:
    et = ch[:ch.index('"')]
    m = re.search(r'bib-fields:\s*"((?:[^"\\]|\\.)*)"', ch)
    if m is None:
        continue
    cards.append((et.split("/")[0].strip().lstrip("@"), m.group(1)))
if len(cards) < 12:
    sys.exit(f"从手册里只抽到 {len(cards)} 个内建格式串——抽取规则与手册结构脱钩了，先修抽取")
open(f"{tmp}/drivers.txt", "w").write("\n".join(f'  {t}: "{f}",' for t, f in cards))
open(f"{tmp}/count.txt", "w").write(str(len(cards)))
PY
[ -s "$tmp/drivers.txt" ] || { echo "  [FAIL] 从手册抽取内建格式串失败"; exit 1; }

# ── ② 语料：每类两条——「字段齐全」与「只有必备字段」（可选字段全缺） ────────
cat > "$tmp/e.bib" <<'BIB'
@book{book, author={{甲}}, editor={{编}}, translator={{译}}, title={题}, subtitle={副}, titleaddon={辅}, edition={2}, location={地}, publisher={社}, date={2020}, pages={11-22}, url={https://u.cn}, doi={10.1/d}, langid={chinese}}
@book{book-thin, author={{甲}}, title={题}, location={地}, publisher={社}, date={2020}, langid={chinese}}
@book{book-noloc, author={{甲}}, title={题}, edition={2}, publisher={社}, date={2020}, langid={chinese}}
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

common='#import "/lib.typ": *
#set text(lang: "zh", font: "Noto Serif CJK SC")
#set page(width: 40cm, height: auto)'

cat > "$tmp/bi.typ" <<EOF
$common
#show: gb7714.with(full: true, version: 2025)
#bibliography(read("$rel/e.bib"), title: none, full: true)
EOF

{
  echo "$common"
  echo '#show: gb7714.with(full: true, version: 2025, custom-drivers: ('
  cat "$tmp/drivers.txt"
  echo '))'
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
  echo "  built-in-format-twins: $(cat "$tmp/count.txt") 类 / $n_entry 条语料（字段齐全 · 只有必备字段 · 专戳取值链）逐字复现内置"
  exit 0
fi

echo "  [FAIL] 手册的内建格式串与内置渲染不一致（左=内置，右=手册格式串）："
diff "$tmp/bi.txt" "$tmp/ov.txt" | head -30
exit 1
