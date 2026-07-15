//! param: cite-sort-by
//! values: auto, none, array
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-sort-by", controls: "合并组*组内*的排序。",
  expect: [`auto` 随制度：顺序编码制按编号升序、著者-出版年制按版本派生。`none` 保书写序。
    数组给键与方向（键：`name` / `date`；方向：`ascending` / `descending`），可多键。
    与文献表的 `bib-sort-by` 独立。])
#let mixed = [正文 #cite(<aj-zh>)#cite(<bm-zh>)#cite(<bm-en>)。]
#cite-only("auto · 顺序编码制（编号升序）", gb7714.with(), body: mixed)
#cite-only("none（保书写序）", gb7714.with(cite-sort-by: none), body: mixed)
#cite-only("auto · 著者-出版年制", gb7714.with(style: "author-date"), body: mixed)
#cite-only("none · 著者-出版年制", gb7714.with(style: "author-date", cite-sort-by: none), body: mixed)
#cite-only("(name,)", gb7714.with(style: "author-date", cite-sort-by: ("name",)), body: mixed)
#cite-only("(date,)", gb7714.with(style: "author-date", cite-sort-by: ("date",)), body: mixed)
#cite-only("((date: descending),)", gb7714.with(style: "author-date", cite-sort-by: ((date: "descending"),)), body: mixed)
#cite-only("(name, date)", gb7714.with(style: "author-date", cite-sort-by: ("name", "date")), body: mixed)
