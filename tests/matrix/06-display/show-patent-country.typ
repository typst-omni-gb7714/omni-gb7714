//! param: show-patent-country
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-patent-country", controls: "专利条目是否著录专利国。",
  expect: [`false`（缺省）：不出。`true`：专利条目显示专利国（取 `address` / `location` 字段）。
    只对专利（`[P]`）生效，其他类型的 `address` 照常当出版地用。])
#let pt = bytes("@patent{p-cn, holder={某公司}, author={褚五}, title={一种示例装置}, number={CN12345678A}, address={中国}, year={2022}, date={2022-05-01}, langid={chinese}}")
#case("false（缺省）", gb7714.with(), bib: pt, full: true)
#case("true", gb7714.with(show-patent-country: true), bib: pt, full: true)
#case("true · 语料专利无 address 字段（无可著录，不留空槽）", gb7714.with(show-patent-country: true), cites: (<pt-zh>,), full: false)
