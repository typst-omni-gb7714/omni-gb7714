#!/usr/bin/env bash
# 由测试入口 source：优先加载固定字体，不改变用户的系统字体配置。
_test_font_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$_test_font_dir/setup.py" --check || return 1
case "${TYPST_FONT_PATHS:-}" in
  "$_test_font_dir"|"$_test_font_dir":*) ;;
  *) export TYPST_FONT_PATHS="$_test_font_dir${TYPST_FONT_PATHS:+:$TYPST_FONT_PATHS}" ;;
esac
unset _test_font_dir
