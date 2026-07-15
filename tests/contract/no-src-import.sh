#!/usr/bin/env bash
# 测试只许走公共 API。
#
# `tests/` 里任何文件都不得 `#import "/src/..."` —— 一旦测试伸手进内部模块，
# src 的重构（拆文件、改函数名）就会连带弄坏一堆与之无关的测试，
# 而那些测试本该只关心「用户看到的行为变没变」。
#
# 唯一的例外是 `tests/unit/`：那一层*就是*直接测内部模块的算法（语言判定的准确率、
# 姓名的 CJK↔拉丁间距），它们本来就该伸手进去。除此之外一律走 lib.typ。
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
bad=$(grep -rln '#import "/src/\|#import "\.\./\.\./src/\|#import "\.\./src/' "$ROOT/tests" --include='*.typ' \
      | grep -v '/tests/unit/' || true)
if [ -n "$bad" ]; then
  echo "FAIL: 这些测试直接 import 了 src/ 的内部模块，请改走公共 API（lib.typ）："
  echo "$bad" | sed "s|$ROOT/||;s/^/  - /"
  exit 1
fi
echo "  ✅ 测试全部只走公共 API（未直接 import src/ 内部模块）"
