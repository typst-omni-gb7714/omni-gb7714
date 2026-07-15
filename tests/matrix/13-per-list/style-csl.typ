//! param: bibliography(style / version / footnote)
//! values: "numeric", "author-date", 原生 CSL 名, CSL bytes, none
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bibliography(style / version / footnote)", controls: "逐表的样式轴、版本轴、脚注轴。",
  expect: [`style`：`"numeric"` / `"author-date"` 是本包的 GB 实现（原生国标 CSL 名
    `"gb-7714-2015-numeric"` / `"gb-7714-2015-author-date"` *自动映射*到它们）；
    其它原生 CSL 名（`"ieee"` / `"apa"` 等 91 种）或 CSL bytes → *本列表整个交 typst 原生渲染*；
    `none`（缺省）跟随全局。
    `version`：2015 / 2025 / 2005；`auto` 跟随全局；与 `style` 的*国标全名*锁定矛盾时报错（名实一致）。
    `footnote`：`true` 时归属本表的引用走脚注；`auto` 跟随全局 `cite-footnote`
    （链：`cite` 显式 > 本参数 > 全局）。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>)
#case("style: none（跟随全局 numeric）", gb7714.with(), cites: cs, full: false)
#case("style: \"author-date\"（逐表切样式）", gb7714.with(), cites: cs, full: false, bib-args: (style: "author-date"))
#case("style: \"gb-7714-2015-numeric\"（国标 CSL 名 → 自动映射到本包实现）", gb7714.with(), cites: cs, full: false, bib-args: (style: "gb-7714-2015-numeric"))
#case("version: 2015（逐表切版本）", gb7714.with(), cites: cs, full: false, bib-args: (version: 2015))
#case("version: 2005", gb7714.with(), cites: cs, full: false, bib-args: (version: 2005))
#case("全局 2025 + 本表 2015（两表并存时各按各的）", gb7714.with(version: 2025), cites: cs, full: false, bib-args: (version: 2015))
#case("footnote: true（归属本表的引用走脚注）", gb7714.with(), full: false, bib-args: (footnote: true),
  body: [脚注引用 #cite(<bm-zh>) 与 #cite(<bm-en>)。])
