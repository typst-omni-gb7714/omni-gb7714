//! param: show-mark 字典里的 auto 档（逐类型 / 码触发单块退化）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-mark 字典 auto", controls: "`show-mark` 字典的值除 `true` / `false` 外还可写 `auto`——命中该键的条目按*单块退化*显码（单块去码、多块显码），是「顶层 `show-mark: auto`」的逐类型 / 码版。任意键（小写 `entry_type` / 大写标识码 / `rest`）都能写 `auto`，逐条目 resolve。",
  expect: [`applied-value` 把字典按「`entry_type` > 码 > `rest`」解析到本条目的值；dispatch 判该值是否 `auto` 决定单块退化，`gate` 再把 `auto` 落成显码（多块）。

    - *`(S: auto, rest: true)`*:标准 `S` 按单块退化(多块 `标准多块[S].` 显码、单块 `标准单块` 去码);其余类型 `rest: true` 恒显码(`图书单块[M]` 单块也显)。
    - *`(S: false, rest: auto)`*:标准 `S` 恒不显码(多块单块都无 `[S]`);其余 `rest: auto` 按单块退化(`图书单块` 去码、`图书多块[M]` 显码)。
    - 现有 `bool` / `不含 auto 的字典` / 顶层 `auto` 行为不受影响,只新增「字典里写 `auto`」这一档。])

#let eb = bytes("@standard{sm, author={局}, number={GB/T 1---2020}, title={标准多块}, date={2020}, langid={chinese}}
@standard{ss, title={标准单块}, langid={chinese}}
@book{bs, title={图书单块}, langid={chinese}}
@book{bm, author={张三}, title={图书多块}, location={北京}, publisher={社}, date={2020}, langid={chinese}}")

#case("(S: auto, rest: true)：标准逐条目单块退化、其余恒显码", gb7714.with(version: 2025, show-mark: (S: auto, rest: true)), bib: eb, cites: (<sm>, <ss>, <bs>, <bm>), full: true)
#case("(S: false, rest: auto)：标准恒不显码、其余逐条目单块退化", gb7714.with(version: 2025, show-mark: (S: false, rest: auto)), bib: eb, cites: (<sm>, <ss>, <bs>, <bm>), full: true)
