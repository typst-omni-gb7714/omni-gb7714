//! combo: page-range-style × page-range-separator × space-before-pages × imprint 占位 × supplement
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：页码与出版项", controls: "页码的三个参数与出版项的两个占位互不相干、各管一段。",
  expect: [页码三参*正交*：`page-range-style` 产出*数字*（折叠 / 展开）、`page-range-separator` 给*连接符*、
    `space-before-pages` 管页码*冒号后*的空格。
    `page-range-style` *只作用于文献表的 `pages` 字段*：`eid`（文章编号回退）不是范围、
    正文引用的 `supplement`（引文页码）是用户直接给的内容，*都不参与*。
    出版项两占位（`show-sine-loco` / `show-sine-nomine`）各管出版地与出版者，正交；
    用户手写在字段里的 `[S.l.]` 两档都原样著录。
    连载文献（§8.5.1.3）：后续部分不另立条目，把「；年，卷（期）：页」直接塞进 `pages` 字段照录——首组「年，卷（期）：」
    由结构化字段给，pages 里除本组页码外携带后续串。整串含「；」「：」非规范页码范围，`page-range-style` 不折叠、原样照录（连首组也不折），保住连载串完整。])
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
// 连载文献（§8.5.1.3）：后续部分作字面串塞进 pages，随著录照录；整串非规范范围，page-range-style 不折叠。
#case("连载文献：pages 携带后续「20-25；2011，33（3）：26-30」照录（§8.5.1.3）", gb7714.with(),
  bib: bytes("@article{ser, author={{某}}, title={连载题名}, journaltitle={某刊}, date={2011}, volume={33}, number={2}, pages={20-25；2011，33（3）：26-30}, langid={chinese}}"), full: true)
#case("连载 + page-range-style: minimal（整串非规范范围，不折叠、原样照录）", gb7714.with(page-range-style: "minimal"),
  bib: bytes("@article{ser2, author={{某}}, title={连载题名}, journaltitle={某刊}, date={2011}, volume={33}, number={2}, pages={120-125；2011，33（3）：126-130}, langid={chinese}}"), full: true)
