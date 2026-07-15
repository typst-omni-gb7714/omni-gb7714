//! param: show-et-al
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-et-al", controls: "截断时是否显示截断词（等 / et al.）。",
  expect: [`true`（缺省）：截断后补「等 / et al.」。`false`：截断但*不*补截断词（只列前 N 位，戛然而止）。
    `.bib` 里显式写 `and others` 时同样受本参数管。])
#let cs = (<bm-zh>, <bm-en>, <nm-others>)
#case("true（缺省）", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1), bib: EDGE, cites: (<nm-others>,), full: false)
#case("false", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, show-et-al: false), bib: EDGE, cites: (<nm-others>,), full: false)
