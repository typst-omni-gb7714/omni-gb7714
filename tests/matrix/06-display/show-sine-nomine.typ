//! param: show-sine-nomine
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-sine-nomine", controls: "缺出版者时是否补「[s.n.] / 出版者不详」占位。",
  expect: [`false`（缺省）：留空。`true`：补占位（GB/T 7714 严格著录）。占位词按*条目语言*取。
    与 `show-sine-loco` 正交：只缺出版者时补出版者位，出版地照旧。])
#let cs = (<im-nopub>, <im-noloc>, <im-placeholder>)
#case("false（缺省）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("true（只补出版者）", gb7714.with(show-sine-nomine: true), bib: EDGE, cites: cs, full: false)
#case("true · 西文条目（[s.n.]）", gb7714.with(show-sine-nomine: true), bib: bytes("@book{en-nopub2, author={Smith, John}, title={No Publisher}, address={NY}, year={2020}, langid={english}}"), full: true)
