//! param: bibliography(related-indent)
//! values: auto, length
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bibliography(related-indent)", controls: "双语关联条目第二行的缩进（`bibliography` 独有，全局无同名参数）。",
  expect: [`show-related: true` 时，被 `related` 指向的第二语言条目另起一行；本参数定那一行的左缩进。
    `auto`（缺省）：与条目正文左边界对齐（顺序编码制下即编号列宽 + `number-gutter`）。
    传长度则强制。])
#case("auto（缺省）", gb7714.with(), bib: EDGE, cites: (<rel-zh>,), full: false)
#case("0pt（第二行顶格）", gb7714.with(), bib: EDGE, cites: (<rel-zh>,), full: false, bib-args: (related-indent: 0pt))
#case("4em", gb7714.with(), bib: EDGE, cites: (<rel-zh>,), full: false, bib-args: (related-indent: 4em))
#case("auto · 著者-出版年制", gb7714.with(style: "author-date"), bib: EDGE, cites: (<rel-zh>,), full: false)
