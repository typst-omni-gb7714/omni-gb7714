// 测试字体集中在这里；中日韩不交给系统的自动回退，符号使用 Typst 内置等宽字体补齐。
#let test-font-stack = ("Libertinus Serif", "Noto Sans CJK SC", "DejaVu Sans Mono")
#let test-fonts(body) = {
  set text(font: test-font-stack)
  body
}
