//! param: biblatex 名字表字段（namea / nameatype）· 条目级 options
//! values: namea→editora 改写 · options={use-prefix=true}
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "namea / nameatype · options", controls: "载入期对 biblatex 名字字段的改写，与条目级开关。",
  expect: [*`namea` / `nameatype`*：biblatex 的自定义名字表。底层解析器*只把* `editora` / `editorb` /
    `editorc` 系列解析进姓名结构，`namea` 不解析——于是以 `namea`（collaborator）承载编制者作*主要责任者*
    的条目（地图，better.bib 约定）会*丢掉责任者*。
    载入期把字段名 `namea` 改写成 `editora`、`nameatype` 改写成 `editoratype`（只匹配字段声明位），把责任者救回来。
    *条目级 `options`*：`use-prefix=true` 让该条的西文姓名前缀计入排序与标注，*优先于*全局 `sort-use-prefix`。])
#case("namea 承载的编制者（不丢责任者）", gb7714.with(), bib: PARSE, full: true, bib-args: (keys: [@pa-namea]))
#case("namea · 著者-出版年制（标签也拿得到责任者）", gb7714.with(style: "author-date"), bib: PARSE, full: true, bib-args: (keys: [@pa-namea]))
#case("条目级 options: use-prefix=true（全局 false）", gb7714.with(style: "author-date", sort-use-prefix: false),
  bib: PARSE, full: true, bib-args: (keys: [@pa-options@pa-sortkey]))
#case("条目级 options 与全局 true 同向", gb7714.with(style: "author-date", sort-use-prefix: true),
  bib: PARSE, full: true, bib-args: (keys: [@pa-options@pa-sortkey]))
