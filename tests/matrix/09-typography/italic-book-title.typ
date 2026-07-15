//! param: italic-book-title
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "italic-book-title", controls: "西文专著 / 论文集题名（非析出）是否斜体。",
  expect: [`false`（缺省）：正体。`true`：斜体。只作用于*西文*的专著类题名（析出文献的析出题名不斜）。
    ⚠️ 斜体是字形，pdftotext 抽出来的*文本一模一样*——两档 golden 相同，差异要开 PDF 看。
    字形差异由 `parity/` 的复刻对拍与人工审 PDF 兜底。])
#let cs = (<bm-en>, <bm-zh>, <aj-en>, <ic-zh>)
#case("false（缺省）", gb7714.with(), cites: cs, full: false)
#case("true", gb7714.with(italic-book-title: true), cites: cs, full: false)
#case("true + italic-journal: true（两轴同开）", gb7714.with(italic-book-title: true, italic-journal: true), cites: cs, full: false)
