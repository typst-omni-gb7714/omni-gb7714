#!/usr/bin/env bash
# 矩阵测试：一个参数 = 一个文件 = 一份 golden。
#
# 每个 .typ 编译成单页长条 PDF，用 `pdftotext -layout` 抽成文本，与 `_golden/` 下的基准逐行比对。
# `-layout` 保留水平位置，所以悬挂缩进、编号列宽、对齐这类*几何*变化也会在 golden 里留下痕迹。
#
# 双版校验（单 golden）：golden 钉在默认 typst（0.14）上逐行*精确*比对。此外每个非 `//! typst: 0.15`
# 的用例还用 tests/bin/typst-0.15.0 编一遍，与*同一份* golden 做「去空白」比对——0.14↔0.15 的合法
# 差异只该是折行 / 空行（typst 排版引擎变化），去掉空白后内容必须逐字一致；不同即 0.15 上的*真回归*
# （`DIFF15`）。没有 0.15 二进制时副比对自动跳过（退化成单版）。
#
# 用法：
#   bash tests/matrix/run.sh            比对 golden，有差异即失败并打印 diff
#   bash tests/matrix/run.sh --update   重新生成 golden（**改完 src 后要人工审这些 diff**）
#   bash tests/matrix/run.sh 03-names   只跑某一组
#
# golden 的差异*就是*该人工审核的地方——这是本套件的全部意义。
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"
source "$ROOT/tests/fonts/env.sh" || exit 1
TYPST="${TYPST:-$ROOT/tests/bin/typst-0.14.2}"
TYPST15="${TYPST15:-$ROOT/tests/bin/typst-0.15.0}"
GOLD="_golden"
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT

UPDATE=0; FILTER=""
for a in "$@"; do
  case "$a" in
    --update) UPDATE=1 ;;
    *) FILTER="$a" ;;
  esac
done

# 单个用例：编译 → 抽文本 → 与 golden 比对。作为子进程被 xargs 并行调用。
run-one() {
  local f="$1" tmp="$2" update="$3"
  local rel="${f#./}"                       # 03-names/show-anon.typ
  local out="$tmp/$(echo "$rel" | tr '/' '_')"
  local gold="$GOLD/${rel%.typ}.txt"
  # `//! typst: 0.15` 头指定用 0.15 二进制跑（原生 target / group 路由需要它）；这类用例的 golden
  #   本就在 0.15 上生成，只在 0.15 上校验（下方副比对不再叠加）。
  local bin="$TYPST" pinned15=0
  if head -5 "$f" | grep -q '^//! typst: 0.15'; then
    bin="$TYPST15"; pinned15=1
    [ -x "$bin" ] || { echo "SKIP|$rel|无 typst 0.15 二进制"; return 0; }
  fi
  if ! "$bin" compile --ignore-system-fonts --root "$ROOT" "$f" "$out.pdf" >"$out.err" 2>&1; then
    # 不要 `cut -c` 截断：它按*字节*切，会把一个中文字符从中间劈开、
    # 吐出非法 UTF-8（下游 python 读这段输出会直接抛 UnicodeDecodeError）。
    echo "FAIL|$rel|编译失败：$(grep -m1 '^error' "$out.err")"
    return 0
  fi
  pdftotext -layout "$out.pdf" "$out.txt" 2>/dev/null || { echo "FAIL|$rel|pdftotext 失败"; return 0; }
  if [ "$update" = "1" ]; then
    mkdir -p "$(dirname "$gold")"
    cp "$out.txt" "$gold"
    echo "GEN|$rel|"
    return 0
  fi
  if [ ! -f "$gold" ]; then
    echo "FAIL|$rel|缺 golden（先跑 --update）"
    return 0
  fi
  # 主比对：默认 typst（0.14）逐行*精确*对 golden——保留折行 / 几何等版面细节。
  if ! diff -q "$gold" "$out.txt" >/dev/null; then
    cp "$out.txt" "$tmp/diff_$(echo "$rel" | tr '/' '_')"
    echo "DIFF|$rel|$(diff "$gold" "$out.txt" | grep -c '^[<>]') 行不同"
    return 0
  fi
  # 副比对（双版）：非 0.15-pinned 的用例也用 0.15 编一遍，与*同一份* golden 做「去空白」比对。
  #   0.14↔0.15 的合法差异只该是折行 / 空行（typst 排版引擎变化），去掉空白后内容必须逐字一致；
  #   一旦不同就是 0.15 上的*真回归*（如 per-cite 覆盖在 0.15 失效、原生路由改了编号）。去空白是
  #   刻意的：单 golden 钉在 0.14，副比对只查内容 / 行为、放过纯排版噪声（详见 README「双版」一节）。
  if [ "$pinned15" = 0 ] && [ -x "$TYPST15" ]; then
    if ! "$TYPST15" compile --ignore-system-fonts --root "$ROOT" "$f" "$out.15.pdf" >"$out.15.err" 2>&1; then
      echo "FAIL15|$rel|0.15 编译失败：$(grep -m1 '^error' "$out.15.err")"
      return 0
    fi
    pdftotext -layout "$out.15.pdf" "$out.15.txt" 2>/dev/null
    if [ "$(tr -d ' \t\n' < "$gold")" != "$(tr -d ' \t\n' < "$out.15.txt")" ]; then
      cp "$out.15.txt" "$tmp/diff15_$(echo "$rel" | tr '/' '_')"
      echo "DIFF15|$rel|0.15 内容与 golden 不一致（去空白后仍不同 = 真回归，非排版差异）"
      return 0
    fi
  fi
  echo "OK|$rel|"
}
export -f run-one
export TYPST TYPST15 GOLD ROOT

pattern="."
[ -n "$FILTER" ] && pattern="./$FILTER"
files=$(find $pattern -name '*.typ' -not -path './_golden/*' | sort)
[ -z "$files" ] && { echo "没有匹配的用例：$FILTER"; exit 1; }

# 并行编译（Typst 单进程编译本身不吃满多核）。
results=$(echo "$files" | xargs -P 8 -I{} bash -c 'run-one "$@"' _ {} "$TMPD" "$UPDATE")

ok=0; fail=0; diffs=0; skip=0; gen=0; diffs15=0
while IFS='|' read -r status rel msg; do
  case "$status" in
    OK)   ok=$((ok+1)) ;;
    GEN)  gen=$((gen+1)) ;;
    SKIP) skip=$((skip+1)); echo "   ⏭  ${rel}（${msg}）" ;;
    FAIL) fail=$((fail+1)); echo "   ❌ ${rel}　$msg" ;;
    FAIL15) fail=$((fail+1)); echo "   ❌ ${rel}　$msg" ;;
    DIFF) diffs=$((diffs+1)); echo "   ⚠️  ${rel}　$msg" ;;
    DIFF15) diffs15=$((diffs15+1)); echo "   ❌ ${rel}　$msg" ;;
  esac
done <<< "$(echo "$results" | sort)"

if [ "$UPDATE" = "1" ]; then
  echo "   ✅ 重新生成 golden：$gen 个（跳过 ${skip}）"
  echo "   ⚠️  用 git diff 审一遍 tests/matrix/_golden/ —— 每一处变化都该说得出为什么"
  exit 0
fi

echo "   ─────"
if [ "$fail" = 0 ] && [ "$diffs" = 0 ] && [ "$diffs15" = 0 ]; then
  echo "   ✅ $ok 个用例与 golden 一致（0.14 精确 + 0.15 去空白双版校验，跳过 ${skip}）"
  exit 0
fi
[ "$diffs" -gt 0 ] && {
  echo
  echo "   有 $diffs 个用例与 golden 不同（0.14）。逐个看："
  echo "     diff tests/matrix/_golden/<组>/<参数>.txt <(重新编译的输出)"
  echo "   确认是有意的改动之后，跑 bash tests/matrix/run.sh --update 重新生成。"
}
[ "$diffs15" -gt 0 ] && {
  echo
  echo "   有 $diffs15 个用例在 0.15 上*内容*与 golden 不一致（去空白后仍不同）——这是 0.15 真回归，"
  echo "   不是折行差异。逐个看： diff <(tr -d ' ' <golden) <(0.15 编译输出 tr -d ' ')"
}
echo "   ❌ 失败 $fail · 0.14差异 $diffs · 0.15回归 $diffs15 · 通过 $ok"
exit 1
