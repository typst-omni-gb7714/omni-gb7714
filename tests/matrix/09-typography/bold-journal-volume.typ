//! param: bold-journal-volume
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bold-journal-volume", controls: "期刊卷号是否加粗。",
  expect: [`false`（缺省）：正常字重。`true`：卷号加粗。
    ⚠️ 字重不进文本 golden，两档相同。])
#let cs = (<aj-en>, <aj-zh>)
#case("false（缺省）", gb7714.with(), cites: cs, full: false)
#case("true", gb7714.with(bold-journal-volume: true), cites: cs, full: false)
#case("true + italic-journal: true", gb7714.with(bold-journal-volume: true, italic-journal: true), cites: cs, full: false)
