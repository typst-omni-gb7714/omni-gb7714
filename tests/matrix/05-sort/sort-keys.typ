//! param: sort-keys
//! values: none, content
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "sort-keys", controls: "手工置顶：内容块里用 `@key` 点名的条目按书写序排在最前，其余照常追加。",
  expect: [`none`（缺省）按样式排序。传内容块则点名的条目优先，其余条目按当前排序方案接在后面
    （未引用条目的追加方式同 `full`）。两制都生效——顺序编码制下被置顶的条目拿到 `[1]`。])
#case("none（缺省）", gb7714.with(), cites: (<bm-zh>, <aj-zh>, <st-zh>), full: false)
#case("[@st-zh]（置顶一条）", gb7714.with(sort-keys: [@st-zh]), cites: (<bm-zh>, <aj-zh>, <st-zh>), full: false)
#case("[@st-zh@aj-zh]（依次置顶两条）", gb7714.with(sort-keys: [@st-zh@aj-zh]), cites: (<bm-zh>, <aj-zh>, <st-zh>), full: false)
#case("著者-出版年制 · [@aj-en]", gb7714.with(style: "author-date", sort-keys: [@aj-en]), cites: (<bm-zh>, <aj-zh>, <aj-en>), full: false)
