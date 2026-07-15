//! param: cite-terms-lang
//! values: by-entry, by-doc, zh, ja, ko, ru, en, fr, de, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-terms-lang", controls: "*cite 侧*（正文标注与脚注标注）术语的语言来源。管 5 个词：`et-al`、`anon`、`no-date`、`ibid`、`footnote-number`。",
  expect: [缺省 `"by-entry"`：跟*被引条目*语言——GB/T 7714 §9.3.1.2 明写「欧美第一责任者姓 + et al.，
    中国第一责任者姓名 + 等」，按*著者*语种。`"by-doc"` 跟文档语言（= citeproc 的实际行为）。
    也可强制具体语种，或给*按 term 项展开的字典*逐词分设。
    *著录侧没有这个轴*——文献表里的术语恒跟条目语言，不给开关。
    本用例文档语言为中文，条目有中英日俄——差别应当可见。])
#let cs = (<lg-zh>, <lg-en>, <lg-ja>, <lg-noauthor-en>, <lg-noyear-en>)
#case("by-entry（缺省）", gb7714.with(style: "author-date", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs, full: false)
#case("by-doc", gb7714.with(style: "author-date", cite-terms-lang: "by-doc", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs, full: false)
#cite-only("强制 zh", gb7714.with(style: "author-date", cite-terms-lang: "zh", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#cite-only("强制 ja", gb7714.with(style: "author-date", cite-terms-lang: "ja", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#cite-only("强制 ko", gb7714.with(style: "author-date", cite-terms-lang: "ko", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#cite-only("强制 ru", gb7714.with(style: "author-date", cite-terms-lang: "ru", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#cite-only("强制 en", gb7714.with(style: "author-date", cite-terms-lang: "en", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#cite-only("强制 fr", gb7714.with(style: "author-date", cite-terms-lang: "fr", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#cite-only("强制 de", gb7714.with(style: "author-date", cite-terms-lang: "de", cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#cite-only("字典 · (et-al: by-doc)——只让截断词跟文档语言", gb7714.with(style: "author-date", cite-terms-lang: (et-al: "by-doc"), cite-et-al-min: 2, cite-et-al-use-first: 1), bib: LANG, cites: cs)
#case("字典 · (ibid: by-doc)——只让脚注引语词跟文档语言", gb7714.with(cite-footnote: true, cite-terms-lang: (ibid: "by-doc")), bib: LANG, full: false,
  body: [首 #cite(<lg-en>) 邻 #cite(<lg-en>) 换 #cite(<lg-zh>) 隔 #cite(<lg-en>)。])
