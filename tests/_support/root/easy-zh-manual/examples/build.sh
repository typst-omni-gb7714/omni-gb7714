#!/usr/bin/env bash
# 编译手册示例截图：easy-zh-manual/examples/egN.typ → egN.pdf（供手册 #image 引用）。
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
TYP="${TYPST:-typst}"
for src in "$DIR"/eg*.typ; do
  out="${src%.typ}.pdf"
  $TYP compile --root "$ROOT" "$src" "$out" && echo "[examples] → $(basename "$out")"
done
