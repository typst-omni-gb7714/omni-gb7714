//! param: space-before-annotation
//! values: auto(缺省·按首字符), true, false, 逐表覆写
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "space-before-annotation", controls: "注释（annotation/annote）与前面那个句点之间的空格。",
  expect: [`auto`（缺省）：按注释*首字符*宽窄定——CJK / 全角标点（`（` `【` 等）不加空格，其余加。
    全角标点自带左侧空当，再加半角空格视觉上是一格半：哈工大理工范例全角括号顶着句点排
    （`520-524.（SCI收录…）`）、人文范例半角括号带空格（`32-38. (中文核心)`），两边都要能逐字复刻。
    判据与 `cite-adjacent-space: auto` 的邻字判定同一字符类。`true` / `false` 恒加 / 恒不加。
    仅在 `show-annotation: true` 时有输出可言。])
#let AN = bytes("@article{sa1, author={张三}, title={题目}, journal={学报}, year={2020}, volume={1}, pages={520-524}, annote={（SCI收录，IF=0.16）}, langid={chinese}}
@article{sa2, author={Li, Si}, title={Paper}, journal={J}, year={2021}, volume={2}, pages={32-38}, annote={(中文核心)}, langid={english}}
@article{sa3, author={Wang, Wu}, title={Work}, journal={J}, year={2022}, volume={3}, pages={1-9}, annote={Cited by 12}, langid={english}}
@article{sa4, author={李四}, title={条目}, journal={学报}, year={2023}, volume={4}, pages={7-9}, annote={注记正文直接接排}, langid={chinese}}")
#case("auto（缺省）：全角（ 顶格、半角 ( 与英文带空格、汉字顶格", gb7714.with(show-annotation: true), bib: AN, full: true)
#case("true：恒加（全角括号前也有半角空格）", gb7714.with(show-annotation: true, space-before-annotation: true), bib: AN, full: true)
#case("false：恒不加（英文注记贴上句点）", gb7714.with(show-annotation: true, space-before-annotation: false), bib: AN, full: true)
#case("逐表覆写：全局 auto、本表 true", gb7714.with(show-annotation: true), bib: AN, full: true, bib-args: (space-before-annotation: true))
