//! param: style
//! values: numeric, author-date, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "style", controls: "著录与标注的样式制度。",
  expect: [标量作用于两轴；字典可*逐轴分设*（`(cite:, bib:)`），得到「标注用一制、著录用另一制」的混合形态。
    值域外的字符串（`"ieee"` / `"apa"` 等原生 CSL 名）不报错，回落全局。])
#case("numeric（缺省）", gb7714.with(), cites: (<bm-zh>, <bm-en>), full: false)
#case("author-date", gb7714.with(style: "author-date"), cites: (<bm-zh>, <bm-en>), full: false)
#case("字典 · cite 顺序编码制 × bib 著者-出版年制", gb7714.with(style: (cite: "numeric", bib: "author-date")), cites: (<bm-zh>, <bm-en>), full: false)
#case("字典 · cite 著者-出版年制 × bib 顺序编码制", gb7714.with(style: (cite: "author-date", bib: "numeric")), cites: (<bm-zh>, <bm-en>), full: false)
