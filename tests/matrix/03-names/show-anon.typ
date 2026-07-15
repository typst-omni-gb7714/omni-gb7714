//! param: show-anon
//! values: auto, true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(
  param: "show-anon",
  controls: "责任者不明时是否补占位词（佚名 / Anon）。",
  expect: [
    `auto`（缺省）= *制度感知*：著者-出版年制显示占位词（无责任者就构不成「著者-年」标签），
    顺序编码制留空（标签是数字序号，题名打头即可）。官方 GB CSL 两制实测就是这样。
    `true` / `false` 显式覆盖。占位词按*条目*语言取（zh 佚名 / en Anon），且*行内与文献表同源*
    ——它是查找键，两侧分裂读者就在按责任者字顺排的表里定位不到。
    排序键 = 责任者位实际显示的内容：开着按占位词排（biblatex 实测：安(a) → 王(w) → 佚名(y) → 赵(zh)），
    关着顺延到题名。
  ],
)
#case("auto · 著者-出版年制（→ true）", gb7714.with(style: "author-date"),
  cites: (<bm-noauthor>, <bm-zh>), bib: MAIN, full: false)
#case("auto · 顺序编码制（→ false）", gb7714.with(),
  cites: (<bm-noauthor>, <bm-zh>), bib: MAIN, full: false)
#case("true · 顺序编码制", gb7714.with(show-anon: true),
  cites: (<bm-noauthor>, <bm-zh>), bib: MAIN, full: false)
#case("false · 著者-出版年制", gb7714.with(style: "author-date", show-anon: false),
  cites: (<bm-noauthor>, <bm-zh>), bib: MAIN, full: false)
#case("排序键：开着按占位词排（佚名 y 落在 王 w 与 赵 zh 之间）",
  gb7714.with(style: "author-date", show-anon: true), bib: LANG, full: true, body: [])
#case("排序键：关着顺延题名",
  gb7714.with(style: "author-date", show-anon: false), bib: LANG, full: true, body: [])
