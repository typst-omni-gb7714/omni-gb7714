#!/usr/bin/env bash
# 单元层：直接测内部模块的算法。
#
# 这是 `tests/` 里**唯一**允许 `#import "/src/..."` 的地方（`contract/no-src-import.sh` 只放它过）。
# 为什么要有这一层：有些东西从公共 API 看不见——
#   - 语言判定的*准确率*（59 例带标注的语料，靠 `#assert` 自断言）；
#   - 姓名的 CJK↔拉丁间距（`pdftotext` 会在 CJK-拉丁边界*自动补空格*，
#     把「昂温S」和「昂温 S」抹成一个样子——只能在字符串层比对）。
# 除此之外的一切都该走 lib.typ、进矩阵。
#
# 用法：bash tests/unit/run.sh
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"
TYPST="${TYPST:-typst}"
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
pass=0; fail=0

# 每个 .typ 靠内部的 `#assert` 自断言：编译过 = 全部通过。
for f in *.typ; do
  if $TYPST compile --root "$ROOT" "$f" "$TMPD/u.pdf" >/dev/null 2>"$TMPD/u.err"; then
    pass=$((pass+1))
  else
    echo "   ❌ $f"
    grep -m2 'error\|assert' "$TMPD/u.err" | sed 's/^/      /'
    fail=$((fail+1))
  fi
done

echo "   ─────"
if [ "$fail" -eq 0 ]; then
  echo "   ✅ $pass 个单元探针全部通过"
  exit 0
fi
echo "   ❌ 失败 $fail · 通过 $pass"
exit 1
