//! param: custom-drivers（表达式守卫与组外字面量）
//! values: 空守卫首尾, 连续空守卫, 句点顺序, 析出符, 真守卫, otherwise, 嵌套, 普通空字段对照
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 守卫与字面量", controls: "空的表达式守卫只省略自身，不吞掉紧邻的组外 verbatim。",
  expect: [题名后的 `[S]` 在出版者缺失时仍保留；字面量与句点保持模板中的先后顺序，析出符前也不丢文字。
    假分支的内部文字不输出。普通空字段和按内容判空的组仍省略其前导字面量；全部数据为空时不凭字面量产生内容。])
#let bib = bytes("@standard{guard-standard,number={GB/T 16159-1996},title={Test standard title}}
@book{guard-empty,title={Book},alpha={A},gamma={C},langid={english}}
@book{guard-present,title={Book},alpha={A},beta={B},gamma={C},langid={english}}
@book{guard-component,title={Book},alpha={A},gamma={//G},langid={english}}")
#let one(name, tpl, key: <guard-empty>) = case(name,
  gb7714.with(custom-fields: (alpha: auto, beta: auto, gamma: auto, nop: auto),
    custom-drivers: (book: tpl, standard: tpl), bib-punct-style: "half-with-space", show-end-period: false),
  cites: (key,), bib: bib, full: false)
#one("issue 16 · 缺出版者的标准保留 [S]", "number ,title {[S]} <publisher => .location :publisher ,year> .", key: <guard-standard>)
#one("末尾空守卫 · A [X]", "alpha {[X]} <beta => beta>")
#one("字面量后仍有句点 · A [S].", "alpha {[S]} <beta => beta> .")
#one("连续空守卫 · A [X] C", "alpha {[X]} <beta => beta> <nop => nop> gamma")
#one("句点在字面量前 · A. [X] C", "alpha . {[X]} <beta => beta> gamma")
#one("字面量位于句点两侧 · A [L]. [R] C", "alpha {[L]} . {[R]} <beta => beta> gamma")
#one("析出符不吞掉字面量 · A [S]//G", "alpha {[S]} <beta => beta> gamma", key: <guard-component>)
#one("守卫右侧的字面量 · A. [X] C", "alpha . <beta => beta> {[X]} gamma")
#one("守卫为真 · A [X] B C", "alpha {[X]} <beta => beta> gamma", key: <guard-present>)
#one("守卫为假时组内文字不出 · A C", "alpha <beta => {[NO]} beta> gamma")
#one("otherwise 被抑制 · A [X] C", "alpha {[X]} < => {[NO]}> <alpha => gamma>")
#one("otherwise 被采用 · A [X] C", "alpha {[X]} <beta => beta> < => gamma>")
#one("普通组内嵌守卫 · A [X] C", "<alpha {[X]} <beta => beta> gamma>")
#one("真守卫内嵌假守卫 · A [X] C", "<alpha => alpha {[X]} <beta => beta> gamma>")
#one("普通空字段仍带走冒号 · A", "alpha{：}beta")
#one("普通非空字段保留冒号 · A：B", "alpha{：}beta", key: <guard-present>)
#one("普通空组仍带走右引号 · A", "alpha{”}<{, }beta>")
#one("普通空组仍带走前导文字 · A", "alpha {[X]} <beta>")
#one("守卫不改变后继空字段规则 · A", "alpha <nop => nop> {：} beta")
#one("数据全部为空时不输出字面量", "beta {[X]} <nop => nop>")
