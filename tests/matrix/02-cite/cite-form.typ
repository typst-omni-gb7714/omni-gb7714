//! param: cite-form
//! values: auto, super, inline, normal, prose, author, year, none
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-form", controls: "正文引用标注的形态。",
  expect: [`auto` 随制度：顺序编码制 `super`（上标 [1]）、著者-出版年制 `normal`（括号内）。
    `prose` 把责任者移出括号（「张三（2020）指出」）；`author` / `year` 只出一半；`none` 只注册不显示。
    上标形态吃引用号前的空格（对齐原生「词[1]」）。])
#let probe-cites = [词 #cite(<bm-zh>) 与 #cite(<bm-en>)。]
#cite-only("auto · 顺序编码制（→ super）", gb7714.with(), body: probe-cites)
#cite-only("auto · 著者-出版年制（→ normal）", gb7714.with(style: "author-date"), body: probe-cites)
#cite-only("super", gb7714.with(cite-form: "super"), body: probe-cites)
#cite-only("inline", gb7714.with(cite-form: "inline"), body: probe-cites)
#cite-only("normal", gb7714.with(cite-form: "normal"), body: probe-cites)
#cite-only("prose · 著者-出版年制", gb7714.with(style: "author-date", cite-form: "prose"), body: probe-cites)
#cite-only("prose · 顺序编码制", gb7714.with(cite-form: "prose"), body: probe-cites)
#cite-only("author · 著者-出版年制", gb7714.with(style: "author-date", cite-form: "author"), body: probe-cites)
#cite-only("year · 著者-出版年制", gb7714.with(style: "author-date", cite-form: "year"), body: probe-cites)
#cite-only("none（只注册不显示）", gb7714.with(cite-form: none), body: probe-cites)
