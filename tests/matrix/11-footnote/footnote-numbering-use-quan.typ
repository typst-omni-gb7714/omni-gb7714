//! param: footnote-numbering-use-quan
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "footnote-numbering-use-quan", controls: "脚注编号的圈码用哪个绘制引擎。",
  expect: [应用本包即*接管脚注编号为带圈数字*（国标示例的圈码形）。
    `false`（缺省）：用 Unicode 带圈字符 ①～㊿（超过 50 退化为 `(N)`，依赖字体覆盖）。
    `true`：改由 `@preview/quan` 包*绘制*带圈数字（不受字体限制）。
    *引擎是实现不是样式*——与 `numbering-style: (circled: "quan")` 同一哲学。
    其它编号样式不设配置项：直接 `set footnote(numbering: ..)` 覆盖即可（`set` 在 `show` 之内、后设者胜）；
    「同③」的引语号*自动镜像*文档当前的脚注编号样式，任何样式都跟对。
    ⚠️ 用户没配 `quan-init` / `quan-style` 时，quan 吐的就是 Unicode 圈码 ①——
    与缺省引擎*逐字节相同*，下方两档的 golden 因此一模一样。
    它真正派上用场是在：字体缺带圈数字，或编号超过 ㊿（缺省引擎退化成 `(N)`，quan 还能画）。])
#let ladder = [首 #cite(<bm-zh>) 换 #cite(<bm-en>) 隔 #cite(<bm-zh>)。]
#case("false（缺省，Unicode ①）", gb7714.with(cite-footnote: true), full: false, body: ladder)
#case("true（quan 绘制）", gb7714.with(cite-footnote: true, footnote-numbering-use-quan: true), full: false, body: ladder)
#case("set footnote(numbering: \"1\")（自设样式 → 「同③」镜像成「同1」）", gb7714.with(cite-footnote: true), full: false,
  body: [#set footnote(numbering: "1")
    #ladder])
