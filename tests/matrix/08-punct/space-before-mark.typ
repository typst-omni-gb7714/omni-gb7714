//! param: space-before-mark
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "space-before-mark", controls: "文献类型标识 `[M]` 之前是否留一个空格。",
  expect: [`false`（缺省）：题名紧接 `[M]`。`true`：题名与 `[M]` 之间留空格。
    ⚠️ *只作用于 `mark-medium` 这个封装 token*（内置八驱动用的就是它）；
    `custom-drivers` 里的*裸* `mark` / `medium` token *不受它管*——裸化模板里标识前的空格由模板自己写。])
#let cs = (<bm-zh>, <bm-en>, <eb-zh>)
#case("false（缺省）", gb7714.with(), cites: cs, full: false)
#case("true", gb7714.with(space-before-mark: true), cites: cs, full: false)
#case("true + 裸 mark token 的自定义驱动（不受它管）", gb7714.with(space-before-mark: true,
  custom-drivers: (book: "<author>. <title>[<mark>]. <publisher>, <year>")), cites: (<bm-zh>,), full: false)
#case("true + mark-medium token 的自定义驱动（受它管）", gb7714.with(space-before-mark: true,
  custom-drivers: (book: "<author>. <title><mark-medium>. <publisher>, <year>")), cites: (<bm-zh>,), full: false)
