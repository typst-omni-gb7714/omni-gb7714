#!/usr/bin/env bash
# LaTeX 命令对齐测试套件：alignment.typ 把转义、重音、字母符号、标点连字、字体命令逐条渲染，
# 断言 pdftotext 输出与 biblatex 实测基准一致（基准逐条列在 alignment.typ 末尾注释里）。
# 用法：bash tests/parity/latex/run.sh   （TYPST=/path 可指定二进制）
set -u
# 每次运行一套自己的临时文件：写死的 /tmp 路径会被并发跑的另一个测试进程覆写，静默串台成假红
# （曾实测到：oracle 渲染第 5 篇时，pdftotext 读到的是另一进程刚写进去的第 61 篇）。
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
cd "$(dirname "$0")"
TYPST="${TYPST:-typst}"
pass=0; fail=0

if ! $TYPST compile --root ../../.. alignment.typ $TMPD/lx.pdf >/dev/null 2>$TMPD/lx.err; then
  echo "  [FAIL] alignment.typ 编译失败："; sed 's/^/        /' $TMPD/lx.err | head -3
  echo "  latex: pass=0 fail=1"; exit 1
fi
txt=$(pdftotext $TMPD/lx.pdf - 2>/dev/null)

want() {  # want <说明> <必须含的子串>
  if grep -qF "$2" <<<"$txt"; then pass=$((pass+1)); else
    echo "  [FAIL] $1：应含「$2」但缺失"; fail=$((fail+1)); fi
}
absent() {  # absent <说明> <必须不含的子串（未转换的裸 LaTeX）>
  if grep -qF "$2" <<<"$txt"; then echo "  [FAIL] $1：不应含未转换的「$2」"; fail=$((fail+1));
  else pass=$((pass+1)); fi
}

# 转义：`% & # _ { } $` 去反斜杠为字面量。
want "esc 百分号"   "Esc pct 50% off"
want "esc &"        "Esc amp R&D dept"
want "esc #"        "Esc hash C#sharp"
want "esc _"        "Esc under file_name"
want "esc 花括号"   "Esc brace {x} here"
want "esc \$"       "Esc dollar \$5 fee"
# 重音与特殊字母。
want "重音 acute/diaeresis" "Accent café naïve"
want "重音 caron"   "Accent Česká"
want "连字 oe/ae"   "Letter œuvre caesar æ"
want "字母 o/l/ss"  "Letter øre Wład Weiß"
# 字母符号命令（吞尾空格）与行内符号。
want "符号 dag/ddag/P" "Sym †and ‡and ¶"
want "符号 trademark"  "Sym Brand™x"
want "符号 S/copy/pounds" "Sym §5 ©2020 £50"
want "省略号 ldots"  "Ellipsis a …z end"
# 标点连字。
want "破折 -- 与 ---" "Dash 1–5 and yes—no"
want "TeX 引号连字"   "Quote “double” and ‘single’"
want "撇号恒右单引号" "Apostrophe O’Brien don’t"
# textbackslash 吞尾空格、`^` 字面量。
want "反斜杠/插入符"  "back \\and caret ^"
# 字体命令与 url 去壳。
want "字体命令脱壳"   "Font bold italic sc tt"
want "url 去壳裸链"   "Link http://example.com done"
# 未转换的裸 LaTeX 必须消失，证明确实做了转换。
absent "textbf 残留"  "textbf"
absent "copyright 残留" "copyright"
absent "ldots 残留"   "ldots"
absent "oe 残留"      "\\oe"

echo
echo "  latex: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
