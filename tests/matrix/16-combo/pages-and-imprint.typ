//! combo: page-range-style × page-range-separator × space-before-pages × imprint 占位 × supplement
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：页码与出版项", controls: "页码的三个参数与出版项的两个占位互不相干、各管一段。",
  expect: [页码三参*正交*：`page-range-style` 产出*数字*（折叠 / 展开）、`page-range-separator` 给*连接符*、
    `space-before-pages` 管页码*冒号后*的空格。
    `page-range-style` *只作用于文献表的 `pages` 字段*：`eid`（文章编号回退）不是范围、
    正文引用的 `supplement`（引文页码）是用户直接给的内容，*都不参与*。
    出版项两占位（`show-sine-loco` / `show-sine-nomine`）各管出版地与出版者，正交；
    用户手写在字段里的 `[S.l.]` 两档都原样著录。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let cs = (<bm-zh>, <aj-en>, <vp-artno>, <vp-pagerange>, <im-nopub>, <im-noloc>, <im-placeholder>)
#let one(name, cfg) = case(name, cfg, bib: mixed, cites: cs, full: false)
#one("缺省", gb7714.with())
#one("page-range-style: minimal", gb7714.with(page-range-style: "minimal"))
#one("+ page-range-separator: 「～」（两轴正交）", gb7714.with(page-range-style: "minimal", page-range-separator: "～"))
#one("+ space-before-pages: false（第三轴）", gb7714.with(page-range-style: "minimal", page-range-separator: "～", space-before-pages: false))
#one("show-sine-loco / show-sine-nomine 全开", gb7714.with(show-sine-loco: true, show-sine-nomine: true))
#one("全开 + 版本 2015（占位词形态随版本？）", gb7714.with(show-sine-loco: true, show-sine-nomine: true, version: 2015))
#case("supplement 不参与 page-range-style（用户直接给的内容）", gb7714.with(page-range-style: "minimal"),
  bib: mixed, full: false, body: [引文页码 #cite(<bm-zh>, supplement: [321-328])，与文献表里的 pages 对照。])
