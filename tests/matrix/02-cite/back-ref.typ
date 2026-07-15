//! param: back-ref
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "back-ref", controls: "文献表条目末尾是否回链到正文引用处（反向引用）。",
  expect: [`true`：每条著录后附回引页码 / 位置，供读者从表跳回正文。`false`（缺省）：不附。])
#case("false（缺省）", gb7714.with(), cites: (<bm-zh>, <bm-en>), full: false)
#case("true", gb7714.with(back-ref: true), cites: (<bm-zh>, <bm-en>), full: false)
