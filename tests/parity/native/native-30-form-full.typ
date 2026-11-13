#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// 原生基准：`#cite(<k>, form: "full")` = 原位完整著录条目（Typst cite.rs CitationForm::Full
// 「Mimics a bibliography entry, with full information」）。顺序编码制出 `[1] 著录`，条目在正文原位再现，
// 文献表照样保留。不是脚注。
// ⚠️语料刻意用**两个**责任者：这是唯一能分辨「form:"full" 取文献表侧还是引用侧 et-al 阈值」的临界值
//   （缺省 bib-et-al-min=4 → 2<4 不截断、出全名；cite-et-al-min=2 → 2>=2 会截成「ALPHA A, et al」）。
//   单责任者时两侧结果相同，对这一点是**空证**。实测原生出全名 → form:"full" 用文献表侧阈值，与
//   「Mimics a bibliography entry」一致（biblatex 的 \fullcite 相反，吃 maxcitenames，那是它自己的
//   语境规则、非本包对齐目标）。别把语料简化回一个责任者。
前 #cite(<k>, form: "full") 后
#bibliography(bytes("@book{k, author={Alpha, A and Bravo, B}, title={书名}, publisher={社}, year={2020}}"), title: none, style: "gb-7714-2015-numeric")
