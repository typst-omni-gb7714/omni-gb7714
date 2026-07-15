//! param: show-related
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-related", controls: "双语关联条目（`related` + `relatedtype = {lanversion}`）的第二行。",
  expect: [`true`（缺省）：主条目下另起一行渲染被 `related` 指向的第二语言条目。
    `false`：只渲染主条目。第二行*不进*文献表的独立条目位（不占编号、不参与排序、不参与 `creator-idem`）。
    引用的是主条目键。])
#let cs = (<rel-zh>,)
#case("true（缺省）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("false", gb7714.with(show-related: false), bib: EDGE, cites: cs, full: false)
#case("true · 著者-出版年制", gb7714.with(style: "author-date"), bib: EDGE, cites: cs, full: false)
