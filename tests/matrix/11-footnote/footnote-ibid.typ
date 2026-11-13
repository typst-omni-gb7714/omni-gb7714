//! param: note-ibid
//! values: auto, true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "note-ibid", controls: "*紧邻*重复（上一条脚注引用就是同一文献）是否简化为「同上(: 页码)」。",
  expect: [`auto`（缺省）*版本感知*：`version: 2015`／`2005` = `true`（紧邻「同上」，对齐 2015 note CSL）；`version: 2025` = `false`（弃用 ibid，对齐 2025 note CSL 与 GB 2025 §9.2.1.3，紧邻退回 `note-repeat-style`）。
    `true`：紧邻「同上(: 页码)」；`false`：紧邻不特殊化，与隔开一样取 `note-repeat-style` 的值（缺省 `"number"` = 「同③」）。
    「紧邻」的判定：*上一条脚注引用*是同一文献即可，中间夹一条普通脚注*不*破坏紧邻关系。
    「同上」的页码语义走 CSL position 算法：与上次同页码时不重复页码；上次有页码本次没有时*降级为隔开*。
    引语词按*被引条目*语言取（中文条目「同上」、西文条目 `Ibid.`）。])
#let ladder = [首 #cite(<bm-zh>) 邻 #cite(<bm-zh>) 换 #cite(<bm-en>) 隔 #cite(<bm-zh>)。]
#let pages = [首 #cite(<bm-zh>, supplement: [10]) 同页 #cite(<bm-zh>, supplement: [10]) 异页 #cite(<bm-zh>, supplement: [20]) 无页 #cite(<bm-zh>)。]
#case("auto · version 2015（→ true，紧邻同上）", gb7714.with(version: 2015, note: "foot"), full: false, body: ladder)
#case("auto · version 2025（→ false，紧邻退回 number = 同③）", gb7714.with(version: 2025, note: "foot"), full: false, body: ladder)
#case("true（紧邻同上，两版通用）", gb7714.with(note: "foot", note-ibid: true), full: false, body: ladder)
#case("false（紧邻退回 note-repeat-style = number = 同③）", gb7714.with(note: "foot", note-ibid: false), full: false, body: ladder)
#case("true · 页码语义（同页不重复、异页带页码、上次有页码本次没有 → 降级为隔开）", gb7714.with(note: "foot", note-ibid: true), full: false, body: pages)
#case("true · 中间夹一条普通脚注（不破坏紧邻）", gb7714.with(note: "foot", note-ibid: true), full: false,
  body: [首 #cite(<bm-zh>) 夹#footnote[一条普通脚注] 邻 #cite(<bm-zh>)。])
#case("true · 西文条目（Ibid.）", gb7714.with(note: "foot", note-ibid: true), full: false,
  body: [首 #cite(<bm-en>) 邻 #cite(<bm-en>) 换 #cite(<bm-zh>) 隔 #cite(<bm-en>)。])
