//! param: entry-first-line-indent
//! values: length
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "entry-first-line-indent", controls: "条目首行的额外缩进。",
  expect: [缺省 `0pt`。它是条目正文那一段的**段落量**，与原生 `par(first-line-indent:)` 同名同义，
    **四种版式下都参与**（成列档下相对*正文列左缘*再缩）。
    与 `entry-hanging-indent` *正交*、不互斥——原生 `par` 里首行在 `first-line-indent`、余行在
    `hanging-indent`，两个量各管各。
    国标原文式（首行缩进、余行顶格）：顺序编码制直接写 `entry-first-line-indent: 2em`
    （余行缩进在该制 `auto` 即 `0pt`）。])
#let cs = (<ic-zh>, <aj-en>)
#case("0pt（缺省）", gb7714.with(), cites: cs, full: false)
#case("2em", gb7714.with(entry-first-line-indent: 2em), cites: cs, full: false)
#case("2em · entry-hanging-indent: 0pt（纯段落缩进式）", gb7714.with(entry-first-line-indent: 2em, entry-hanging-indent: 0pt), cites: cs, full: false)
#case("2em · 著者-出版年制", gb7714.with(style: "author-date", entry-first-line-indent: 2em), cites: cs, full: false)
#case("2em · number-placement: margin", gb7714.with(entry-first-line-indent: 2em, number-placement: "margin"), cites: cs, full: false)
#case("2em · number-placement: inline", gb7714.with(entry-first-line-indent: 2em, number-placement: "inline"), cites: cs, full: false)
#case("国标原文式：顺序编码制直接写 first-line 2em（余行 auto 即 0pt）", gb7714.with(entry-first-line-indent: 2em, number-placement: "inline"), cites: cs, full: false)
