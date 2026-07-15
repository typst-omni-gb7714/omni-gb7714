//! param: bibliography(source)
//! values: str, bytes, 数组
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bibliography(source)", controls: "bib 数据源。",
  expect: [收 `read("refs.bib")` 的结果（`str` 或 `bytes`），或它们的*数组*（多份 `.bib` 合并）。
    ⚠️ 一篇文档只有*一套* bib 数据——`gb7714()` 把全文所有 `bibliography()` 的源拼起来*一次*解析。
    因此两份含*相同 key* 的语料同处一文档会报 `duplicate key`。
    ⚠️ `.bib` 必须用 `read()` 读进来：Typst 的字符串字面量词法器会吃掉 `\t` 一类转义
    （直接内联 `"\\textbackslash"` 会损坏）。])
#case("bytes（read 的结果）", gb7714.with(), cites: (<bm-zh>,), full: false)
#case("str（read 不转 bytes）", gb7714.with(),
  bib: read("/tests/_fixture/latex.bib"), full: true)
#case("数组：两份 .bib 合并", gb7714.with(),
  bib: (read("/tests/_fixture/lang.bib"), read("/tests/_fixture/types.bib")), full: true)
