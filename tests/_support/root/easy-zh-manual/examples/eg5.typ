// 示例 5：中文排序——拼音序 vs 笔画序（同一批条目、两种 collation，著者-出版年制按著者名排序）。
#set page(width: 15cm, height: auto, margin: 10pt)
#set text(lang: "zh", font: "Noto Serif CJK SC", size: 9.5pt)
#import "/lib.typ": *
#let bib = bytes("
@book{a, author={{王五}}, title={甲书}, publisher={社}, date={2020}, langid={chinese}}
@book{b, author={{李四}}, title={乙书}, publisher={社}, date={2021}, langid={chinese}}
@book{c, author={{张三}}, title={丙书}, publisher={社}, date={2019}, langid={chinese}}
@book{d, author={{陈一}}, title={丁书}, publisher={社}, date={2022}, langid={chinese}}
")
*拼音序（陈 < 李 < 王 < 张）：*
#[#show: gb7714(full: true, style: "author-date", bib-sort-zh-by: "pinyin"); #bibliography(bib, title: none)]
#v(0.4em) *笔画序（王4 < 李7 < 张7 < 陈7）：*
#[#show: gb7714(full: true, style: "author-date", bib-sort-zh-by: "bihua"); #bibliography(bib, title: none)]
