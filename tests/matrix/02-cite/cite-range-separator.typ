//! param: cite-range-separator
//! values: string, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-range-separator", controls: "压缩区间的连接符（`[1-3]` 里的那根横线）。",
  expect: [缺省 `"-"`（半角连字符）。可给任意字符串；也可给*多语言字典*按条目语言分设，
    未点到的语言退回本参数的缺省值。裸标点字符走全 / 半角感知，其余当字面量。])
#let three = [正文 #cite(<bm-zh>)#cite(<bm-en>)#cite(<bm-noauthor>)。]
#cite-only(`"-"（缺省）`.text, gb7714.with(), body: three)
#cite-only(`"–"（en dash）`.text, gb7714.with(cite-range-separator: "–"), body: three)
#cite-only(`"~"`.text, gb7714.with(cite-range-separator: "~"), body: three)
#cite-only("多语言字典 (zh: 「～」, rest: 「-」)", gb7714.with(cite-range-separator: (zh: "～", rest: "-")), body: three)
