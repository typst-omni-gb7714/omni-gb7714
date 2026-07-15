//! param: footnote-repeat-reset
//! values: none, selector
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "footnote-repeat-reset", controls: "重复判定的*重置界*（biblatex `citereset` 的对应物）。",
  expect: [`none`（缺省）：全文一个域。
    传 selector：selector 的每个匹配处都是一道界，重复判定只认*最近一道界之后*的引用——
    界之后的首次引用重新*完整著录*，「同③」只在本域内找注号。
    典型值：`heading.where(level: 1)`（章界）、任意标签（正文写 `#[]<part-break>` 手工插界）、
    元素函数（`heading` 任意级都切）、`.or()` 组合。
    只管*判定*，不动脚注编号——每章重编号是文档排版自己的事，
    但*每章重编号的文档必须同设本参数*，否则「同③」会跨章指向上一章的注号。
    `"reuse"` 复用的是全局首注（原生标签只有一处），*不受本参数影响*。])
#let two-sections = [
  == 甲章
  首 #cite(<bm-zh>) 邻 #cite(<bm-zh>)。
  == 乙章
  又引 #cite(<bm-zh>)。
]
#let with-label = [
  首 #cite(<bm-zh>) 邻 #cite(<bm-zh>)。
  #[]<part-break>
  界后 #cite(<bm-zh>)。
]
#case("none（缺省，全文一个域 → 乙章那次是「同①」）", gb7714.with(cite-footnote: true), full: false, body: two-sections)
#case("heading.where(level: 2)（章界 → 乙章重新完整著录）", gb7714.with(cite-footnote: true, footnote-repeat-reset: heading.where(level: 2)), full: false, body: two-sections)
#case("heading（任意级标题都切）", gb7714.with(cite-footnote: true, footnote-repeat-reset: heading), full: false, body: two-sections)
#case("标签 <part-break>（手工插界）", gb7714.with(cite-footnote: true, footnote-repeat-reset: <part-break>), full: false, body: with-label)
#case("none · 同一正文的对照（界不生效）", gb7714.with(cite-footnote: true), full: false, body: with-label)
#case("footnote-repeat-style: reuse + 章界（复用不受界影响）", gb7714.with(cite-footnote: true, footnote-repeat-style: "reuse", footnote-repeat-reset: heading.where(level: 2)), full: false, body: two-sections)
