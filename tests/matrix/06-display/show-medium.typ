//! param: show-medium
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-medium", controls: "载体标识（`/OL` `/DK` …）的显示。",
  expect: [`true`（缺省）：`[M/OL]`。`false`：只剩类型码 `[M]`——`/` 与载体码一起消失。
    与 `show-mark` 正交（`show-mark: false` 时整个方括号块都不出）。])
#let cs = (<bm-online>, <eb-zh>, <ds-zh>, <bm-zh>)
#case("true（缺省）", gb7714.with(), cites: cs, full: false)
#case("false", gb7714.with(show-medium: false), cites: cs, full: false)
#case("show-mark: false + show-medium: true（方括号整块不出）", gb7714.with(show-mark: false), cites: cs, full: false)
