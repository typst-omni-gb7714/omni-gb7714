#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// omni 对照 native-29：相邻 cite 组跨两表，按归属 bib 拆成 subgroup 各自渲染。
// `@a`（表一 author-date）→ `(Alpha, 2020)`；`@b`（表二 numeric）→ `[1]`；相邻拼接 `(Alpha, 2020)[1]`。
// 修复前：ours 整组用首项（a）的样式，@b 错渲成 `(Beta, 2021)`（该是 `[1]`）。修复后组渲染器按每项
//   携带的 bib-index 把 items 切成连续段、每段递归渲染（各随其表的样式 / 后缀），对齐 Typst 的 subgroup 拆分。
#import "/lib.typ": *
#show: gb7714(version: 2015)
引 @a @b 。
表一 #bibliography("@book{a, author={Alpha, A}, title={AA}, year={2020}}", title: none, style: "author-date")
表二 #bibliography("@book{b, author={Beta, B}, title={BB}, year={2021}}", title: none, style: "numeric")
