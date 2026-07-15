//! param: name-suffix-separator
//! values: auto, string, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "name-suffix-separator", controls: "姓名与世系后缀（Jr. / II）之间的分隔符。",
  expect: [`auto` 按语言派生。显式字符串走三态（裸标点感知 / `{X}` verbatim / 字面量）；也收多语言字典，
    未点到的语言退回 `auto` 档的派生值。])
#let cs = (<nm-suffix>,)
#case("auto（缺省）", gb7714.with(bib-et-al-min: 999), bib: EDGE, cites: cs, full: false)
#case(`","`.text, gb7714.with(bib-et-al-min: 999, name-suffix-separator: ","), bib: EDGE, cites: cs, full: false)
#case(`" "`.text, gb7714.with(bib-et-al-min: 999, name-suffix-separator: " "), bib: EDGE, cites: cs, full: false)
#case(`""`.text + "（无分隔）", gb7714.with(bib-et-al-min: 999, name-suffix-separator: ""), bib: EDGE, cites: cs, full: false)
#case("多语言字典 (zh: 「·」, rest: 「, 」)", gb7714.with(bib-et-al-min: 999, name-suffix-separator: (zh: "·", rest: ", ")), bib: EDGE, cites: cs, full: false)
