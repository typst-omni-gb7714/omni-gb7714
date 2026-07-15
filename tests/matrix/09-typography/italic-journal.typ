//! param: italic-journal
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "italic-journal", controls: "期刊名 / 报纸名是否斜体。",
  expect: [`false`（缺省）：正体。`true`：斜体。
    ⚠️ 同 `italic-book-title`：字形差异不进文本 golden。])
#let cs = (<aj-en>, <aj-zh>, <np-zh>)
#case("false（缺省）", gb7714.with(), cites: cs, full: false)
#case("true", gb7714.with(italic-journal: true), cites: cs, full: false)
