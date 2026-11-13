//! param: bib-numbering-style
//! values: auto, bracket, paren, dot, plain, fullwidth-bracket, fullwidth-paren, shell, circled, (circled: "quan"), none
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-numbering-style", controls: "顺序编码制的编号形态（文献表与行内标注*同源*）。",
  expect: [`auto`（缺省）→ `"bracket"`（`[1]`）。改形时文献表与行内标注一起改——二者必须同源，
    否则读者拿标注找不到条目。`"circled"` 缺省用 Unicode 带圈数字（超过 ㊿ 退化成 `(N)`）；
    字典形 `(circled: "quan")` 改由 `quan` 包*绘制*（引擎是实现不是样式，故不占顶层值）。
    `none` = 不出编号，文献表退化成无编号的悬挂段落（行内标注也无号可标）。
    著者-出版年制下无编号，本参数不参与。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>)
#case("auto（缺省 → bracket）", gb7714.with(), cites: cs, full: false)
#case(`"bracket"`.text, gb7714.with(bib-numbering-style: "bracket"), cites: cs, full: false)
#case(`"paren"`.text, gb7714.with(bib-numbering-style: "paren"), cites: cs, full: false)
#case(`"dot"`.text, gb7714.with(bib-numbering-style: "dot"), cites: cs, full: false)
#case(`"plain"`.text, gb7714.with(bib-numbering-style: "plain"), cites: cs, full: false)
#case(`"fullwidth-bracket"`.text, gb7714.with(bib-numbering-style: "fullwidth-bracket"), cites: cs, full: false)
#case(`"fullwidth-paren"`.text, gb7714.with(bib-numbering-style: "fullwidth-paren"), cites: cs, full: false)
#case(`"shell"`.text, gb7714.with(bib-numbering-style: "shell"), cites: cs, full: false)
#case(`"circled"`.text + "（Unicode 引擎）", gb7714.with(bib-numbering-style: "circled"), cites: cs, full: false)
#case(`(circled: "quan")`.text + "（quan 包绘制引擎）", gb7714.with(bib-numbering-style: (circled: "quan")), cites: cs, full: false)
#case("none（不出编号）", gb7714.with(bib-numbering-style: none), cites: cs, full: false)
#case("著者-出版年制：本参数不参与", gb7714.with(style: "author-date", bib-numbering-style: "paren"), cites: cs, full: false)
