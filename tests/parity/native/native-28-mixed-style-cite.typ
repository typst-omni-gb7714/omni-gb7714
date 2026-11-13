#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// 原生基准：同一文档混排「一张 author-date 表 + 一张 numeric 表」，cite 各自继承所属表的样式。
// 实测原生（bibliography.rs：cite 无自己的 style 时用 bib.style）：表甲的 @a → `(Alpha, 2020)`（author-date），
// 表乙的 @b → `[1]`（numeric）。编号只由 numeric 表推进（author-date 表 counts-number=false）。
表甲 @a
#bibliography(bytes("@book{a, author={Alpha, A}, title={AA}, year={2020}}
@book{b, author={Beta, B}, title={BB}, year={2021}}"), title: none, style: "gb-7714-2015-author-date")
表乙 @b
#bibliography(bytes("@book{a, author={Alpha, A}, title={AA}, year={2020}}
@book{b, author={Beta, B}, title={BB}, year={2021}}"), title: none, style: "gb-7714-2015-numeric")
