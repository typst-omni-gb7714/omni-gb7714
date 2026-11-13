//! param: show-urldate
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-urldate", controls: "引用日期（`urldate` 字段）的显示。",
  expect: [`true`（缺省）：URL 前出「[2024-01-15]」。`false`：不出。
    是否适用仍按当前版本与著录类型判断；`show-url` 不再连带抑制引用日期。])
#let cs = (<bm-online>, <eb-zh>, <ds-zh>)
#case("true（缺省）", gb7714.with(), cites: cs, full: false)
#case("false", gb7714.with(show-urldate: false), cites: cs, full: false)
#case("false + show-url: false（两者都不出）", gb7714.with(show-urldate: false, show-url: false), cites: cs, full: false)
