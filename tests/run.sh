#!/usr/bin/env bash
# 发布测试入口：运行代码来自实际preview包，临时映射为原测试所需的根目录。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$HERE/run-preview.py" "$@"
