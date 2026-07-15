#!/usr/bin/env bash
# errors-sync 测试套件：两张手动维护表的漂移防护（批次三①，用户要求「每一个手动维护处都要有防护」）。
# 用法：bash tests/contract/errors-sync.sh
# A：`_MESSAGES` 的 id 与 errors.raise/message 调用点双向比对，调用了未登记的 id 或表里有死条目都 FAIL。
# B：`_ENUMS` 值域与 api.typ 对应参数 doc-comment 里引用的值双向比对，文档写了表没有、表有文档没写都 FAIL。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ERR="$ROOT/src/errors.typ"
API="$ROOT/src/api.typ"
fail=0

# A：消息表与调用点双向比对。
ids_called=$(grep -rhoE '_?errors\.(raise|message)\("[a-z-]+\.[a-z-]+"' "$ROOT/src" "$ROOT/lib.typ" \
  | grep -oE '"[a-z-]+\.[a-z-]+"' | tr -d '"' | sort -u)
ids_table=$(awk '/^#let _MESSAGES = \(/{f=1} f&&/^\)$/{exit} f' "$ERR" \
  | grep -oE '^  "[a-z-]+\.[a-z-]+":' | grep -oE '"[^"]+"' | tr -d '"' | sort -u)
miss=$(comm -23 <(printf '%s\n' "$ids_called") <(printf '%s\n' "$ids_table") || true)
dead=$(comm -13 <(printf '%s\n' "$ids_called") <(printf '%s\n' "$ids_table") || true)
if [ -n "$miss" ]; then echo "FAIL: 这些错误 id 被调用但未登记进 _MESSAGES:"; echo "$miss" | sed 's/^/  - /'; fail=1; fi
if [ -n "$dead" ]; then echo "FAIL: _MESSAGES 里这些 id 无任何调用点(死条目):"; echo "$dead" | sed 's/^/  - /'; fail=1; fi

# B：值域表与 doc-comment 双向比对。
# 每个 `_ENUMS` 参数在 api.typ 有一处权威 doc（锚点是参数声明行）。从声明行起、到下一个参数声明行止，
# 收集 doc 里的「小写值」引用与字面量 `none` 的反引号引用，与表比对。
enum_params=$(awk '/^#let _ENUMS = \(/{f=1} f&&/^\)$/{exit} f' "$ERR" | grep -oE '^  "[a-z-]+"' | tr -d ' "')
anchor_of() {
  case "$1" in
    numbering-style) echo "numbering-style:";;
    number-align) echo "number-align:";;
    number-placement) echo "number-placement:";;
    cite-form) echo "cite-form:";;
    footnote-numbering-style) echo "footnote-numbering-style:";;
    supplement-style) echo "cite-supplement-style:";;
    punct-style) echo "cite-punct-style:";;
    bib-punct-style) echo "bib-punct-style:";;
    entry-lang-detect) echo "entry-lang-detect:";;
    sort-zh-by) echo "bib-sort-zh-by:";;
    titles-text-case) echo "titles-text-case:";;
    date-fallback) echo "date-fallback:";;
    page-range-style) echo "page-range-style:";;
    *) echo "";;
  esac
}
for p in $enum_params; do
  a="$(anchor_of "$p")"
  if [ -z "$a" ]; then echo "FAIL: _ENUMS 参数 $p 没有登记 doc 锚点(errors-sync.sh 的 anchor 表)"; fail=1; continue; fi
  block=$(awk -v a="$a" 'BEGIN{f=0}
    f==0 && match($0, "^ +" a) {f=1; ind=RSTART; pre=substr($0,1,match($0,/[a-z]/)-1); print; next}
    f==1 && match($0, "^" pre "[a-z][a-z0-9-]*: ") {exit}
    f==1 {print}' "$API")
  if [ -z "$block" ]; then echo "FAIL: api.typ 找不到锚点 $a($p)"; fail=1; continue; fi
  doc_vals=$(printf '%s\n' "$block" | grep -oE '`"[a-z][a-z0-9-]*"`' | tr -d '`"' | sort -u)
  table_vals=$(awk -v p="\"$p\":" '$0 ~ "^  "p {f=1} f{print} f&&/\),$/{exit}' "$ERR" \
    | grep -oE '"[a-z][a-z0-9-]*"' | tr -d '"' | grep -v "^$p$" | sort -u)
  miss=$(comm -23 <(printf '%s\n' "$table_vals") <(printf '%s\n' "$doc_vals") || true)
  extra=$(comm -13 <(printf '%s\n' "$table_vals") <(printf '%s\n' "$doc_vals") || true)
  if [ -n "$miss" ]; then echo "FAIL: $p 的值在 _ENUMS 有而 doc($a)未引用: $(echo $miss)"; fail=1; fi
  if [ -n "$extra" ]; then echo "FAIL: $p 的 doc($a)引用了 _ENUMS 没有的值: $(echo $extra)"; fail=1; fi
  # `none` 取值：表里有 `none` 时，doc 里必须出现反引号 `none`。
  if awk -v p="\"$p\":" '$0 ~ "^  "p {f=1} f{print} f&&/\),$/{exit}' "$ERR" | grep -q "none"; then
    printf '%s\n' "$block" | grep -q '`none`' || { echo "FAIL: $p 的 _ENUMS 含 none 档但 doc($a)未见 \`none\`"; fail=1; }
  fi
done

[ $fail -eq 0 ] && echo "errors-sync: _MESSAGES $(printf '%s\n' "$ids_table" | grep -c .) 条 / _ENUMS $(printf '%s\n' "$enum_params" | grep -c .) 参数 双向对齐"
exit $fail
