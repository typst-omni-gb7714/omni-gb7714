//! param: number-gutter
//! values: length
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "number-gutter", controls: "编号列与正文之间的间距。",
  expect: [缺省 `0.65em`。`number-placement: "column"` 下正文左边界 = `number-width` + 本参数；
    `"inline"` 下退化成编号与正文之间的一个水平间距。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>)
#case("0.65em（缺省）", gb7714.with(), cites: cs, full: false)
#case("0pt", gb7714.with(number-gutter: 0pt), cites: cs, full: false)
#case("2em", gb7714.with(number-gutter: 2em), cites: cs, full: false)
#case("2em · number-placement: inline", gb7714.with(number-gutter: 2em, number-placement: "inline"), cites: cs, full: false)
