//! param: space-before-pages
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "space-before-pages", controls: "页码冒号之后是否留空格。",
  expect: [`true`（缺省）：`: 123`。`false`：`:123`。
    与 `bib-punct-style` 的尾空格档正交——本参数只管*页码位*那个冒号后面的空格。
    全角档（`full`）下冒号本身是 `：`（自带宽度），空格仍按本参数加。])
#let cs = (<bm-zh>, <aj-zh>, <aj-en>)
#case("true（缺省）· 2025 full 档", gb7714.with(), cites: cs, full: false)
#case("false · 2025 full 档", gb7714.with(space-before-pages: false), cites: cs, full: false)
#case("true · 2015 half-with-space 档", gb7714.with(version: 2015), cites: cs, full: false)
#case("false · 2015 half-with-space 档", gb7714.with(version: 2015, space-before-pages: false), cites: cs, full: false)
#case("false · half 档（无尾空格）", gb7714.with(bib-punct-style: "half", space-before-pages: false), cites: cs, full: false)
