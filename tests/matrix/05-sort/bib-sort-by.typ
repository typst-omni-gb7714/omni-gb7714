//! param: bib-sort-by
//! values: auto, none, array（键 name/date/title × 方向 ascending/descending）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-sort-by", controls: "参考文献表的排序键，按优先级从高到低。",
  expect: [`auto`（缺省）按标注体系派生：著者-出版年制取 `("name","date","title")`（GB §9.3.2），
    顺序编码制取 `none`（GB §9.2.1.1 按引用先后编号）。`none` = 保引用 / `.bib` 原序。
    数组的元素是键名（升序）或单条方向字典 `(date: "descending")`。
    *文种是隐式的最高优先级键*，不可省（GB §9.3.2「先按文种集中」），文种之间的先后由 `entry-lang-order` 定。])
#case("auto · 顺序编码制（→ none，按引用先后）", gb7714.with(), cites: (<st-zh>, <bm-zh>, <aj-en>, <bm-en>), full: false)
#case("auto · 著者-出版年制（→ name, date, title）", gb7714.with(style: "author-date"), cites: (<st-zh>, <bm-zh>, <aj-en>, <bm-en>), full: false)
#case("none · 著者-出版年制（保原序）", gb7714.with(style: "author-date", bib-sort-by: none), cites: (<st-zh>, <bm-zh>, <aj-en>, <bm-en>), full: false)
#case(`("date",)`.text + "（出版年升序）", gb7714.with(style: "author-date", bib-sort-by: ("date",)), full: true)
#case(`((date: "descending"),)`.text + "（出版年降序）", gb7714.with(style: "author-date", bib-sort-by: ((date: "descending"),)), full: true)
#case(`("title",)`.text, gb7714.with(style: "author-date", bib-sort-by: ("title",)), full: true)
#case(`((date: "descending"), "name")`.text + "（先年降序、再责任者升序）", gb7714.with(style: "author-date", bib-sort-by: ((date: "descending"), "name")), full: true)
#case("顺序编码制也可显式排序：(\"name\",)", gb7714.with(bib-sort-by: ("name",)), full: true)
