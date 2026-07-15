//! param: cite-supplement-style
//! values: auto, compact, split
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-supplement-style", controls: "引文页码在标注里的显示形态。",
  expect: [`compact`：页码并进标注方括号内（`[1]25`）。`split`：页码作上标拆出（`[1]^25`）。
    `auto` 随制度。著者-出版年制下页码接在年份后（`(张三, 2020: 25)`）。])
#let supp = [正文 #cite(<bm-zh>, supplement: [25]) 与 #cite(<bm-en>, supplement: [30-32])。]
#cite-only("auto · 顺序编码制", gb7714.with(), body: supp)
#cite-only("compact · 顺序编码制", gb7714.with(cite-supplement-style: "compact"), body: supp)
#cite-only("split · 顺序编码制", gb7714.with(cite-supplement-style: "split"), body: supp)
#cite-only("auto · 著者-出版年制", gb7714.with(style: "author-date"), body: supp)
#cite-only("compact · 著者-出版年制", gb7714.with(style: "author-date", cite-supplement-style: "compact"), body: supp)
#cite-only("split · 著者-出版年制", gb7714.with(style: "author-date", cite-supplement-style: "split"), body: supp)
