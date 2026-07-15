//! param: cite-sort-zh-by
//! values: pinyin, bihua
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-sort-zh-by", controls: "合并组内中文责任者的排序方案。",
  expect: [`pinyin`（缺省）按拼音字顺；`bihua` 按笔画笔顺（GB/T 7714 §9.3.2 允许两者）。
    语料的四个姓氏（丁 / 万 / 习 / 乔）在两种方案下次序不同——差别应当可见。])
#let zh4 = [正文 #cite(<sort-zh-1>)#cite(<sort-zh-2>)#cite(<sort-zh-3>)#cite(<sort-zh-4>)。]
#cite-only("pinyin（缺省）", gb7714.with(style: "author-date", cite-sort-by: ("name",)), bib: LANG, body: zh4)
#cite-only("bihua", gb7714.with(style: "author-date", cite-sort-by: ("name",), cite-sort-zh-by: "bihua"), bib: LANG, body: zh4)
