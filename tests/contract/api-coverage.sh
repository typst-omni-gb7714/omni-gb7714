#!/usr/bin/env bash
# API 覆盖：**每一个公共参数都必须被矩阵测到**。
#
# 参数清单不按路径写死，而是从 `lib.typ` 的三个公共入口的*签名*里抽出来
# （`gb7714(` / `bibliography(` / `cite(`）——src 的模块怎么拆、文件怎么挪都不影响本检查。
# 找不到入口就直接 FAIL（说明入口被改名了，这本身就是该知道的事）。
#
# 判据：参数名在 `tests/matrix/` 的某个 .typ 源码里出现过。矩阵的写法是
# 「一个参数 = 一个文件」，参数名一定出现在 `#show: spec.with(param: ..)` 头与各 `#case` 的配置里。
#
# 加了新参数忘了加测试 → 本检查变红。这是「全面完整覆盖」这句话的机器版本。
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB="$ROOT/lib.typ"
MATRIX="$ROOT/tests/matrix"
fail=0

# 从 lib.typ 抽某个公共函数的参数名（行首两空格的 `name:`，doc-comment 一参一行）。
params-of() {
  local fn="$1"
  awk -v fn="^#let $fn\\\\(" '$0 ~ fn {f=1} f {print} f && /^\) = /{exit}' "$LIB" \
    | grep -oE '^  [a-z][a-z0-9-]*:' | tr -d ' :' | sort -u
}

check-entry() {
  local fn="$1" label="$2"
  local ps; ps=$(params-of "$fn")
  if [ -z "$ps" ]; then
    echo "FAIL: 在 lib.typ 里找不到入口 \`$fn(\` 的签名（改名了？）"
    fail=1; return
  fi
  local n=0 missing=""
  while read -r p; do
    [ -z "$p" ] && continue
    n=$((n+1))
    # 参数名在矩阵源码里出现过即算覆盖（作为配置键、或作为 spec 头里的参数名）。
    # 只搜 .typ 源码，不搜 _golden（golden 里印的是渲染结果，参数名碰巧出现在里面不算覆盖）。
    if ! grep -rqF --include='*.typ' --exclude-dir=_golden -- "$p" "$MATRIX"; then
      missing="$missing $p"
    fi
  done <<< "$ps"
  if [ -n "$missing" ]; then
    echo "FAIL: $label 的这些参数在 tests/matrix/ 里一次都没出现："
    for m in $missing; do echo "  - $m"; done
    fail=1
  else
    echo "  ${label}：$n 个参数全部被矩阵覆盖"
  fi
}

echo "api-coverage（参数清单从 lib.typ 的签名现抽，不写死路径）"
check-entry gb7714       "gb7714(..)"
check-entry bibliography "bibliography(..)"
check-entry cite         "cite(..)"

# 矩阵的每个文件都得有 `//! param:` 头——它是「这个文件测的是哪个 API」的机器可读声明。
noheader=$(find "$MATRIX" -name '*.typ' -not -path '*/_golden/*' \
  -exec sh -c 'head -1 "$1" | grep -qE "^//! (param|combo):" || echo "$1"' _ {} \;)
if [ -n "$noheader" ]; then
  echo "FAIL: 这些矩阵文件缺 \`//! param:\` / \`//! combo:\` 头："
  echo "$noheader" | sed "s|$ROOT/||;s/^/  - /"
  fail=1
fi

# `pid-priority` 的缺省值同时是「残缺名次表」的补齐序，所以它在两处写着：api 的签名默认值、
# `pids/built-in.typ` 的 `DEFAULT-PID-PRIORITY`。两者漂移会让「默认次序」与「补齐次序」不一致，
# 而这种不一致不会报错、只会静默排错顺序。
api_pp=$(grep -oE '^  pid-priority: \(.*\),' "$ROOT/src/api.typ" | head -1 | sed 's/^  pid-priority: (//;s/),$//' | tr -d ' "')
pids_pp=$(grep -oE '^#let DEFAULT-PID-PRIORITY = \(.*\)' "$ROOT/src/elements/pids/built-in.typ" | sed 's/.*= (//;s/)$//' | tr -d ' "')
if [ "$api_pp" != "$pids_pp" ]; then
  echo "FAIL: pid-priority 的缺省值与 DEFAULT-PID-PRIORITY 漂移了："
  echo "  api.typ:              ($api_pp)"
  echo "  pids/built-in.typ:    ($pids_pp)"
  fail=1
else
  echo "  ✅ pid-priority 缺省值与补齐序一致（$api_pp）"
fi

[ $fail -eq 0 ] && echo "  ✅ 三个公共入口的参数无一遗漏"
exit $fail
