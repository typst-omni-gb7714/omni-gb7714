#!/usr/bin/env bash
# 笔画排序双驱动交叉比对测试套件：胡振震样式（biblatex-gb7714-2015）与 omni-gb7714 渲染同一 refs.bib，
# 比对著者-出版年制下中文姓名按笔画排序的结果是否一致。
# 依赖：xelatex + biber（latexmk）、typst。从任意 cwd 运行都可以。
# 用法：bash tests/parity/stroke-sort/run.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
source "$ROOT/tests/fonts/env.sh"
export TYPST="${TYPST:-$ROOT/tests/bin/typst-0.14.2}"
exec python3 "$HERE/run.py" "$@"
