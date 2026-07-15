#!/usr/bin/env bash
# config-sync 测试套件：断言 lib.typ 的 `config` 转发字典与 src/api.typ 的 `gb7714` 工厂签名参数逐一对应。
# 用法：bash tests/contract/config-sync.sh
# 背景：转发层 lib.typ 手工把 82 个 `gb7714` 参数转发给引擎工厂（见 lib.typ「位置必须跟上方签名同步」注释）。
# 工厂新增或改名一个参数、而 lib 的 config 忘了同步时，引擎会静默用自己的默认值，没有编译错误——
# 本测试套件把这种漂移变成硬失败。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="$ROOT/src/api.typ"
LIB="$ROOT/lib.typ"

# 工厂参数名：`#let gb7714(` 到 `) = {` 之间、行首两空格缩进的 `name:`（doc-comment 格式固定一参一行）。
factory=$(awk '/^#let gb7714\(/{f=1} f{print} f&&/^\) = /{exit}' "$API" \
  | grep -oE '^  [a-z][a-z0-9-]*:' | tr -d ' :' | sort -u)
# config 转发键：lib.typ `let config = (` 到其闭合 `)` 之间的所有 `key:`（每行可多个）。
config=$(awk '/let config = \(/{f=1} f{print} f&&/^ +\)/{exit}' "$LIB" \
  | grep -oE '[a-z][a-z0-9-]*:' | tr -d ' :' | sort -u)

miss=$(comm -23 <(printf '%s\n' "$factory") <(printf '%s\n' "$config") || true)
extra=$(comm -13 <(printf '%s\n' "$factory") <(printf '%s\n' "$config") || true)

fail=0
if [ -n "$miss" ]; then
  echo "FAIL: gb7714 工厂声明了这些参数、但 lib.typ 的 config 未转发（引擎将静默用默认值）："
  echo "$miss" | sed 's/^/  - /'
  fail=1
fi
if [ -n "$extra" ]; then
  echo "FAIL: lib.typ config 转发了这些键、但 gb7714 工厂无此参数（拼错/过时）："
  echo "$extra" | sed 's/^/  - /'
  fail=1
fi
# 末行必须是显式 exit：`[ $fail -ne 0 ] && exit $fail` 在 set -e 下，fail=0 时那句返回 1，
# 整个脚本跟着以 1 退出——全绿却报红。（原脚本一直被 `if out=$(..)` 包着调用，掩住了。）
if [ $fail -ne 0 ]; then exit $fail; fi
echo "config-sync: gb7714 工厂 $(printf '%s\n' "$factory" | grep -c .) 参数与 lib config 逐一对应"
exit 0
