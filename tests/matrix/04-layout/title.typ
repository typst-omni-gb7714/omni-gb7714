//! param: title
//! values: auto, none, content
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "title", controls: "文献表标题。",
  expect: [`auto`（缺省）：按文档语言取「参考文献 / References」，用 `heading` 渲染（进目次）。
    `none`：不出标题。传 `content`：原样用作标题。逐表可用 `bibliography(title: ..)` 覆盖。
    *矩阵的其余用例一律传 `title: none`*，这里是唯一看标题的地方。])
#let cs = (<bm-zh>,)
#case("auto（缺省，中文文档 → 「参考文献」）", gb7714.with(), cites: cs, full: false, title: auto)
#case("none", gb7714.with(), cites: cs, full: false, title: none)
#case("content：[参 考 书 目]", gb7714.with(), cites: cs, full: false, title: [参 考 书 目])
#case("content：带层级的 heading", gb7714.with(), cites: cs, full: false, title: heading(level: 2, "引用文献"))
