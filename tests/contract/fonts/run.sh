#!/usr/bin/env bash
# 同时检查真实输出和字体来源，避免文字提取正常、实际字形已变成圈或箭头的假通过。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT/tests/fonts/env.sh"
TYPST="${TYPST:-typst}"
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
bins=("$TYPST")
[ ! -x "$ROOT/tests/bin/typst-0.15.0" ] || bins+=("$ROOT/tests/bin/typst-0.15.0")
for i in "${!bins[@]}"; do
  "${bins[$i]}" compile --ignore-system-fonts --root "$ROOT" \
    "$ROOT/tests/fonts/specimen.typ" "$TMPD/$i.pdf"
  pdffonts "$TMPD/$i.pdf" > "$TMPD/$i.fonts"
  pdftotext "$TMPD/$i.pdf" "$TMPD/$i.txt"
  python3 - "$TMPD/$i.fonts" "$TMPD/$i.txt" <<'PY'
from pathlib import Path
import sys

fonts = [line.split()[0].split('+')[-1] for line in Path(sys.argv[1]).read_text().splitlines()[2:] if line.strip()]
assert any('NotoSansCJKsc-Regular' in name for name in fonts), fonts
assert any('NotoSansCJKsc-Bold' in name for name in fonts), fonts
assert all(name.startswith(('NotoSansCJKsc-', 'LibertinusSerif-', 'DejaVuSansMono')) for name in fonts), fonts
circles = ''.join(map(chr, [*range(0x2460, 0x2474), *range(0x3251, 0x3260), *range(0x32b1, 0x32c0)]))
expected = ('正文首引，再引，合引。默认中文参考文献。' * 2
    + '山田太郎 日本語の参考文献。'
    + '김철수 이영희 박민수 한국어 책 서울 출판사'
    + 'Émile François Иванов Москва'
    + circles + '▸ ⚠️ ✓ ✗ → ⟦⟧')
compact = lambda value: ''.join(value.split())
assert compact(Path(sys.argv[2]).read_text()) == compact(expected), Path(sys.argv[2]).read_text()
PY
done
echo "   ✅ 字体覆盖：中日韩／西文／粗体／圈码／符号，输出与固定字体来源一致"
