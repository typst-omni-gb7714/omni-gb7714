//! param: cite-completion
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-completion", controls: "是否接管 `@key` 的补全提示（编辑器体验，不影响渲染）。",
  expect: [两个取值的*渲染结果应当完全相同*——它只影响编辑器补全，不参与著录与标注。
    本用例存在的意义就是把这条契约冻结：若两块出现差异，说明它意外地影响了渲染。])
#case("true（缺省）", gb7714.with(), cites: (<bm-zh>,), full: false)
#case("false", gb7714.with(cite-completion: false), cites: (<bm-zh>,), full: false)
