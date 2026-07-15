//! combo: 多列表 × 逐表覆盖 × cite(bib-label) × 全局默认 × 隔离编号
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：多列表", controls: "一篇文档多张表时，覆盖链与编号空间怎么走。",
  expect: [*覆盖链*：`cite` 显式 > `bibliography` 逐表 > `gb7714` 全局。
    *编号空间*：匿名主列表全文连续；*命名列表*（`label:`）各自独立、从 `[1]` 起（`number-offset` 恒 0）。
    *归属*：`set-bib-label("x")` 作用域内的引用归 x；`cite(bib-label: "x")` 单次归 x。
    *一份文档只有一套 bib 数据*——`gb7714()` 把全文的 bib 源拼起来*一次*解析，
    所以两份含相同 key 的语料同处一文档会报 `duplicate key`。
    ⚠️ typst 0.15 的原生 `target:` / `group:` 是另一套路由（见 `13-per-list/target-group.typ`）。])
#let two-lists = [
  中文表引用 #cite(<bm-zh>, bib-label: "zh") #cite(<aj-zh>, bib-label: "zh")；
  西文表引用 #cite(<bm-en>, bib-label: "en")。
  #bibliography(MAIN, title: [中文文献（2015 · 顺序编码）], full: false, label: "zh", version: 2015)
  #bibliography(MAIN, title: [西文文献（2025 · 著者-出版年）], full: false, label: "en", style: "author-date")
]
#let scoped = [
  #[#set-bib-label("s1")
    第一节的引用 #cite(<bm-zh>) #cite(<aj-zh>)]
  #bibliography(MAIN, title: [第一节], full: false, label: "s1", numbering-style: "paren")
  #[#set-bib-label("s2")
    第二节的引用 #cite(<bm-en>)]
  #bibliography(MAIN, title: [第二节], full: false, label: "s2", numbering-style: "circled")
]
#case("两张命名列表：各自的 version / style / 编号空间", gb7714.with(), full: false, own-bib: false, body: two-lists)
#case("set-bib-label 分节 + 逐表 numbering-style", gb7714.with(), full: false, own-bib: false, body: scoped)
#case("三级覆盖链：全局 numeric → 本表 author-date → 本次 cite(style: numeric)", gb7714.with(), full: false, own-bib: false, body: [
  本表 author-date，本次引用强制 numeric：#cite(<bm-zh>, bib-label: "c3", style: "numeric")；
  同表另一次引用跟本表：#cite(<aj-zh>, bib-label: "c3")。
  #bibliography(MAIN, title: none, full: false, label: "c3", style: "author-date")])
