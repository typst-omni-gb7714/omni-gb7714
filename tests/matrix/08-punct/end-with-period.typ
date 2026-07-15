//! param: end-with-period
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "end-with-period", controls: "条目末尾是否自动补句号。",
  expect: [`true`（缺省）：条目不以缩写点结尾时补 `.`。`false`：不补。
    *不叠句点*：已以缩写点收尾（`n.d.` / `et al.` / `3rd ed.`）的条目不会得到 `..`。
    与 `show-annotation` 联动：开注释时句点接在注释之后。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>)
#case("true（缺省）", gb7714.with(), cites: cs, full: false)
#case("false", gb7714.with(end-with-period: false), cites: cs, full: false)
#case("true · 条目以缩写点收尾（不叠成 ..）", gb7714.with(show-no-date: true), bib: LANG, cites: (<lg-noyear-en>, <lg-noyear-zh>), full: false)
#case("true + show-annotation（句点接在注释后）", gb7714.with(show-annotation: true), bib: EDGE, cites: (<an-a>,), full: false)
#case("false + show-annotation", gb7714.with(show-annotation: true, end-with-period: false), bib: EDGE, cites: (<an-a>,), full: false)
