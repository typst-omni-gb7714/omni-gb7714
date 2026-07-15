//! param: number-placement
//! values: "column", "margin", "inline"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "number-placement", controls: "编号*放哪*。",
  expect: [`"column"`（缺省）：编号自成一列贴版心左缘，正文另起一列，余行贴正文列——
    对齐官方 GB CSL 的 `second-field-align="flush"`（两制官方样式都用它）。
    `"margin"`：编号挂到版心*外*，正文与余行都贴版心左缘——对齐 CSL 的 `second-field-align="margin"`
    （原生 typst 未实现该值，渲染同 flush；本包实现之）。
    `"inline"`：编号排在行内、不成列，余行与首行改由 `entry-hanging-indent` /
    `entry-first-line-indent` 决定。`number-width` / `number-align` / `number-gutter` 只在成列两档有意义。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>, <ic-zh>)
#case(`"column"`.text + "（缺省）", gb7714.with(), cites: cs, full: false)
#case(`"margin"`.text, gb7714.with(number-placement: "margin"), cites: cs, full: false)
#case(`"inline"`.text, gb7714.with(number-placement: "inline"), cites: cs, full: false)
#case(`"inline"`.text + " · entry-hanging-indent: 0pt（余行顶格）", gb7714.with(number-placement: "inline", entry-hanging-indent: 0pt), cites: cs, full: false)
#case(`"inline"`.text + " · entry-first-line-indent: 2em", gb7714.with(number-placement: "inline", entry-first-line-indent: 2em), cites: cs, full: false)
