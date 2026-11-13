//! param: prefix-last
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "prefix-last", controls: "西文姓名前缀（van der / de la）全拼前置还是全拼后置——biblatex `useprefix` 的显示半。",
  expect: [真前缀（`.bib` 录为 `van der Berg, Jan`）：`false`（缺省）全拼*前置* `van der Berg J`（李泽平 .bst 各版本现默认、useprefix=true）；
    `true`（≡ useprefix=false）全拼*后置* `Berg J van der`（ISO 690:2021「KARAJAN, H. von」、APA7）——前缀永不缩、后置时保原小写不随姓大写。
    不随版本；版本只改姓的大小写（2015/2005 大写，前置前缀随之大写、后置前缀不随）。
    前缀录进*名*字段（`Veen, P. H. van der`）则跟名一起缩、保原大小写 `Veen P H v d`（GB 示例形态），与本参数无关。
    条目级 `options = {useprefix=..}` 与全局 `sort-use-prefix` 与它联动。])
#let cs = (<nm-prefix>,)
#let CASEA = bytes("@book{a, author={Veen, Pieternella H. van der}, title={Prefix In Given}, address={NY}, publisher={P}, year={2020}, langid={english}}")
#case("false（缺省）· 全拼前置", gb7714.with(prefix-last: false), bib: EDGE, cites: cs, full: false)
#case("true（useprefix=false）· 全拼后置", gb7714.with(prefix-last: true), bib: EDGE, cites: cs, full: false)
#case("2015 · 只改姓大小写、前缀仍前置", gb7714.with(version: 2015), bib: EDGE, cites: cs, full: false)
#case("前缀录进名字段 · Veen, P. H. van der → Veen P H v d", gb7714.with(), bib: CASEA, cites: (<a>,), full: false)
