//! param: show-no-date
//! values: auto, true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-no-date", controls: "出版日期不明时是否补占位词（无日期 / n.d.）。",
  expect: [与 `show-anon` *逐字同构*：`auto`（缺省）= 著者-出版年制显示占位词（无年份就构不成
    「著者-年」标签）、顺序编码制留空。官方 GB CSL 两制实测就是这样。占位词占*年份位*，按条目语言取，
    *行内与文献表同源*。消歧后缀用*连字符*（`无日期-a`，官方 GB CSL 里显式的 `<group delimiter="-">`）；
    有年的仍直接贴（`2020a`）。西文的 `n.d.` 缩写点兼作责任者元素后的句点，不叠成 `n.d..`。])
#let cs = (<lg-noyear-zh>, <lg-noyear-en>, <lg-zh>)
#case("auto · 著者-出版年制（→ true）", gb7714.with(style: "author-date"), bib: LANG, cites: cs, full: false)
#case("auto · 顺序编码制（→ false）", gb7714.with(), bib: LANG, cites: cs, full: false)
#case("true · 顺序编码制", gb7714.with(show-no-date: true), bib: LANG, cites: cs, full: false)
#case("false · 著者-出版年制", gb7714.with(style: "author-date", show-no-date: false), bib: LANG, cites: cs, full: false)
#case("消歧后缀：同责任者多条无年 → 无日期-a / 无日期-b", gb7714.with(style: "author-date"), bib: EDGE,
  cites: (<nm-noyear-a>, <nm-noyear-b>, <nm-same-a>, <nm-same-b>), full: false)
