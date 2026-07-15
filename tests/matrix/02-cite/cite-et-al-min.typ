//! param: cite-et-al-min
//! values: 2, 4, 5, 999, 语言档
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-et-al-min", controls: "标注里责任者数量*达到*此值就截断（加「等 / et al.」）。",
  expect: [缺省 `2`：1 位完整列出，2 位及以上截断。
    *语义与 CSL 的 `et-al-min` 逐字同义*——责任者数**达到**此数就截断（`>=`），CSL 样式里的数值照搬即可、
    不必换算。（曾是「*超过*此数才截断」，默认值也因此小一位；语义等价，但每次跟 CSL 样式对照都要在脑子里
    ±1，迁移样式时极易错位。）
    语料条目有 4 位责任者——设 `4` 恰好截断（「达到」即截），设 `5` 不截断，设 `999` 等于关闭截断。
    与 `cite-et-al-use-first` 正交：本参数决定*何时*截，那个决定*留几位*。

    末档是*字典取值*，与 `bib-et-al-min` 同规（整数 / 语言档 / 角色档）：`(zh: 5, rest: 2)`
    让中文条目 5 位才截（4 位责任者全出）、西文条目仍 2 位就截。行内标注只出主责任者，所以角色档
    在 cite 侧只有 `principal` 一个键有意义。])
#let cs = (<bm-zh>, <bm-en>)
#cite-only("2（缺省）", gb7714.with(style: "author-date"), cites: cs)
#cite-only("4（= 责任者数，恰好截断）", gb7714.with(style: "author-date", cite-et-al-min: 4), cites: cs)
#cite-only("5（> 责任者数，不截断）", gb7714.with(style: "author-date", cite-et-al-min: 5), cites: cs)
#cite-only("999（关闭截断）", gb7714.with(style: "author-date", cite-et-al-min: 999), cites: cs)
#cite-only("语言档 (zh: 5, rest: 2)：中文全出、西文仍截",
  gb7714.with(style: "author-date", cite-et-al-min: (zh: 5, rest: 2)), cites: cs)
