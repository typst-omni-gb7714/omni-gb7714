//! param: prefix-last
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "prefix-last", controls: "西文姓名的前缀（van / de la）排在姓之前还是之后。",
  expect: [控制 `van der Berg` 著录成「Berg J V D」还是「van der Berg J」。
    2025 缺省与 2015 缺省不同——版本感知。条目级 `options = {useprefix=true}` 与全局 `sort-use-prefix` 与它联动。])
#let cs = (<nm-prefix>,)
#case("2025 缺省", gb7714.with(version: 2025), bib: EDGE, cites: cs, full: false)
#case("2015 缺省", gb7714.with(version: 2015), bib: EDGE, cites: cs, full: false)
#case("true", gb7714.with(prefix-last: true), bib: EDGE, cites: cs, full: false)
#case("false", gb7714.with(prefix-last: false), bib: EDGE, cites: cs, full: false)
