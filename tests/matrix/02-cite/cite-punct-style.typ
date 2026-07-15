//! param: cite-punct-style
//! values: by-doc-and-style, by-doc-no-space, by-doc-with-space, by-entry-and-style, by-entry-no-space, by-entry-with-space, half, half-with-space, full, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-punct-style", controls: "标注*内部*标点（分隔逗号、括号、冒号）的全 / 半角与空格。",
  expect: [`by-doc-*` 按*文档*语言派生；`by-entry-*` 按*被引条目*语言派生；`half` / `half-with-space` / `full` 是绝对档。
    `-and-style` 额外做*制度感知*（顺序编码制紧凑无空格 `[1,2]`、著者-出版年制带空格）。
    字典可逐制分设。本文件的*文档语言是中文*、条目有中有西——两个轴的差别因此都看得见；
    末两块用 `in-lang("en", ..)` 把同一档位裹进*西文文档*作对照。])
#let mix = [正文 #cite(<bm-zh>)#cite(<bm-en>) 与 #cite(<aj-zh>, supplement: [7])。]
#cite-only("by-doc-and-style（缺省）· 顺序编码制", gb7714.with(), body: mix)
#cite-only("by-doc-and-style · 著者-出版年制", gb7714.with(style: "author-date"), body: mix)
#cite-only("by-doc-no-space", gb7714.with(cite-punct-style: "by-doc-no-space"), body: mix)
#cite-only("by-doc-with-space", gb7714.with(cite-punct-style: "by-doc-with-space"), body: mix)
#cite-only("by-entry-and-style · 著者-出版年制", gb7714.with(style: "author-date", cite-punct-style: "by-entry-and-style"), body: mix)
#cite-only("by-entry-no-space", gb7714.with(cite-punct-style: "by-entry-no-space"), body: mix)
#cite-only("by-entry-with-space", gb7714.with(cite-punct-style: "by-entry-with-space"), body: mix)
#cite-only("half", gb7714.with(cite-punct-style: "half"), body: mix)
#cite-only("half-with-space", gb7714.with(cite-punct-style: "half-with-space"), body: mix)
#cite-only("full", gb7714.with(cite-punct-style: "full"), body: mix)
#cite-only("字典 · (numeric: half, author-date: full)", gb7714.with(style: "author-date", cite-punct-style: (numeric: "half", author-date: "full")), body: mix)
#cite-only("by-doc-with-space · 西文文档（→ 半角）", in-lang("en", gb7714.with(cite-punct-style: "by-doc-with-space")), body: mix)
#cite-only("by-entry-with-space · 西文文档（不随文档 → 中文条目仍全角）", in-lang("en", gb7714.with(cite-punct-style: "by-entry-with-space")), body: mix)
