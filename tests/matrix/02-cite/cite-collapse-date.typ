//! param: cite-collapse-date
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-collapse-date", controls: "著者-出版年制下，同责任者的多条引用是否折叠成一个责任者 + 多个年份。",
  expect: [`true`（缺省）：`(张三, 2020, 2021)`——责任者只出一次。`false`：`(张三, 2020; 张三, 2021)`。
    只在著者-出版年制下有意义（顺序编码制标注是数字，无责任者可折叠）。])
#let same-author = [正文 #cite(<nm-same-a>)#cite(<nm-same-b>)#cite(<nm-noyear-a>)。]
#cite-only("true（缺省）", gb7714.with(style: "author-date"), bib: EDGE, body: same-author)
#cite-only("false", gb7714.with(style: "author-date", cite-collapse-date: false), bib: EDGE, body: same-author)
