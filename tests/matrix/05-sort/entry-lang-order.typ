//! param: entry-lang-order
//! values: array
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "entry-lang-order", controls: "多语种混排时的语种分组次序（靠前的语种排在前面）。",
  expect: [缺省 `("zh","ja","ko","en","fr","ru")`。*文种是隐式的最高优先级排序键*，
    `bib-sort-by` 写不写它都先按文种集中（GB §9.3.2），本参数只决定文种之间谁先谁后。
    未列出的语种排在列出的之后。顺序编码制按引用先后编号，不分组。
    *`()`（空数组）= 不分组*（有意的公共契约）：所有条目走*一趟全局字顺*，中文条目按拼音混进西文里
    （`Adams` / `陈明`(chen) / `Zhao`），而不是「中文组在前」。这是*偏离国标*的逃生舱（§9.3.2 要求
    先按文种集中），给要对齐 CSL 与国际惯例的用户——CSL 1.0.2 没有文种分组能力。])
#let cs = (<lg-zh>, <lg-en>, <lg-ja>, <lg-ko>, <lg-ru>, <lg-fr>, <lg-de>)
// 「不分组」与「某个文种顺序」在多数语料下输出相同，要靠中文拼音落在两个西文姓名*之间*才区分得开。
#let mix = bytes("@book{m-adams, author={Adams, Alice}, title={A book}, address={NY}, publisher={P}, year={2019}, langid={english}}
@book{m-chen, author={陈明}, title={中文丙}, address={北京}, publisher={社}, year={2021}, langid={chinese}}
@book{m-zhao, author={Zhao, Zed}, title={Z book}, address={NY}, publisher={P}, year={2022}, langid={english}}")
#let mixcs = (<m-adams>, <m-chen>, <m-zhao>)
#case("缺省 (zh, ja, ko, en, fr, ru)", gb7714.with(style: "author-date"), bib: LANG, cites: cs, full: false)
#case(`("en", "zh")`.text + "（西文先、中文后，其余语种随后）", gb7714.with(style: "author-date", entry-lang-order: ("en", "zh")), bib: LANG, cites: cs, full: false)
#case(`("ru", "fr", "de", "en", "ko", "ja", "zh")`.text + "（整个翻过来）", gb7714.with(style: "author-date", entry-lang-order: ("ru", "fr", "de", "en", "ko", "ja", "zh")), bib: LANG, cites: cs, full: false)
#case("顺序编码制：按引用先后，不分组", gb7714.with(entry-lang-order: ("en", "zh")), bib: LANG, cites: cs, full: false)
#case("缺省 · 中文组在前（陈明 → Adams → Zhao）", gb7714.with(style: "author-date"), bib: mix, cites: mixcs, full: false)
#case("`()` = 不分组 · 一趟全局字顺（Adams → 陈明 chen → Zhao）", gb7714.with(style: "author-date", entry-lang-order: ()), bib: mix, cites: mixcs, full: false)
#case(`("en", "zh")`.text + " · 西文组在前（Adams → Zhao → 陈明）—— 与 `()` 语义不同", gb7714.with(style: "author-date", entry-lang-order: ("en", "zh")), bib: mix, cites: mixcs, full: false)
