//! combo: et-al 阈值三参 × show-et-al × custom-terms(et-al) × cite-terms-lang × 两轴分离
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：截断词一家子", controls: "「等 / et al.」牵动阈值、保留数、开关、词形、语言五处，且分*两轴*。",
  expect: [*两轴分离*：`bib-et-al-*` 管文献表、`cite-et-al-*` 管正文标注——两轴各自独立。
    - `*-et-al-min`：责任者数*达到*此值就截断（缺省 4 = 文献表、2 = 标注；GB §7.1.2「≤3 全录，>3 录前 3」；语义与 CSL 的 `et-al-min` 逐字同义，数值照搬不必换算）；
    - `*-et-al-use-first`：截断后保留前 N 位（缺省 3；`0` 是合法值，只出截断词、*不留孤儿分隔符*——
      官方 GB CSL 设 `et-al-use-first="0"` 实测输出裸「等」）；
    - `show-et-al`：截断时出不出截断词（`false` = 截断但不补词）；
    - `custom-terms: (et-al: ..)`：改词形（`(en: "et al")` 去掉尾点）；
    - `cite-terms-lang`：只动*标注侧*的取词语言（著录侧硬性跟条目语言）。
    GB §9.3.1.2 明文：「欧美第一责任者姓 + et al.，中国第一责任者姓名 + 等」——按*著者*语种。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>, <aj-en>)
#let one(name, cfg) = cite-only(name, cfg, cites: cs)
#case("缺省（bib 侧：4 位 > 3 → 录前 3 加「等」）", gb7714.with(), cites: cs, full: false)
#case("bib-et-al-min: 999（文献表不截断）· cite 侧仍截断", gb7714.with(style: "author-date", bib-et-al-min: 999), cites: cs, full: false)
#case("cite-et-al-min: 999（标注不截断）· bib 侧仍截断", gb7714.with(style: "author-date", cite-et-al-min: 999), cites: cs, full: false)
#case("两轴都关", gb7714.with(style: "author-date", bib-et-al-min: 999, cite-et-al-min: 999), cites: cs, full: false)
#case("et-al-use-first: 0（只出截断词，无孤儿分隔符）", gb7714.with(bib-et-al-min: 2, bib-et-al-use-first: 0), cites: cs, full: false)
#case("show-et-al: false（截断但不补词）", gb7714.with(bib-et-al-min: 2, bib-et-al-use-first: 1, show-et-al: false), cites: cs, full: false)
#case("custom-terms: (et-al: (en: \"et al\"))（去尾点）", gb7714.with(custom-terms: (et-al: (en: "et al"))), cites: cs, full: false)
#case("cite-terms-lang: \"zh\"（标注侧一律「等」，著录侧不动）", gb7714.with(style: "author-date", cite-terms-lang: "zh"), cites: cs, full: false)
#case("cite-terms-lang: (et-al: \"by-doc\")（只让截断词跟文档语言）", gb7714.with(style: "author-date", cite-terms-lang: (et-al: "by-doc")), cites: cs, full: false)
#case("et-al-use-first: 0 + 其他责任者（编者 / 译者的角色词接缝）", gb7714.with(bib-et-al-min: 2, bib-et-al-use-first: 0),
  bib: EDGE, cites: (<nm-others>, <nm-editor-only>, <nm-translator>), full: false)
