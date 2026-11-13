#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// omni 对照 native-27：多表 · 著者-出版年制年份消歧**按表**，逐条对齐原生。
// 表一（Alpha 两篇同年）→ 2020a / 2020b；表二（Beta 两篇同年）→ 2021a / 2021b。
// ⭐关键：a1（Alpha 2020）*同时被两表引用*——它在表一是同年对的一员（2020a），在表二里却是唯一的
//   Alpha 2020（无同伴），所以表二里它是 `2020`（无后缀）。同一个 key 在不同表后缀不同，各随各表，
//   与该表著录逐条一致（原生实测如此）。这正是 BUGS #20 的核心：
//   - 空串共用键（最初）：靠后表把靠前表的后缀冲掉 → 表一行内丢 a/b；
//   - 合并所有表（中途 merge 版）：a1 在表二也拿表一的 2020a、与表二著录 2020 打架，还因与表一同形被去重丢掉；
//   - 按 bib 实例键、逐表取（终版）：a1 表一 2020a、表二 2020，各随各表，与原生一致。
#import "/lib.typ": *
#show: gb7714(version: 2015, style: "author-date")
表一 @a1 @a2 。
#bibliography("@book{a1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{a2, author={Alpha, A}, title={T2}, publisher={P}, year={2020}}
@book{b1, author={Beta, B}, title={T3}, publisher={Q}, year={2021}}
@book{b2, author={Beta, B}, title={T4}, publisher={Q}, year={2021}}", title: none)
表二 @a1 @b1 @b2 。
#bibliography("@book{a1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{a2, author={Alpha, A}, title={T2}, publisher={P}, year={2020}}
@book{b1, author={Beta, B}, title={T3}, publisher={Q}, year={2021}}
@book{b2, author={Beta, B}, title={T4}, publisher={Q}, year={2021}}", title: none)
