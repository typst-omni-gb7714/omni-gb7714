//! param: custom-drivers（字面量 · 标点 · 软空格）
//! values: {} verbatim, \{ 转义, 裸标点感知, 方括号, 软空格, 硬空格
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 字面量 / 标点 / 空白", controls: "模板里非 token 的那些字符怎么落地。",
  expect: [*花括号字面量* `{…}`：原样进条目（含 CJK、空格、标点），*不受标点矫正与软空格影响*；
    要写花括号本身用 `\{` `\}`（模板本身是 Typst 字符串，源码里写 `\\{` `\\}`）。反引号不再是元字符。
    *裸标点*（`. , : ; / ( )` 及任何 CJK 标点）原样进条目并*受 `bib-punct-style` 矫正*——
    中文条目下裸写的半角 `,` 渲染成 `，`、`(` 渲染成 `（`；要原样半角就放进花括号 `{,}`。
    *方括号* `[` `]` 是普通字面标点（*恒半角、不自适应*），直接写 `[M]` 就出 `[M]`。
    *软空格*：单个空格按排版规则决定落不落——一般落 1 个；但*贴左标点*（`. , : ; ? ! ) ]` 及所有全角标点）前不落、
    全角标点或开括号后不落。要确切的空格，写*两个及以上*空格（落 n−1 个硬空格），或用花括号把空格裹进去。
    *元字符* `?<` `&<` `>` `{` `}` `=>` `|` 要字面输出，用花括号 verbatim 裹起来。])
#let one(name, tpl) = case(name, gb7714.with(custom-drivers: (book: tpl, article: tpl)), cites: (<bm-zh>, <aj-en>), full: false)
#one("软空格：author . title → 句点贴前、后留一空", "author . title")
#one("软空格：title , year → 中文条目逗号转全角、两侧不留空", "title , year")
#one("软空格：两个 token 之间落 1 空格", "author title year")
#one("硬空格：三个空格 → 落 2 个", "author   title")
#one("花括号把空格裹进去：author { , } title → 原样", "author { , } title")
#one("verbatim 不受标点矫正：{,} 恒半角，裸 , 随条目语言", "author {,} title , year")
#one("verbatim 吃掉相邻软空格：{《} title {》}", "author {《} title {》} year")
#one("方括号恒半角：直接写 [M]", "author . title {[} {M} {]} . year")
#one("裸 [ ] 也是普通字面标点", "author . title [ M ] . year")
#one("转义花括号 \\{ \\}", "author . title \\{备注\\} . year")
#one("元字符字面输出：{?<} {&<} {>} {|} {=>}", "author . title {?<} {&<} {>} {|} {=>} . year")
#one("CJK 标点直接写：、 · 《 》", "author 、 title 《 year 》")
#one("title 与 mark-medium 贴紧：用中性组 title<mark-medium>", "author . title<mark-medium> . publisher")
#one("对照：title mark-medium（软空格落地 → 有空格）", "author . title mark-medium . publisher")
