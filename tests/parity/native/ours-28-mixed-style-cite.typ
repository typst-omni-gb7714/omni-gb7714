#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// omni 对照 native-28：混排 author-date 表 + numeric 表，cite 继承所属表样式。
// 表甲（author-date）的 @a → `(Alpha, 2020)`；表乙（numeric）的 @b → `[1]`。
// 修复前：cite 读主列表共享的 `main-list-style`（last-write-wins），两张主表下所有 cite 都用最后一张
//   （numeric）的样式，表甲的 @a 错出 `[1]`。修复后 native 模式按 bib 实例索引存 / 取每表样式，各随各表，
//   对齐原生「cite 继承所属 bibliography 的 style」。
#import "/lib.typ": *
#show: gb7714(version: 2015)
表甲 @a
#bibliography("@book{a, author={Alpha, A}, title={AA}, year={2020}}
@book{b, author={Beta, B}, title={BB}, year={2021}}", title: none, style: "author-date")
表乙 @b
#bibliography("@book{a, author={Alpha, A}, title={AA}, year={2020}}
@book{b, author={Beta, B}, title={BB}, year={2021}}", title: none, style: "numeric")
