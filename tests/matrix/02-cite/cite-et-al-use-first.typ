//! param: cite-et-al-use-first
//! values: 0, 1, 2, 3
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-et-al-use-first", controls: "标注截断后保留前 N 位责任者。",
  expect: [缺省 `1`。`0` 是合法值——只出截断词、不留孤儿分隔符（官方 GB CSL 设 `et-al-use-first="0"`
    实测输出裸「等」）。设的位数 ≥ 责任者数时等同不截断。])
#let cs = (<bm-zh>, <bm-en>)
#cite-only("0（只出截断词）", gb7714.with(style: "author-date", cite-et-al-min: 2, cite-et-al-use-first: 0), cites: cs)
#cite-only("1（缺省）", gb7714.with(style: "author-date", cite-et-al-min: 2, cite-et-al-use-first: 1), cites: cs)
#cite-only("2", gb7714.with(style: "author-date", cite-et-al-min: 2, cite-et-al-use-first: 2), cites: cs)
#cite-only("3", gb7714.with(style: "author-date", cite-et-al-min: 2, cite-et-al-use-first: 3), cites: cs)
