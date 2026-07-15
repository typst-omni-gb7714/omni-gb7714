#!/usr/bin/env bash
# 报错用例：每个 .typ **必须编译失败**，且 stderr 含指定的关键词。
#
# 为什么单独成组：这些用例进不了矩阵——矩阵的每个文件都得编得过（它要产出 golden）。
# 一个参数的「非法取值」档天然编不过，只能在这里验。
#
# 断言写在下面的 expect 表里：<文件名>|<stderr 必须含的子串（用 | 再分隔）>
# 报错文案改了，这里就该同步改——报错文案是面向用户的 API，不是内部细节。
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../../.. && pwd)"
TYPST="${TYPST:-typst}"
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
pass=0; fail=0

expect() {
  local f="$1"; shift
  if [ ! -f "$f" ]; then echo "   ❌ $f 不存在"; fail=$((fail+1)); return; fi
  if $TYPST compile --root "$ROOT" "$f" "$TMPD/p.pdf" >/dev/null 2>"$TMPD/p.err"; then
    echo "   ❌ $f 本应报错，却编译成功了"; fail=$((fail+1)); return
  fi
  local miss=""
  for sub in "$@"; do
    grep -qE "$sub" "$TMPD/p.err" || miss="${miss}「${sub}」"
  done
  if [ -n "$miss" ]; then
    echo "   ❌ $f 报错文案缺 $miss"
    echo "      实际：$(grep -m1 'error' "$TMPD/p.err" | cut -c1-120)"
    fail=$((fail+1))
  else
    pass=$((pass+1))
  fi
}

# ── 值域校验（枚举参数收到表外的值）
expect enum-typo-panic.typ                  'numbering-style 收到非法值' '合法值' 'bracket'
expect numbering-circled-dict-panic.typ     '字典形只收' 'circled'
expect numbering-quan-value-panic.typ       '非法值' 'circled'
expect page-range-bad-value.typ             'page-range-style 收到非法值' 'chicago-15'
expect footnote-repeat-style-bad-value-panic.typ  'footnote-repeat-style' '只收 auto' 'shortened'
expect footnote-repeat-style-bad-string-panic.typ 'footnote-repeat-style' '只收 auto' 'short'
expect footnote-repeat-reset-panic.typ      'footnote-repeat-reset' 'selector'
expect ttc-bad-key-panic.typ                'titles-text-case 收到非法键' 'journaltitle|journal'

# ── 结构校验（字典 / 数组的形状不对）
expect style-bad-axis-panic.typ             '只收' '两个键'
expect style-missing-axis-panic.typ         '须同时给出'
expect disambiguate-bad-key-panic.typ       '未知机制' 'given-name'
expect sort-by-bad-key-panic.typ            '未知排序键' '合法键'
expect sort-by-bad-order-panic.typ          'ascending / descending'
expect cite-sort-by-bad-key-panic.typ       'cite-sort-by' '合法键'
expect name-style-string-value-panic.typ    '须是维度字典'
expect name-style-bad-dim-panic.typ         'given-initial-separator' '值域外'
expect name-order-dict-panic.typ            '须同时给出' 'first' 'rest'
expect footnote-ibid-dict-bad-key-panic.typ 'ibid' 'text' 'supplement-separator'
expect custom-terms-wrap-bad-panic.typ      '是模式词|前后缀对'
expect separator-lang-dict-bad-key.typ      '未知键' 'zh / en / ja / ko / ru / fr / rest'

# ── 扩展入口的键校验
expect custom-punct-unknown-key-panic.typ   'custom-punct 的键必须是标点字符本身'
expect custom-marks-bad-value-panic.typ     'custom-marks'
expect custom-fields-reserved-field-panic.typ '与内'
expect custom-drivers-category-word-panic.typ '类别词|entry_type'

# ── 模板 DSL 的语法与语义
expect dsl-guard-type-was-mark-panic.typ    '现在指' 'mark=M'
expect cf-arrow-misuse-panic.typ            '不止一个'
expect cf-arrow-outside-group-panic.typ     '只能作' '守卫组'
expect custom-drivers-unknown-token-panic.typ '既不是内置标识' 'custom-fields'
expect guard-empty-value-panic.typ          '后缺值'
expect guard-ambiguous-or-panic.typ         '裸 token 名' '空非空' '取值'

# ── 数据校验
expect warn-missing-title-panic.typ         '缺 title 字段'
expect latex-strict-command-panic.typ       'foobar|未定义'
expect latex-strict-char-panic.typ          '&|转义'

echo "   ─────"
if [ "$fail" -eq 0 ]; then
  echo "   ✅ $pass 个报错用例：都按预期报了错，文案也对得上"
  exit 0
fi
echo "   ❌ 失败 $fail · 通过 $pass"
exit 1
