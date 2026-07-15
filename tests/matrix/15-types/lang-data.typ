//! param: 多语种数据（lang.bib 全表）
//! values: zh ja ko ru fr de en × 缺 langid × 中西混排
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "多语种全表", controls: "`lang.bib` 整表——六语种 + 缺 `langid` + 中西混排 + 中文排序四条。",
  expect: [条目语言决定：本地化词（等 / et al. / 编 / 译 / 佚名 / 无日期 / 出版地不详）、
    `by-entry-*` 标点档的全 / 半角、多语言字典 `-separator` 的取值、文种分组的落位。
    缺 `langid` 的条目按 `entry-lang-detect` 判定。
    著者-出版年制下按 `entry-lang-order` 先分文种、组内再按责任者字顺（中文按 `bib-sort-zh-by`）。])
#case("2025 · 顺序编码制（缺省）", gb7714.with(), bib: LANG, full: true)
#case("2025 · 著者-出版年制（文种分组 + 组内字顺）", gb7714.with(style: "author-date"), bib: LANG, full: true)
#case("by-entry-with-space（各条目按自身语言定标点）", gb7714.with(bib-punct-style: "by-entry-with-space"), bib: LANG, full: true)
#case("占位词全开（佚名 / 无日期 按条目语言取词）", gb7714.with(style: "author-date", show-anon: true, show-no-date: true), bib: LANG, full: true)
