//! param: bibliography(entry-type / mark / filter / keys / keyword)
//! values: 五种过滤器 × 组合
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bibliography 的五个过滤器", controls: "只渲染表里的一部分条目。",
  expect: [- `entry-type`：按 `.bib` 条目类型过滤，收单值或数组（`"book"` / `("book", "article")`）；
    - `mark`：按*文献类型标识*过滤（`"M"` / `("C", "G")`）——按码而非按类型，与 `custom-marks` 登记的自造码通用；
    - `filter`：自定义函数 `entry => bool`，拿到的是条目对象；
    - `keys`：只渲染点名的条目，传内容块 `[@k1@k2]`，*按书写顺序*；
    - `keyword`：按 `keywords` 字段*子串*匹配。
    过滤器与 `full` 正交：`full: true` 先取全表、再过滤。多个过滤器同时给时逐个收窄（取交集）。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let one(name, args) = case(name, gb7714.with(), bib: mixed, full: true, bib-args: args)
#one("不过滤（全表）", (entry-type: "thesis"))
#one("entry-type: \"book\"", (entry-type: "book"))
#one("entry-type: (\"article\", \"thesis\")", (entry-type: ("article", "thesis")))
#one("mark: \"J\"（按标识码）", (mark: "J"))
#one("mark: (\"D\", \"S\")", (mark: ("D", "S")))
#one("filter: 自定义函数（只留有 doi 字段的；拿到的是条目对象，键在外层、不在 `e` 上）", (filter: e => "doi" in e.fields))
#one("keys: [@st-zh@bm-en]（点名 + 书写序）", (keys: [@st-zh@bm-en]))
#one("keyword: \"示例关键词\"", (keyword: "示例关键词"))
#one("组合：entry-type book + filter 有 url", (entry-type: "book", filter: e => "url" in e.fields))
