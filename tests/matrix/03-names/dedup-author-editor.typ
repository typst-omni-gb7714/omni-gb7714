//! param: dedup-author-editor
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "dedup-author-editor", controls: "责任者与编者是同一批人时，是否省略「其他责任者」位的编者。",
  expect: [`false`（缺省）：照常著录两处。`true`：编者与责任者同组人时省略编者位，避免同一批人印两遍。])
#let same = bytes("@book{dup, author={张三 and 李四}, editor={张三 and 李四}, title={作者与编者同人}, address={北京}, publisher={社}, year={2020}, langid={chinese}}")
#case("false（缺省）", gb7714.with(), bib: same, full: true)
#case("true", gb7714.with(dedup-author-editor: true), bib: same, full: true)
