//! param: cite-name-date-separator
//! values: auto, string, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-name-date-separator", controls: "标注里责任者与出版年之间的分隔符。",
  expect: [`auto` 随版本与条目标点轴：2015 / 2025 用逗号（全 / 半角随条目语言），2005 的半角标点条目用空格
    （对齐标准 10.2.1 的西文示例 `(Crane 1972)`）。显式字符串走三态：裸标点字符做全 / 半角感知，
    `{X}` 是 verbatim 定界，其余当字面量。
    *多语言字典*按*条目语言*挑值，没点到的语言退回 `auto` 档的派生值；挑出来的值*再走上面那三态*
    （与 bib 侧的 `bib-name-date-separator` 同规——两侧对称）。])
#let cs = (<bm-zh>, <bm-en>)
#cite-only("auto · 2025", gb7714.with(style: "author-date"), cites: cs)
#cite-only("auto · 2005（西文条目用空格）", gb7714.with(style: "author-date", version: 2005), cites: cs)
#cite-only(`"," （裸逗号，全/半角感知）`.text, gb7714.with(style: "author-date", cite-name-date-separator: ","), cites: cs)
#cite-only(`"." （裸句点）`.text, gb7714.with(style: "author-date", cite-name-date-separator: "."), cites: cs)
#cite-only(`" " （空格）`.text, gb7714.with(style: "author-date", cite-name-date-separator: " "), cites: cs)
#cite-only("{ — }（verbatim 定界，原样不感知）", gb7714.with(style: "author-date", cite-name-date-separator: "{ — }"), cites: cs)
#cite-only("多语言字典 (zh: 「，」, rest: 「, 」)", gb7714.with(style: "author-date", cite-name-date-separator: (zh: "，", rest: ", ")), cites: cs)
#cite-only("多语言字典只点中文（其余语言退回 auto 档派生值）", gb7714.with(style: "author-date", cite-name-date-separator: (zh: "·")), cites: cs)
#cite-only("多语言字典 + verbatim 值", gb7714.with(style: "author-date", cite-name-date-separator: (zh: "{ ～ }", rest: "{ - }")), cites: cs)
