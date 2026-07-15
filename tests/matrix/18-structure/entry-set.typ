//! param: @set 条目集（entryset）
//! values: 成员合并渲染 · 标注 · 脚注 · 两制
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "@set 条目集", controls: "把几条文献合并成*一个*编号 / 一个标签。",
  expect: [`@set{main, entryset = {a, b}}`：`a` 与 `b` 在文献表里合并成*一条*（一个编号、一个骨架，
    成员逐条著录在其下），正文引用 `main` 得*一个*标注。
    引用成员键（`@a`）会*重定向*到集主条目——标签与编号都是集的。
    *著者-出版年制的标签*：用条目里显式的 `label` 字段作整体标签；**没有 `label` 字段就退化成 key**
    （对齐 biblatex v3.8+ 静态条目集的默认解法——集不是一个人写的一篇文献，没有天然的「著者-年」）。
    脚注制下集的完整著录 = 各成员依次著录。
    成员条目*不再单独出现*在文献表里（`full: true` 也不会）。])
#case("顺序编码制：集合并成一条", gb7714.with(), bib: EDGE, cites: (<set-main>, <ti-punct>), full: false)
#case("引用成员键 → 重定向到集", gb7714.with(), bib: EDGE, cites: (<set-a>, <set-b>), full: false)
#case("著者-出版年制 · 无 label 字段 → 标签退化成 key", gb7714.with(style: "author-date"), bib: EDGE, cites: (<set-main>,), full: false)
#case("著者-出版年制 · 有 label 字段 → 用它作整体标签", gb7714.with(style: "author-date"), bib: EDGE, cites: (<set-labeled>,), full: false)
#case("full: true（成员不再单独出现）", gb7714.with(), bib: EDGE, full: true,
  bib-args: (keys: [@set-main@ti-punct]))
#case("脚注制：集的完整著录 = 各成员依次著录", gb7714.with(cite-footnote: true), bib: EDGE, full: false,
  body: [引用条目集 #cite(<set-main>)，再引一次 #cite(<set-main>)。])
#case("end-with-period: false（成员之间的句点由谁补）", gb7714.with(end-with-period: false), bib: EDGE,
  cites: (<set-main>,), full: false)
