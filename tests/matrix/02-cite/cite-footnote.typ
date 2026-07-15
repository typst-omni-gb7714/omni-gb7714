//! param: cite-footnote
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-footnote", controls: "引用是否走脚注制（完整著录落在脚注里，正文只留注号）。",
  expect: [`true`：正文出圈码注号，脚注里给出完整著录；首次全著录，紧邻重复「同上」，隔开重复「同③」
    （官方 note CSL 的梯子）。相邻引用合成*一个*脚注。`false`（缺省）：常规行内标注。
    脚注里的引语词（同上 / Ibid.）按*被引条目*语言取。])
#case("false（缺省）", gb7714.with(), cites: (<bm-zh>, <bm-en>), full: false)
#case("true · 首次 + 紧邻重复 + 隔开重复", gb7714.with(cite-footnote: true), full: false,
  body: [首 #cite(<bm-zh>) 邻 #cite(<bm-zh>) 换 #cite(<bm-en>) 隔 #cite(<bm-zh>)。])
#case("true · 相邻引用合成一个脚注", gb7714.with(cite-footnote: true), full: false,
  body: [合注 #cite(<bm-zh>)#cite(<bm-en>)。])
#case("true · 西文条目的引语词（Ibid. / See note）", gb7714.with(cite-footnote: true), full: false,
  body: [首 #cite(<bm-en>) 邻 #cite(<bm-en>) 换 #cite(<bm-zh>) 隔 #cite(<bm-en>)。])
