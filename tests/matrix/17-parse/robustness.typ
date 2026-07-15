//! param: 载入健壮性（条目键空白 · NFD 重音 · 自造类型透传 · 非法取值兜底）
//! values: `@book {k}` · Café(NFD) · @mytype · version 非法值
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "载入健壮性", controls: "畸形但合法的输入不该把整篇文档带崩。",
  expect: [- *条目键前的空白*：`@book {key}`（类型名与花括号之间有空格）照常解析；
    - *NFD 分解形重音*（`Café` 写成 `Cafe` + U+0301）：全库语言预扫描曾在这里崩
      （`to-unicode` 按字节迭代撞上非字符边界），现按码位迭代，正常渲染；
    - *自造类型透传*：`@mytype` 原样保留类型名（上游 crate 会压成 unknown），没登记码则兜底 `[Z]`；
    - *`version` 非法值兜底*：写成字符串 `"2015"` 也接受（不文档化、不推荐，只避免常见笔误把整篇卡住）。])
#case("三条畸形输入一起渲染", gb7714.with(), bib: PARSE, full: true,
  bib-args: (keys: [@pa-key-space@pa-nfd@pa-rawtype]))
#case("NFD 条目 · entry-lang-detect: accurate（预扫描全开）", gb7714.with(entry-lang-detect: "accurate"),
  bib: PARSE, full: true, bib-args: (keys: [@pa-nfd]))
#case("version 写成字符串 \"2015\"（笔误兜底）", gb7714.with(version: "2015"), bib: PARSE, full: true,
  bib-args: (keys: [@pa-key-space]))
#case("自造类型 + custom-marks 登记", gb7714.with(custom-marks: (mytype: "XX")), bib: PARSE, full: true,
  bib-args: (keys: [@pa-rawtype]))
