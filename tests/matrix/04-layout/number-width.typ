//! param: number-width
//! values: auto, length
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "number-width", controls: "编号列的固定宽度。",
  expect: [`auto`（缺省）：按*本表最宽的那个编号*量出来（`[17]` 比 `[1]` 宽，全表按前者留位）。
    传长度则固定；过窄时编号与正文会挤到一起（不裁切、不报错）。
    正文左边界 = `number-width` + `number-gutter`。])
#case("auto（缺省，按最宽编号量）", gb7714.with(), full: true)
#case("3em", gb7714.with(number-width: 3em), full: true)
#case("1em（过窄，编号与正文相挤）", gb7714.with(number-width: 1em), full: true)
