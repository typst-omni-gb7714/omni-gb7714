//! param: number-align
//! values: "left", "right", "center"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "number-align", controls: "编号在编号列里的水平对齐（成列两档才有意义）。",
  expect: [`"left"`（缺省）：编号左对齐，`[9]` 与 `[10]` 左边界齐。
    `"right"`：右对齐，个位数与十位数的*右括号*齐。`"center"`：居中。
    语料够 10 条才看得出差别，故本用例开 `full: true`；并把 `number-width` 放宽以拉开差距。])
#case(`"left"`.text + "（缺省）", gb7714.with(number-width: 3em), full: true)
#case(`"right"`.text, gb7714.with(number-align: "right", number-width: 3em), full: true)
#case(`"center"`.text, gb7714.with(number-align: "center", number-width: 3em), full: true)
#case(`"right"`.text + " · number-placement: margin", gb7714.with(number-align: "right", number-placement: "margin"), full: true)
