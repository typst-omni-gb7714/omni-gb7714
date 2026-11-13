// 编号列几何不变量：每一条的编号左缘必须落在同一条竖线上。
//
// `number-width: auto` 曾只量*末号*的宽，默认它最宽。可 Times 有「11」这对字距（kern pair）：
// `［11］` 反而比 `［10］` 窄 0.45pt，列宽按末号定就塞不下 `［10］`，Typst 把行首全角括号的可压缩半格
// 压掉来凑，那一条独自左探半格。11 条以上、末号含「1」（11、21、111…）就会露出来。
// 修法是逐号测量取最宽。本文件 11 条、全角括号、Times，正好卡在那个坑上。
#import "/lib.typ": gb7714, bibliography
#set page(width: 300pt, height: auto, margin: 20pt)
#set text(font: ("Times New Roman", "SimSun"), size: 12pt)
#show: gb7714.with(bib-numbering-style: "fullwidth-bracket")
#bibliography(bytes(range(1, 12).map(i => "@book{k" + str(i) + ", author={Author " + str(i) + "}, title={T" + str(i) + "}, publisher={P}, address={X}, year={2020}, langid={english}}").join("\n")), title: none, full: true)
