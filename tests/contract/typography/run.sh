#!/usr/bin/env bash
# 字形开关的「到底有没有生效」闸。
#
# 文本 golden（`pdftotext`）看不见字形：斜体、粗体、上标、超链接——两档抽出来的文字一模一样。
# 于是这些参数在矩阵里只能记一句「两档 golden 相同」，一旦有人把它们改成*什么都不做*，
# 矩阵是不会红的。
#
# 这里换个看法：渲染成 **SVG**（字形进得了标记），断言「开」与「关」两档的输出**必须不同**。
# 它证不了「斜体斜得对不对」（那要人看 PDF），但能证「这个开关确实在改变输出」——
# 一个开关悄悄失效，正是最容易漏掉、也最容易发生的回归。
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../../.. && pwd)"
TYPST="${TYPST:-typst}"
# 临时 .typ 得落在 project root 里面——typst 不接受 root 之外的源文件。
TMPD="$(mktemp -d "$ROOT/tests/.tmp-typo-XXXXXX")"; trap 'rm -rf "$TMPD"' EXIT
pass=0; fail=0

# differs <名字> <正文> <关档配置> <开档配置> [页宽] [语料]
#
# 页宽与语料都可换：有些开关只有在*真的断行*时才看得见（断字、URL 软连字符、悬挂缩进），
# 有些要特定数据才触发（多卷书的卷号间距）。探针造不出触发条件，就会把「开关有效」误判成「开关失效」。
differs() {
  local label="$1" cites="$2" off="$3" on="$4"
  local width="${5:-16cm}" bibfile="${6:-main}"
  for side in off on; do
    local cfg; [ "$side" = off ] && cfg="$off" || cfg="$on"
    cat > "$TMPD/$side.typ" <<TYP
#import "/lib.typ": *
#set page(width: $width, height: auto, margin: 5mm)
#set text(lang: "zh", size: 9pt)
#show: gb7714.with($cfg)
$cites
#bibliography(bytes(read("/tests/_fixture/$bibfile.bib")), title: none, full: false)
TYP
    if ! $TYPST compile --root "$ROOT" "$TMPD/$side.typ" "$TMPD/$side.svg" --format svg >/dev/null 2>"$TMPD/$side.err"; then
      echo "   ❌ ${label}（$side 档编译失败）"; sed 's/^/      /' "$TMPD/$side.err" | head -2; fail=$((fail+1)); return
    fi
  done
  if cmp -s "$TMPD/off.svg" "$TMPD/on.svg"; then
    echo "   ❌ ${label}：开与关渲出来*一模一样* → 这个开关没在做事"
    fail=$((fail+1))
  else
    pass=$((pass+1))
  fi
}

differs "italic-book-title"    '#cite(<bm-en>)' ''                          'italic-book-title: true'
differs "italic-journal"       '#cite(<aj-en>)' ''                          'italic-journal: true'
differs "bold-journal-volume"  '#cite(<aj-en>)' ''                          'bold-journal-volume: true'
differs "hyperlink"            '#cite(<bm-online>)' ''                      'hyperlink: false'
differs "hyperlink-title"      '#cite(<bm-online>)' ''                      'hyperlink-title: true'
differs "cite-form super/inline" '#cite(<bm-zh>)' 'cite-form: "inline"'     'cite-form: "super"'
differs "cite-supplement-style"  '#cite(<bm-zh>, supplement: [12])' 'cite-supplement-style: "compact"' 'cite-supplement-style: "split"'
differs "hyphenate"            '#cite(<aj-en>)#cite(<bm-en>)' ''           'hyphenate: false'          6cm
differs "entry-spacing"        '#cite(<bm-zh>)#cite(<bm-en>)' ''            'entry-spacing: 2em'
# 悬挂缩进只在「编号不成列」时才由它说了算：成列档（缺省 `"column"`）下余行贴正文列，
# 版式由列宽决定，这个参数不参与（见 BUGS.md #8——doc 那句「传长度则强制」是错的）。
differs "entry-hanging-indent" '#cite(<ic-zh>)' 'number-placement: "inline"' 'number-placement: "inline", entry-hanging-indent: 6em' 6cm
differs "number-align"         '#cite(<bm-zh>)' 'number-width: 3em'         'number-width: 3em, number-align: "right"'
differs "number-gutter"        '#cite(<bm-zh>)' ''                          'number-gutter: 3em'
differs "number-placement"     '#cite(<bm-zh>)' ''                          'number-placement: "margin"'
differs "volume-title-gutter"  '#cite(<ti-multivolume>)' ''                 'volume-title-gutter: 3em'  16cm edge
# `footnote-numbering-use-quan` *不在*本闸里：quan 0.2.1 在用户没配 `quan-init` / `quan-style` 时
# 吐的就是 Unicode 圈码 ①，与缺省引擎逐字节相同——「开关必须改变输出」这条对它*不成立*。
# 它真正的用处在字体缺带圈数字、或编号超过 ㊿（缺省引擎退化成 `(N)`）时。矩阵里有它的两档对照。
differs "url-break-hyphen"     '#cite(<bm-online>)' ''                      'url-break-hyphen: true'    5cm

echo "   ─────"
[ "$fail" -eq 0 ] && { echo "   ✅ $pass 个字形 / 几何开关：开与关的渲染结果确有不同"; exit 0; }
echo "   ❌ 失败 $fail · 通过 $pass"; exit 1
