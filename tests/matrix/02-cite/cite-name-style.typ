//! param: cite-name-style
//! values: auto, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-name-style", controls: "标注里西文姓名的格式（八维字典）。",
  expect: [`auto` 缺省：著者-出版年制标注只出*姓*（family）。字典可逐维覆盖——
    `order`（姓前 / 名前，也可 `(first:, rest:)` 分设第一责任者与其余）、`family-case`、
    `given-form`（缩写 / 全名 / 只姓）、`given-separator`、`given-case`、`given-initial-separator`（缩写点）、
    `family-given-separator`、`given-family-separator`（两个接缝）。])
#let cs = (<nm-prefix>, <nm-suffix>, <nm-hyphen>)
#case("auto（缺省，只出姓）", gb7714.with(style: "author-date", cite-et-al-min: 999), bib: EDGE, cites: (<nm-prefix>, <nm-suffix>), full: false)
#cite-only("given-form: initials（补名的首字母）", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (given-form: "initials")), bib: EDGE, cites: cs)
#cite-only("given-form: full（全名）", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (given-form: "full")), bib: EDGE, cites: cs)
#cite-only("order: given-ahead（名前姓后）", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (order: "given-ahead", given-form: "full")), bib: EDGE, cites: cs)
#cite-only("order 字典 (first: family-ahead, rest: given-ahead)", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (order: (first: "family-ahead", rest: "given-ahead"), given-form: "full")), bib: EDGE, cites: cs)
#cite-only("family-case: uppercase", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (family-case: "uppercase")), bib: EDGE, cites: cs)
#cite-only("family-case: lowercase", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (family-case: "lowercase")), bib: EDGE, cites: cs)
#cite-only("given-initial-separator: 「.」（缩写点）", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (given-form: "initials", given-initial-separator: ".")), bib: EDGE, cites: cs)
#cite-only("given-separator + given-case", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (given-form: "full", given-separator: "-", given-case: "uppercase")), bib: EDGE, cites: cs)
#cite-only("family-given-separator + given-family-separator", gb7714.with(style: "author-date", cite-et-al-min: 999, cite-name-style: (given-form: "full", family-given-separator: "、", given-family-separator: "‧")), bib: EDGE, cites: cs)
