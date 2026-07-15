//! param: bib-sort-zh-by
//! values: "pinyin", "bihua"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-sort-zh-by", controls: "文献表里中文责任者姓名的排序方案（只对中文条目生效）。",
  expect: [`"pinyin"`（缺省）按汉语拼音字母序；`"bihua"` 按笔画数，同画按笔顺（横竖撇捺折）。
    语料四条中文责任者：`丁一`(2 画 / d) · `万二`(3 画 / w) · `习三`(3 画 / x) · `乔四`(6 画 / q)——
    拼音序 丁 → 乔 → 万 → 习；笔画序 丁 → 万 → 习 → 乔。
    顺序编码制按引用先后排，不受本参数影响。多音字用 `sortkey` / `key` 域手动指定排序值。])
#let cs = (<sort-zh-1>, <sort-zh-2>, <sort-zh-3>, <sort-zh-4>)
#case(`"pinyin"`.text + "（缺省 → 丁 乔 万 习）", gb7714.with(style: "author-date"), bib: LANG, cites: cs, full: false)
#case(`"bihua"`.text + "（→ 丁 万 习 乔）", gb7714.with(style: "author-date", bib-sort-zh-by: "bihua"), bib: LANG, cites: cs, full: false)
#case("顺序编码制：按引用先后，本参数不参与", gb7714.with(bib-sort-zh-by: "bihua"), bib: LANG, cites: cs, full: false)
#case("逐表覆盖：全局 pinyin，本表 bihua", gb7714.with(style: "author-date"), bib: LANG, cites: cs, full: false, bib-args: (sort-zh-by: "bihua"))
