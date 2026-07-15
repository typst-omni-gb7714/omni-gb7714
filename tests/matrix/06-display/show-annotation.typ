//! param: show-annotation
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-annotation", controls: "条目末尾是否追加 `annotation` / `annote` 字段。",
  expect: [`false`（缺省）：忽略这两个字段。`true`：取 `annotation`（优先）或 `annote`，
    以*一个句点加空格*接在条目尾部，*不再附加其它标点*。字段内的 LaTeX 命令 / 转义按与其它字段相同的规则渲染。
    `bibliography` / `cite(footnote: true)` 接受同名参数（`auto` 继承全局）。])
#let cs = (<an-a>, <kw-a>)
#case("false（缺省）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("true", gb7714.with(show-annotation: true), bib: EDGE, cites: cs, full: false)
#case("true + end-with-period: false（尾部只有注释的句点）", gb7714.with(show-annotation: true, end-with-period: false), bib: EDGE, cites: cs, full: false)
#case("逐表覆盖：全局 false、本表 true", gb7714.with(), bib: EDGE, cites: cs, full: false, bib-args: (show-annotation: true))
