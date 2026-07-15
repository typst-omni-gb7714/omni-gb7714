//! param: period-after-creator
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "period-after-creator", controls: "*责任者元素*之后是否加句点。",
  expect: [`true`（缺省）加 `.`，`false` 改用空格。*两制同构*——句点落在责任者元素之后，而著者-出版年制的
    责任者元素是「责任者，出版年」*整块*（`ZUO Z, 2020. Titlex` → `ZUO Z, 2020 Titlex`）。
    责任者与年份之间那个逗号不归本参数管（那是 `bib-name-date-separator`）。
    对应 biblatex 的 `\labelnamepunct`——胡振震样式实测改成 `\addspace` 得「ZHEN Z, 2020 Titlex[M].」。])
#let cs = (<bm-zh>, <bm-en>)
#case("true（缺省）· 顺序编码制", gb7714.with(), cites: cs, full: false)
#case("false · 顺序编码制", gb7714.with(period-after-creator: false), cites: cs, full: false)
#case("true（缺省）· 著者-出版年制", gb7714.with(style: "author-date"), cites: cs, full: false)
#case("false · 著者-出版年制", gb7714.with(style: "author-date", period-after-creator: false), cites: cs, full: false)
