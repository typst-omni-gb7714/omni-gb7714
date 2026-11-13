//! param: show-no-date
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-no-date", controls: "出版日期不明时是否补占位词（无日期 / n.d.）。",
  expect: [默认 `true`：著者-出版年制缺出版年就补占位词（占*年份位*，无年份构不成「著者-年」标签）。
    *与 `show-anon` 不同，没有制度感知的 `auto`*：本参数只在 AY 语境渲染（AY 文献表责任者后年份位 + AY 标注），
    顺序编码制既无此槽、标签又是数字序号，碰不到它——故默认恒 `true`、无需按制度分档。
    占位词按*条目*语言取，*行内与文献表同源*；消歧后缀用*连字符*（`无日期-a`；有年的仍直接贴 `2020a`）。
    西文的 `n.d.` 缩写点兼作责任者元素后的句点，不叠成 `n.d..`。
    *cite 侧全形态同源*：`default` / `prose` / `year` 三形态缺年都补「无日期」，按条目语言取。])
#let cs = (<lg-noyear-zh>, <lg-noyear-en>, <lg-zh>)
#case("默认 true · 著者-出版年制 → 无日期", gb7714.with(style: "author-date"), bib: LANG, cites: cs, full: false)
#case("false · 著者-出版年制 → 留空", gb7714.with(style: "author-date", show-no-date: false), bib: LANG, cites: cs, full: false)
#case("顺序编码制无此槽：开关都不渲染（缺年占位归 show-sine-anno）", gb7714.with(), bib: LANG, cites: cs, full: false)
#case("form 同源：无年 default / prose / year 都出无日期", gb7714.with(style: "author-date"),
  bib: LANG, full: false, body: [#cite(<lg-noyear-zh>) ／ #cite(<lg-noyear-zh>, form: "prose") ／ #cite(<lg-noyear-zh>, form: "year")])
#case("消歧后缀：同责任者多条无年 → 无日期-a / 无日期-b", gb7714.with(style: "author-date"), bib: EDGE,
  cites: (<nm-noyear-a>, <nm-noyear-b>, <nm-same-a>, <nm-same-b>), full: false)
