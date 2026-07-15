//! param: bib-name-date-separator
//! values: auto, string, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-name-date-separator", controls: "文献表里责任者与出版年之间的分隔符（著者-出版年制）。",
  expect: [`auto` 随版本：2005 用句点、2015 / 2025 用逗号，都做全 / 半角感知。
    显式字符串走三态；也收多语言字典（按条目语言挑值，未点到的退回 `auto` 档派生值）。])
#let cs = (<bm-zh>, <bm-en>)
#case("auto · 2025（缺省）", gb7714.with(style: "author-date"), cites: cs, full: false)
#case("auto · 2005（句点）", gb7714.with(style: "author-date", version: 2005), cites: cs, full: false)
#case(`","`.text, gb7714.with(style: "author-date", bib-name-date-separator: ","), cites: cs, full: false)
#case(`" "`.text, gb7714.with(style: "author-date", bib-name-date-separator: " "), cites: cs, full: false)
#case("{ — }（verbatim）", gb7714.with(style: "author-date", bib-name-date-separator: "{ — }"), cites: cs, full: false)
#case("多语言字典 (zh: 「，」, rest: 「, 」)", gb7714.with(style: "author-date", bib-name-date-separator: (zh: "，", rest: ", ")), cites: cs, full: false)
