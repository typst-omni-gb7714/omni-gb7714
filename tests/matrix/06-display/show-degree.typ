//! param: show-degree
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-degree", controls: "学位论文是否在 `[D]` 后附学位级别注记（只对标识为 D 的条目生效）。",
  expect: [`false`（缺省）：不附，`@thesis` / `@mastersthesis` / `@phdthesis` 著录相同。
    `true`：`[D]` 后插入学位级别，按*条目语言*取词——
    硕士（`@mastersthesis` 或 `@thesis` + `type = {mathesis}`）：硕士学位论文 / MA thesis；
    博士（`@phdthesis` 或 `type = {phdthesis}`）：博士学位论文 / PhD thesis。
    *裸 `@thesis` 无 `type` 字段：不附加*（无从判级）。])
#let th = bytes("@thesis{t-phd, author={郑三}, title={博士论文}, type={phdthesis}, institution={示例大学}, address={武汉}, year={2019}, langid={chinese}}
@mastersthesis{t-ma, author={王四}, title={硕士论文}, institution={示例大学}, address={武汉}, year={2020}, langid={chinese}}
@thesis{t-bare, author={李五}, title={裸 thesis 无 type}, institution={示例大学}, address={武汉}, year={2021}, langid={chinese}}
@phdthesis{t-en, author={Smith, John}, title={English PhD}, institution={Example University}, address={NY}, year={2022}, langid={english}}")
#case("false（缺省）", gb7714.with(), bib: th, full: true)
#case("true", gb7714.with(show-degree: true), bib: th, full: true)
