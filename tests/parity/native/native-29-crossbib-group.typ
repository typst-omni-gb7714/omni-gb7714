#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// 原生基准：一个*相邻 cite 组*跨两张不同表（`@a`→表一 author-date、`@b`→表二 numeric）。
// Typst 的 Works::generate 把 CiteGroup 按归属 bib 拆成 subgroup、各自渲染、组间拼接（cite.rs CiteGroup 注释）。
// 结果：`@a @b` → `(Alpha, 2020)`（AD）紧接 `[1]`（numeric），各随所属表的样式。
引 @a @b 。
表一 #bibliography(bytes("@book{a, author={Alpha, A}, title={AA}, year={2020}}"), title: none, style: "gb-7714-2015-author-date")
表二 #bibliography(bytes("@book{b, author={Beta, B}, title={BB}, year={2021}}"), title: none, style: "gb-7714-2015-numeric")
