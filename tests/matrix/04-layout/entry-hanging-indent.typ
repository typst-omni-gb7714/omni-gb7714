//! param: entry-hanging-indent
//! values: auto, length
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "entry-hanging-indent", controls: "条目回行的悬挂缩进。",
  expect: [它是条目正文那一段的**段落量**（与原生 `par(hanging-indent:)` 同名同义），量的是
    「余行相对*正文块*左缘」——**不是**「距版心左缘的绝对位置」。**四种版式下都生效。**
    `auto`：著者-出版年制 `1.5em`（对齐官方 CSL 的 `hanging-indent="true"`）；顺序编码制 `0pt`
    ——官方 numeric CSL 根本没有这个属性，它那个「余行贴正文列」的效果全部来自
    `second-field-align="flush"` 的**编号列**，与本量无关。
    所以成列档（`"column"` / `"margin"`）下，正文列本身就是那一段，本量相对*正文列左缘*再缩。
    ⚠️「余行顶格」不归本参数管——那是「编号不占一列」，用 `number-placement: "inline"`。
    本量刻意*不*与编号列宽挂钩：编号列宽随条目数变（`[9]` 涨到 `[120]` 宽出 1.4em），
    若本量是「距版心左缘的绝对值」，用户写死的数随时可能小于编号列宽，余行就倒插到首行文字左边
    ——加减几条参考文献就能把版式弄崩。段落量与编号列宽解耦，才没有这种耦合病。
    与 `entry-first-line-indent` *正交*、同一坐标系，可同时生效。])
#let cs = (<ic-zh>, <aj-en>)
#case("auto · 顺序编码制（= 编号列宽 + gutter）", gb7714.with(), cites: cs, full: false)
#case("auto · 著者-出版年制（= 2em）", gb7714.with(style: "author-date"), cites: cs, full: false)
#case("0pt · 成列档（= auto 的顺序编码制派生值 → 余行贴正文列）", gb7714.with(entry-hanging-indent: 0pt), cites: cs, full: false)
#case("4em · 成列档（正文列左缘基础上再缩 4em）", gb7714.with(entry-hanging-indent: 4em), cites: cs, full: false)
#case("4em · number-placement: margin", gb7714.with(entry-hanging-indent: 4em, number-placement: "margin"), cites: cs, full: false)
#case("4em · number-placement: inline（编号不占列 → 余行顶格由此档给）", gb7714.with(entry-hanging-indent: 4em, number-placement: "inline"), cites: cs, full: false)
#case("0pt · number-placement: inline（回行顶格）", gb7714.with(entry-hanging-indent: 0pt, number-placement: "inline"), cites: cs, full: false)
#case("两量同时生效：hanging 4em + first-line 2em（成列档）", gb7714.with(entry-hanging-indent: 4em, entry-first-line-indent: 2em), cites: cs, full: false)
#case("number-width 3em + hanging 4em（成列档：与编号列宽解耦，余行 = 正文列 + 4em）", gb7714.with(number-width: 3em, entry-hanging-indent: 4em), cites: cs, full: false)
#case("4em · 著者-出版年制", gb7714.with(style: "author-date", entry-hanging-indent: 4em), cites: cs, full: false)
