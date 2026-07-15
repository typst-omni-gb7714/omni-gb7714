//! param: entry-spacing
//! values: auto, length
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "entry-spacing", controls: "条目之间的垂直间距。",
  expect: [`auto`（缺省）：跟随文档的段间距（`par.spacing`）。传长度则固定。
    `0pt` = 条目紧贴（只剩行距）。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>)
#case("auto（缺省，跟随 par.spacing）", gb7714.with(), cites: cs, full: false)
#case("0pt", gb7714.with(entry-spacing: 0pt), cites: cs, full: false)
#case("1.2em", gb7714.with(entry-spacing: 1.2em), cites: cs, full: false)
