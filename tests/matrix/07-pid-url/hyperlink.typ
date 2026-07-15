//! param: hyperlink
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "hyperlink", controls: "获取路径与标识符是否渲染成可点击超链接。",
  expect: [`true`（缺省）：`url`（链到自身）、DOI（doi.org）、CSTR（cstr.cn）、
    `eprint`（按 `archiveprefix` 链到 arXiv / PubMed / ChinaXiv 摘要页），以及 `custom-terms` 里 `pid: true`
    的自定义标识符（值为 URL 则链到自身，或经 `resolver` 模板合成目标）都可点击。
    *ISBN / ISSN 无公认解析器，恒为纯文本*。`false`：全部渲染为纯文本。
    ⚠️ 超链接是 PDF 的注解层，*抽出来的文本一模一样*——本用例两档的 golden 相同，
    差异要开 PDF 点一下才看得见（链接目标由 `contract/` 的 PDF 注解检查兜底）。])
#let cs = (<pid-all>, <pid-eprint>, <pid-isbn>, <bm-online>)
#let m = bytes(read("/tests/_fixture/main.bib")) + bytes(read("/tests/_fixture/edge.bib"))
#case("true（缺省）", gb7714.with(show-pid: (rest: true, doi: true)), bib: m, cites: cs, full: false)
#case("false（纯文本）", gb7714.with(show-pid: (rest: true, doi: true), hyperlink: false), bib: m, cites: cs, full: false)
