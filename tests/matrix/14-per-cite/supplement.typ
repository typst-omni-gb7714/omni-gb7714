//! param: cite(supplement)
//! values: none, content, 数组（逐一对应）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite(supplement)", controls: "引文页码 / 补充说明。",
  expect: [单个 content *作用于末位引用*；传数组则与本次的多个引用*逐一对应*。
    显示形态由 `cite-supplement-style` 定（`"compact"` 贴在标注里 / `"split"` 拆成上标）。
    脚注制下 supplement 接在注文之后（「同上：88」）。
    ⚠️ `supplement` 是用户直接给的内容，*不参与* `page-range-style` 的位数重排。])
#let one(name, cfg) = cite-only(name, cfg, body: [
  单引带页码 #cite(<bm-zh>, supplement: [12])；
  合并引用 · 单 supplement 落在*末位* #cite(<bm-zh>, <bm-en>, supplement: [88])；
  合并引用 · 数组逐一对应 #cite(<bm-zh>, <bm-en>, supplement: ([12], [34]))；
  非页码的补充说明 #cite(<aj-zh>, supplement: [表 2]).
])
#one("顺序编码制（缺省 supplement-style）", gb7714.with())
#one("顺序编码制 + supplement-style: \"split\"", gb7714.with(cite-supplement-style: "split"))
#one("著者-出版年制", gb7714.with(style: "author-date"))
#one("逐次覆盖 supplement-style", gb7714.with(cite-supplement-style: "compact"))
#case("脚注制：supplement 接在注文之后", gb7714.with(cite-footnote: true), full: false,
  body: [首 #cite(<bm-zh>, supplement: [12]) 邻 #cite(<bm-zh>, supplement: [34])。])
