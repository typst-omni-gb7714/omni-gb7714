//! param: bib-name-style
//! values: auto, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-name-style", controls: "文献表里西文姓名的格式（八维字典）。",
  expect: [`auto` 缺省：GB 形态——姓全著、首字母大写，名缩写为首字母且不加缩写点（§7.1）。
    八维可逐维覆盖，语义同 `cite-name-style`。条目级 `nameformat` 字段优先于本参数（混合语料逐条标）。])
#let cs = (<nm-prefix>, <nm-suffix>, <nm-hyphen>, <nm-nameformat>)
#case("auto（缺省）", gb7714.with(bib-et-al-min: 999), bib: EDGE, cites: cs, full: false)
#case("given-form: full", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "full")), bib: EDGE, cites: cs, full: false)
#case("given-form: none（只姓）", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: none)), bib: EDGE, cites: cs, full: false)
#case("order: given-ahead", gb7714.with(bib-et-al-min: 999, bib-name-style: (order: "given-ahead", given-form: "full")), bib: EDGE, cites: cs, full: false)
#case("order 字典 (first:, rest:)", gb7714.with(bib-et-al-min: 999, bib-name-style: (order: (first: "family-ahead", rest: "given-ahead"), given-form: "full")), bib: EDGE, cites: cs, full: false)
#case("family-case: uppercase / lowercase / none", gb7714.with(bib-et-al-min: 999, bib-name-style: (family-case: "lowercase")), bib: EDGE, cites: cs, full: false)
#case("given-initial-separator: 「.」", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "initials", given-initial-separator: ".")), bib: EDGE, cites: cs, full: false)
#case("given-separator + given-case", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "full", given-separator: "-", given-case: "capitalize-first")), bib: EDGE, cites: cs, full: false)
#case("family-given-separator + given-family-separator", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "full", family-given-separator: "、", given-family-separator: "‧")), bib: EDGE, cites: cs, full: false)
