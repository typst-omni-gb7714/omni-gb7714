//! param: show-series
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-series", controls: "是否著录丛书项（`series` 字段）。",
  expect: [`false`（缺省）：不著录——GB/T 7714—2015 / 2025 的著录格式*不含*丛书项（只有 2005 版有）。
    `true`：在出版项后以「(丛书名)」或「(丛书名, 丛书号)」著录（`number` 未被类型标识占用时附丛书号）。
    *只对专著与析出文献生效*：标准 S、学位论文 D、报告 R、专利 P、报纸 N、期刊 J 等
    `number` 另有用途的类型不输出。])
#let cs = (<ti-series>,)
#case("false（缺省）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("true", gb7714.with(show-series: true), bib: EDGE, cites: cs, full: false)
#case("true · version: 2005（旧式丛书著录的原生地）", gb7714.with(show-series: true, version: 2005), bib: EDGE, cites: cs, full: false)
#case("true · number 另有用途的类型（标准 / 报告：不输出丛书号）", gb7714.with(show-series: true), cites: (<st-zh>, <rp-zh>), full: false)
