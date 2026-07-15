//! param: cite(footnote-related-indent / footnote-punct-style / footnote-custom-punct / footnote-url-break-every)
//! values: 脚注专属四参（仅 footnote: true 时生效）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite 的脚注专属四参", controls: "只在 `footnote: true` 时生效的四个参数。",
  expect: [- `footnote-related-indent`：脚注里双语关联条目第二行的缩进；`auto` 与首行首字对齐（实测注号前缀宽）；
    - `footnote-punct-style`：脚注*注文*的标点风格（与正文标注的 `punct-style` 分开——注文是著录，不是标注）；
    - `footnote-custom-punct`：脚注注文的标点覆写；
    - `footnote-url-break-every`：脚注注文里 URL 的断点密度。
    这四个都是 `auto` 继承全局对应项。`cite()` 的 `custom-drivers` / `custom-terms` / `custom-fields` /
    `custom-pids` / `show-pid` / `pid-priority` / `dedup-url-pid` / `show-annotation` *也都只在 `footnote: true` 时生效*
    （正文标注里没有著录可言）。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#case("footnote-related-indent: auto（缺省）", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [关联条目 #cite(<rel-zh>)。])
#case("footnote-related-indent: 0pt", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [关联条目 #cite(<rel-zh>, footnote-related-indent: 0pt)。])
#case("footnote-punct-style: \"half-with-space\"（注文半角，正文标注不变）", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [注文半角 #cite(<bm-zh>, footnote-punct-style: "half-with-space")。])
#case("footnote-custom-punct: (\",\": \" ### \")", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [覆写注文标点 #cite(<bm-zh>, footnote-custom-punct: (",": " ### "))。])
#case("footnote-url-break-every: none", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [长 URL #cite(<bm-online>, footnote-url-break-every: none)。])
#case("footnote 专属：custom-drivers 只在脚注生效", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [模板注 #cite(<bm-zh>, custom-drivers: (book: "{【注文模板】} author . title"))。])
#case("footnote 专属：show-annotation 只在脚注生效", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [带注释 #cite(<an-a>, show-annotation: true)。])
