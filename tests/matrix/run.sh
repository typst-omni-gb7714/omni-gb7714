#!/usr/bin/env bash
# 矩阵测试：一个参数 = 一个文件 = 一份 golden。
#
# 每个 .typ 编译成单页长条 PDF，用 `pdftotext -layout` 抽成文本，与 `_golden/` 下的基准逐行比对。
# `-layout` 保留水平位置，所以悬挂缩进、编号列宽、对齐这类*几何*变化也会在 golden 里留下痕迹。
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
TYPST="${TYPST:-typst}"
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
  # `//! typst: 0.15` 头指定用 0.15 二进制跑（原生 target / group 路由需要它）。
  local bin="$TYPST"
  if head -5 "$f" | grep -q '^//! typst: 0.15'; then
    bin="$TYPST15"
    [ -x "$bin" ] || { echo "SKIP|$rel|无 typst 0.15 二进制"; return 0; }
  fi
  if ! "$bin" compile --root "$ROOT" "$f" "$out.pdf" >"$out.err" 2>&1; then
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
  if diff -q "$gold" "$out.txt" >/dev/null; then
    echo "OK|$rel|"
  else
    cp "$out.txt" "$tmp/diff_$(echo "$rel" | tr '/' '_')"
    echo "DIFF|$rel|$(diff "$gold" "$out.txt" | grep -c '^[<>]') 行不同"
  fi
}
export -f run-one
export TYPST TYPST15 GOLD ROOT

pattern="."
[ -n "$FILTER" ] && pattern="./$FILTER"
files=$(find $pattern -name '*.typ' -not -path './_golden/*' | sort)
[ -z "$files" ] && { echo "没有匹配的用例：$FILTER"; exit 1; }

# 并行编译（Typst 单进程编译本身不吃满多核）。
results=$(echo "$files" | xargs -P 8 -I{} bash -c 'run-one "$@"' _ {} "$TMPD" "$UPDATE")

ok=0; fail=0; diffs=0; skip=0; gen=0
while IFS='|' read -r status rel msg; do
  case "$status" in
    OK)   ok=$((ok+1)) ;;
    GEN)  gen=$((gen+1)) ;;
    SKIP) skip=$((skip+1)); echo "   ⏭  ${rel}（${msg}）" ;;
    FAIL) fail=$((fail+1)); echo "   ❌ ${rel}　$msg" ;;
    DIFF) diffs=$((diffs+1)); echo "   ⚠️  ${rel}　$msg" ;;
  esac
done <<< "$(echo "$results" | sort)"

if [ "$UPDATE" = "1" ]; then
  echo "   ✅ 重新生成 golden：$gen 个（跳过 ${skip}）"
  echo "   ⚠️  用 git diff 审一遍 tests/matrix/_golden/ —— 每一处变化都该说得出为什么"
  exit 0
fi

echo "   ─────"
if [ "$fail" = 0 ] && [ "$diffs" = 0 ]; then
  echo "   ✅ $ok 个用例与 golden 一致（跳过 ${skip}）"
  exit 0
fi
[ "$diffs" -gt 0 ] && {
  echo
  echo "   有 $diffs 个用例与 golden 不同。逐个看："
  echo "     diff tests/matrix/_golden/<组>/<参数>.txt <(重新编译的输出)"
  echo "   确认是有意的改动之后，跑 bash tests/matrix/run.sh --update 重新生成。"
}
echo "   ❌ 失败 $fail · 差异 $diffs · 通过 $ok"
exit 1
