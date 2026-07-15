//! param: bibliography(target / group)
//! values: selector, 分组名
//! typst: 0.15
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bibliography(target / group)", controls: "typst 0.15 的原生引用路由与编号分组。",
  expect: [`target`：原生 cite 路由选择器，如 `selector(std.cite).within(<ch1>)`——把某个范围内的引用
    路由到本表。`group`：原生编号分组，`auto` 全文档连续编号；两表用同一 `group` 名即*跨表连续编号*。
    *两者都需要 typst 0.15+*（0.14 下报「label 不存在」）；本文件由 runner 用 0.15 二进制跑。
    与 `label`（命名列表）是两套并行方案：`label` 在 0.14 也能用，`target` / `group` 是原生路由。])
#let chapters = [
  #[== 甲章
    引用 #cite(<bm-zh>) #cite(<aj-zh>)]<ch1>
  #bibliography(MAIN, title: [甲章参考文献], full: false, target: selector(std.cite).within(<ch1>))
  #[== 乙章
    引用 #cite(<bm-en>)]<ch2>
  #bibliography(MAIN, title: [乙章参考文献], full: false, target: selector(std.cite).within(<ch2>))
]
#let grouped = [
  #[== 甲章
    引用 #cite(<bm-zh>) #cite(<aj-zh>)]<g1>
  #bibliography(MAIN, title: [甲章], full: false, target: selector(std.cite).within(<g1>), group: "all")
  #[== 乙章
    引用 #cite(<bm-en>)]<g2>
  #bibliography(MAIN, title: [乙章], full: false, target: selector(std.cite).within(<g2>), group: "all")
]
#case("target：按章路由（各表独立编号）", gb7714.with(), full: false, own-bib: false, body: chapters)
#case("target + 同一 group：跨表连续编号（乙章从 [3] 起）", gb7714.with(), full: false, own-bib: false, body: grouped)
