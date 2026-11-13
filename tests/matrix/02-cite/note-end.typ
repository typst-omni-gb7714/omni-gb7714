//! param: note（"end" 尾注制）
//! values: version 2015 / 2025 梯子 × reuse × markup
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "note: \"end\"（尾注制）", controls: "注模式取 `\"end\"`：正文出注号（自建计数器、上标圈码），完整著录集中排在 `#bibliography` 位置的*尾注列表*，*取代*参考文献表。",
  expect: [注号与脚注制同一套圈码（`note-numbering-style`），著录与重复梯子也与脚注制同源——差别只在落点从页脚换到文末。
    正文上标注号与列表条目号*逐字同源*（都取自建 `_endnote-counter` 在该位置的值）。本文件是*一个连续文档*，各 case 用不同 key 让梯子各自从头演示；注号跨 case 连续递增（与脚注制矩阵同惯例）。
    - 首次完整著录，重复位「同上 / 同③」，梯子随 `version`：2015 紧邻「同上」、隔开「同③」；2025 弃 ibid，紧邻也走「同③」；
    - 「同③」的 ③ 引*尾注号*（非脚注号），与正文上标同源；引语词按*被引条目*语言（中文「同上」、西文「See note」）；
    - `note-repeat-style: "reuse"`：正文复用首个尾注号，列表*不*多出一条；
    - markup `@key` 与函数 `#cite()` 同入尾注（两条渲染路径同源）。])
#case("2015 梯子：full · 同上（紧邻）· full · 同①（隔开）", gb7714.with(note: "end", version: 2015), full: false,
  body: [甲 @bm-zh 紧邻 @bm-zh 换 @bm-en 隔开 @bm-zh。])
#case("2025 梯子：紧邻也走同③（弃 ibid）", gb7714.with(note: "end", version: 2025), full: false,
  body: [甲 @aj-zh 紧邻 @aj-zh 换 @aj-en 隔开 @aj-zh。])
#case("reuse：正文复用首号、列表不出新条目", gb7714.with(note: "end", version: 2015, note-repeat-style: "reuse"), full: false,
  body: [甲 @ic-zh 换 @cp-zh 再引 @ic-zh。])
#case("markup @key 与 #cite() 同入尾注", gb7714.with(note: "end", version: 2015), full: false,
  body: [markup @dt-zh 与函数 #cite(<rp-zh>)。])
#case("合注：相邻引用合成一个尾注（分号连、单注号）", gb7714.with(note: "end", version: 2015), full: false,
  body: [合注 @st-zh#cite(<pt-zh>) 与单注 @np-zh。])
#case("引文页码：supplement 进注体（首「: 25」·紧邻同上「: 30」）", gb7714.with(note: "end", version: 2015), full: false,
  body: [甲 #cite(<eb-zh>, supplement: [25]) 邻 #cite(<eb-zh>, supplement: [30])。])
#case("著者-出版年制注体：年份前置「作者，年.」开头（注体随 bib 轴，与脚注制同源）", gb7714.with(note: "end", version: 2015, style: (cite: "numeric", bib: "author-date")), full: false,
  body: [甲 @ds-zh。])
// 缺省 `title`（`auto`）：尾注列表*不*补「参考文献」标题（它取代文献表、但形态是注不是表）；下方
//   区块紧接注号、无标题行即证。显式 title 才排标题（见前文单表冒烟）。
#case("缺省 title：尾注列表不补「参考文献」标题", gb7714.with(note: "end", version: 2015), title: auto, full: false,
  body: [甲 @sw-zh。])
