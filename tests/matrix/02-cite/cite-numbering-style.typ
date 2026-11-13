//! param: cite-numbering-style
//! values: bracket, paren, fullwidth-bracket, fullwidth-paren, shell, circled
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-numbering-style", controls: "正文标注编号的括号形态。与 bib-numbering-style 分属两轴：那个管文献表那列的编号，本参数管正文里的 [1]。",
  expect: [默认 `bracket`（[1]，GB 正文标准）；`paren`（(1)）；`fullwidth-bracket`（［1］，全角方括号）；`fullwidth-paren`（（1））；`shell`（〔1〕，六角括号，旧 GB-1987 体例）。
    前五个是括号对，只作用于顺序编码制正文标注，不动文献表那列的编号；连号 / 合引也套同一括号（`［1-2］`）。
    `circled`（①）是圈码上标：不套括号、也不与范围 `[1-3]` / 合并 `[1,2]` 组合，逐条各出一枚（合引 `#cite(<a>,<b>)` 得 `①②`）；绘制引擎值内二级展开同 `bib-numbering-style`（标量 Unicode、`(circled: "quan")` 用 quan 包）。配 `bib-numbering-style: "circled"` 得「正文上标 ① + 文末圈码列表」的尾注观感。])
#let probe-cites = [首引 #cite(<bm-zh>)，再引 #cite(<aj-zh>)，合引 #cite(<bm-zh>, <aj-zh>)。]
#cite-only("bracket（默认）", gb7714.with(), body: probe-cites)
#cite-only("paren", gb7714.with(cite-numbering-style: "paren"), body: probe-cites)
#cite-only("fullwidth-bracket", gb7714.with(cite-numbering-style: "fullwidth-bracket"), body: probe-cites)
#cite-only("fullwidth-paren", gb7714.with(cite-numbering-style: "fullwidth-paren"), body: probe-cites)
#cite-only("shell", gb7714.with(cite-numbering-style: "shell"), body: probe-cites)
#cite-only("circled（① 上标·合引不并 → ①②）", gb7714.with(cite-numbering-style: "circled"), body: probe-cites)
#cite-only("circled + quan 引擎（字典 (circled: \"quan\")）", gb7714.with(cite-numbering-style: (circled: "quan")), body: probe-cites)
