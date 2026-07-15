//! param: cite(逐次覆盖)
//! values: 每个可覆盖参数：全局设一个值、本次设另一个值 → 本次胜出
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite(..) 逐次覆盖", controls: "`#cite()` 的同名参数覆盖全局 / 列表，`auto` 继承。",
  expect: [本文件*逐个*走一遍 `cite()` 的可覆盖参数：每块把*全局*设成一个值、把*本次引用*设成另一个值，
    正文标注里印出来的必须是*本次*那个值。缺省 `auto` 表示「继承列表 / 全局」。
    覆盖链：**`cite` 显式 > `bibliography` 逐表 > `gb7714` 全局**。
    ⚠️ `custom-drivers` / `custom-terms` / `custom-fields` / `custom-pids` / `show-pid` / `pid-priority` /
    `dedup-url-pid` / `show-annotation` 与四个 `footnote-*` 参数*只在 `footnote: true` 时生效*
    （见 `footnote-only.typ`）——正文标注里没有著录可言。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#case("bib-label（临时归属到命名列表 x）", gb7714.with(), bib: mixed, full: false, body: [
  归属 x 的引用 #cite(<bm-zh>, bib-label: "x")，归属主表的引用 #cite(<aj-zh>)。
  #bibliography(mixed, title: [列表 x], full: false, label: "x")])
#cite-only("style", gb7714.with(), bib: mixed, body: [全局档 #cite(<bm-zh>)#cite(<bm-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, style: "author-date")。])
// `"super"` 与 `"inline"` 的差别是*上标*——抽出来的文本一样，看不出覆盖有没有生效。
// 改用著者-出版年制下文本可辨的三档：`prose`（叙述式）/ `author`（只出责任者）/ `year`（只出年份）。
#cite-only("form · prose", gb7714.with(style: "author-date", cite-form: "normal"), bib: mixed, body: [全局档 #cite(<bm-zh>)；本次覆盖 #cite(<bm-zh>, form: "prose")。])
#cite-only("form · author / year", gb7714.with(style: "author-date"), bib: mixed, body: [只出责任者 #cite(<bm-zh>, form: "author")；只出年份 #cite(<bm-zh>, form: "year")。])
#cite-only("name-style", gb7714.with(style: "author-date"), bib: mixed, body: [全局档 #cite(<bm-zh>)#cite(<bm-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, name-style: (given-form: "full"))。])
// 顺序编码制下两条连号压成 [1-2]，标点看不见——用著者-出版年制才辨得出全 / 半角。
#cite-only("punct-style", gb7714.with(style: "author-date", cite-punct-style: "full"), bib: mixed, body: [全局档 #cite(<bm-zh>, <bm-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, punct-style: "half-with-space")。])
#cite-only("supplement-style", gb7714.with(cite-supplement-style: "compact"), bib: mixed, body: [全局档 #cite(<bm-zh>, supplement: [12])；本次覆盖 #cite(<bm-en>, supplement: [34], supplement-style: "split")。])
#cite-only("merge", gb7714.with(cite-merge: true), bib: mixed, body: [全局档 #cite(<bm-zh>)#cite(<bm-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, merge: false)。])
// 语料 bm-* 有 4 位责任者，阈值 3 与 1 都会截断——看不出差别。
// 用 2 位责任者的 aj-*：阈值 3 不截断（陈九，卫十）、阈值 1 截断（陈九等）。
#cite-only("et-al-min", gb7714.with(style: "author-date", cite-et-al-min: 3), bib: mixed, body: [全局档 #cite(<aj-zh>, <aj-en>)；本次覆盖 #cite(<aj-zh>, <aj-en>, et-al-min: 1)。])
#cite-only("et-al-use-first", gb7714.with(style: "author-date", cite-et-al-min: 1, cite-et-al-use-first: 3), bib: mixed, body: [全局档 #cite(<bm-zh>)#cite(<bm-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, et-al-use-first: 1)。])
#cite-only("terms-lang", gb7714.with(style: "author-date", cite-et-al-min: 1), bib: mixed, body: [全局档 #cite(<bm-zh>)#cite(<bm-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, terms-lang: "zh")。])
// 四条连号两档都压成 [1-4]——看不出差别。用三条连号：阈值 4 不压（[1,2,3]）、阈值 2 压（[1-3]）。
#cite-only("compress-min", gb7714.with(cite-compress-min: 4), bib: mixed, body: [全局档 #cite(<bm-zh>, <bm-en>, <aj-zh>)；本次覆盖 #cite(<bm-zh>, <bm-en>, <aj-zh>, compress-min: 2)。])
#cite-only("range-separator", gb7714.with(cite-range-separator: "-"), bib: mixed, body: [全局档 #cite(<bm-zh>, <bm-en>, <aj-zh>, <aj-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, <aj-zh>, <aj-en>, range-separator: "～")。])
#cite-only("sort-by", gb7714.with(style: "author-date", cite-sort-by: none), bib: mixed, body: [全局档 #cite(<bm-zh>, <bm-en>, <aj-zh>, <aj-en>)；本次覆盖 #cite(<bm-zh>, <bm-en>, <aj-zh>, <aj-en>, sort-by: ("date",))。])
#cite-only("sort-zh-by", gb7714.with(style: "author-date", cite-sort-by: ("name",)), bib: LANG, body: [全局档 #cite(<sort-zh-1>, <sort-zh-2>, <sort-zh-3>, <sort-zh-4>)；本次覆盖 #cite(<sort-zh-1>, <sort-zh-2>, <sort-zh-3>, <sort-zh-4>, sort-zh-by: "bihua")。])
#cite-only("collapse-date", gb7714.with(style: "author-date", cite-collapse-date: false), bib: mixed, body: [全局档 #cite(<nm-same-a>, <nm-same-b>)；本次覆盖 #cite(<nm-same-a>, <nm-same-b>, collapse-date: true)。])
#case("footnote（本次走脚注）", gb7714.with(cite-footnote: false), bib: mixed, full: false, body: [行内引用 #cite(<aj-zh>)，脚注引用 #cite(<bm-zh>, footnote: true)。])
