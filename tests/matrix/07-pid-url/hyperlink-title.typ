//! param: hyperlink-title
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "hyperlink-title", controls: "条目题名是否渲染成可点击超链接。",
  expect: [`false`（缺省）：题名是纯文本。`true`：题名链到 `url` / `doi`（需有其一，否则仍是纯文本）。
    ⚠️ 同 `hyperlink`：超链接在 PDF 注解层，抽出来的文本相同——两档 golden 一致。])
#let cs = (<bm-online>, <bm-zh>)
#case("false（缺省）", gb7714.with(), cites: cs, full: false)
#case("true", gb7714.with(hyperlink-title: true), cites: cs, full: false)
#case("true + hyperlink: false（题名链仍在，路径文本不可点）", gb7714.with(hyperlink-title: true, hyperlink: false), cites: cs, full: false)
