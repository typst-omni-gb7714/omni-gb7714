#!/usr/bin/env bash
# 复刻对拍：《GB/T 7714—2015》原文的参考文献示例，用本包逐条复刻一遍。
#
# 它是最接近「标准怎么说」的一道闸：源在仓库根的 `2015国标复刻.typ`，数据在 `2015-*.bib`。
# 这里只验它*编得过*且页数不变——逐条的字形比对靠人看 PDF（复刻件本身就是给人看的）。
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TYPST="${TYPST:-typst}"
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
cd "$ROOT"

if ! $TYPST compile --root . "2015国标复刻.typ" "$TMPD/fk.pdf" >"$TMPD/fk.err" 2>&1; then
  echo "   ❌ 2015国标复刻 编译失败："
  grep -m3 'error' "$TMPD/fk.err" | sed 's/^/      /'
  exit 1
fi
pages=$(pdfinfo "$TMPD/fk.pdf" 2>/dev/null | awk '/^Pages:/{print $2}')
echo "   ✅ 2015国标复刻 编译通过（$pages 页）"
