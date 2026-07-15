//! param: full
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "full", controls: "文献表是否收录未被引用的条目。",
  expect: [`false`（缺省）只著录被引用的；`true` 收录语料里的全部条目（未引用的按 bib 文件序追加在已引用的之后）。])
#case("false（缺省）· 只引两条", gb7714.with(), cites: (<bm-zh>, <bm-en>), full: false)
#case("true · 全表", gb7714.with(), cites: (<bm-zh>, <bm-en>), full: true)
