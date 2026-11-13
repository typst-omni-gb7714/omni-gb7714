#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// 原生 std.bibliography（gb-7714-2015-author-date）· 多表 · 著者-出版年制年份消歧作用域基准。
// 实测原生：消歧**按表**——每张 bibliography 只在自己路由到的条目内分 a/b。
//   表一 Alpha 同年对 → 2020a / 2020b；表二 Beta 同年对 → 2021a / 2021b。
// ⭐a1 同时被两表引用：表一里是同年对（2020a），表二里唯一 Alpha 2020（无后缀 → `2020`）。
//   同一 key 两表后缀不同，各随各表。omni 侧须逐条对齐（见 ours-27）。
表一 @a1 @a2 。
#bibliography(bytes("@book{a1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{a2, author={Alpha, A}, title={T2}, publisher={P}, year={2020}}
@book{b1, author={Beta, B}, title={T3}, publisher={Q}, year={2021}}
@book{b2, author={Beta, B}, title={T4}, publisher={Q}, year={2021}}"), title: none, style: "gb-7714-2015-author-date")
表二 @a1 @b1 @b2 。
#bibliography(bytes("@book{a1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{a2, author={Alpha, A}, title={T2}, publisher={P}, year={2020}}
@book{b1, author={Beta, B}, title={T3}, publisher={Q}, year={2021}}
@book{b2, author={Beta, B}, title={T4}, publisher={Q}, year={2021}}"), title: none, style: "gb-7714-2015-author-date")
