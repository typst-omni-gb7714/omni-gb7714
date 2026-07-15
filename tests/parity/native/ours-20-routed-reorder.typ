// P-A 回归守卫：文档序 ≠ 路由号（num↔seen 对齐）。
// @p1@p2 文档序在前但 within(<sec>) 路由到第二个（副）表 → 高号 [3-4]；
// @a@b 文档序在后但落 auto 主表 → 低号 [1-2]。若 num↔seen 错配（取全局文档序 key），
// 副表 [3] 会错链/错列成主表条目；route-seen 修对后 [3] 必为 Paper One。
#import "/lib.typ": *
#show: gb7714(version: 2015, )
#[早 @p1 @p2] <sec>
晚 @a @b
#bibliography("@book{a, author={Alpha, A}, title={Book A}, publisher={P}, year={2020}}\n@book{b, author={Beta, B}, title={Book B}, publisher={Q}, year={2021}}", title: "主表")
#bibliography("@book{p1, author={Pone, P}, title={Paper One}, publisher={R}, year={2022}}\n@book{p2, author={Ptwo, P}, title={Paper Two}, publisher={S}, year={2023}}", title: "副表", target: selector(std.cite).within(<sec>))
