//! param: cite-merge
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-merge", controls: "相邻引用是否合并为一组标注。",
  expect: [`true`（缺省）：`@a@b@c` 合并成 `[1-3]` / `(A, 2020; B, 2021; C, 2022)`。
    `false`：各引用独立成组，`[1][2][3]` / `(A, 2020)(B, 2021)(C, 2022)`。
    合并组内的次序由 `cite-sort-by` 定（缺省顺序编码制按编号升序）。])
#let three = [正文 #cite(<bm-zh>)#cite(<bm-en>)#cite(<aj-zh>)。]
#cite-only("true（缺省）· 顺序编码制", gb7714.with(), body: three)
#cite-only("false · 顺序编码制", gb7714.with(cite-merge: false), body: three)
#cite-only("true · 著者-出版年制", gb7714.with(style: "author-date"), body: three)
#cite-only("false · 著者-出版年制", gb7714.with(style: "author-date", cite-merge: false), body: three)
