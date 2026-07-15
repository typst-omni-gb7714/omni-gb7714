//! param: cite-et-al-use-last
//! values: 0, 1
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-et-al-use-last", controls: "行内标注截断后，在省略号之后再保留*原名单末尾* N 位责任者。",
  expect: [缺省 `0`（关）。与 `bib-et-al-use-last` 同规，只是作用在行内标注：出「前
    use-first 位 + 省略号 + 末 N 位」，且不再出「等 / et al」。

    语料每条 8 位责任者。设 `cite-et-al-min: 8`、`cite-et-al-use-first: 6`、`cite-et-al-use-last: 1`
    得 `(张三，李四，…，孙八，…吴十，2020)`。

    *注意*：真实样式里这个轴通常只开在文献表侧——心理学报的 `et-al-use-last="true"` 写在
    `<bibliography>` 上，`<citation>` 不带，所以它的正文标注仍是「等 / et al」。本包 `bib-` 与
    `cite-` 两轴独立，正好表达得了这种分工。])
#let cs = (<el-zh>, <el-en>)
#cite-only("0（缺省，关）", gb7714.with(style: "author-date", cite-et-al-min: 8), bib: ETAL-LAST, cites: cs)
#cite-only("1（前 6 + 省略号 + 末 1）",
  gb7714.with(style: "author-date", cite-et-al-min: 8, cite-et-al-use-first: 6, cite-et-al-use-last: 1),
  bib: ETAL-LAST, cites: cs)
