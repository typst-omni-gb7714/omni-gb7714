//! param: page-range-separator
//! values: string（三态：裸标点感知 / {X} verbatim / 字面量）, dictionary（按条目语言）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "page-range-separator", controls: "起讫页码的连接符。",
  expect: [缺省 `"-"`。接受任意字符串：
    *裸标点字符*（`","` `"."` 等九种结构标点）随 `bib-punct-style` 与条目语言做全 / 半角感知；
    *verbatim 定界* `"{,}"` 字面输出、不感知；其余字符串（`"～"` `"–"`）就是字面量。
    *多语言字典*按*条目语言*分设：`(zh: "～")` 让中文条目出全角波浪线、其余语言照旧（走本参数预设值 `"-"`）；
    键是语言码（`zh`/`en`/`ja`/`ko`/`ru`/`fr`），写错的键直接报错；`rest` 兜底档改写「其余语言」那一档。
    挑出来的值*再走上面那三态*。字典档对*全部* `-separator` 配置生效，不止本项。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>, <aj-en>)
#case(`"-"`.text + "（缺省）", gb7714.with(), cites: cs, full: false)
#case(`"～"`.text + "（全角波浪线，字面量）", gb7714.with(page-range-separator: "～"), cites: cs, full: false)
#case(`"–"`.text + "（en dash，字面量）", gb7714.with(page-range-separator: "–"), cites: cs, full: false)
#case(`","`.text + "（裸标点 → 随 punct-style 与条目语言感知）", gb7714.with(page-range-separator: ",", bib-punct-style: "by-entry-with-space"), cites: cs, full: false)
#case(`"{,}"`.text + "（verbatim → 恒半角逗号，不感知）", gb7714.with(page-range-separator: "{,}", bib-punct-style: "by-entry-with-space"), cites: cs, full: false)
#case(`(zh: "～")`.text + "（中文条目波浪线，西文条目回落预设 -）", gb7714.with(page-range-separator: (zh: "～")), cites: cs, full: false)
#case(`(zh: "～", rest: "–")`.text + "（rest 改写「其余语言」档）", gb7714.with(page-range-separator: (zh: "～", rest: "–")), cites: cs, full: false)
