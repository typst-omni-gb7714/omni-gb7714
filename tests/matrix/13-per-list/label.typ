//! param: bibliography(label) + set-bib-label + cite(bib-label)
//! values: none, 字符串（命名列表）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bibliography(label)", controls: "命名列表：把引用归属到指定的那张表（0.14 也能用的多列表方案）。",
  expect: [`none`（缺省）：匿名主列表。
    传字符串：本表成为*命名列表*，配合 `set-bib-label("x")`（作用域内的引用都归属 x）
    或 `cite(bib-label: "x")`（单次归属）把引用绑到它。
    *也用于隔离子列表*：给一个（哪怕没有 cite 归属的）label，本表即*独立编号、从 `[1]` 起*
    （命名列表的 `number-offset` 恒 0）。
    ⚠️ 矩阵的 probe 正是靠它把每个区块的编号隔离开——否则同一文档里多张匿名表共享编号空间，
    第二块起的编号会接着往上加，正文标注与表内编号对不上。])
#let two = [
  甲区（归属列表 A）：#cite(<bm-zh>, bib-label: "la") #cite(<aj-zh>, bib-label: "la")
  乙区（归属列表 B）：#cite(<bm-en>, bib-label: "lb")
  #bibliography(MAIN, title: [列表 A], full: false, label: "la")
  #bibliography(MAIN, title: [列表 B], full: false, label: "lb")
]
#let scoped = [
  #[#set-bib-label("sc")
    作用域内的引用自动归属 sc：#cite(<bm-zh>) #cite(<aj-zh>)]
  #bibliography(MAIN, title: [列表 sc], full: false, label: "sc")
]
#case("两张命名列表各自编号（cite(bib-label:) 逐次归属）", gb7714.with(), full: false, own-bib: false, body: two)
#case("set-bib-label 作用域归属", gb7714.with(), full: false, own-bib: false, body: scoped)
#case("隔离子列表：给 label 但无 cite 归属 → 独立从 [1] 起", gb7714.with(), full: false, own-bib: false,
  body: [#bibliography(MAIN, title: none, full: true, label: "iso", entry-type: "thesis")])
