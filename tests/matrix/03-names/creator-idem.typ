//! param: creator-idem
//! values: none, string
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "creator-idem", controls: "文献表里*紧邻*的同责任者条目，责任者槽整块替换成给定串。",
  expect: [`none`（缺省）：每条都印全责任者。传字符串：与*上一条*责任者相同的条目，责任者槽换成该串
    （CSL 的 `subsequent-author-substitute`）。判据只看*名单*、不看来源角色（与 biblatex 的 fullhash 同义），
    名单为空的条目不参与。语料里 `Smith, John` 与 `Smith, Jane` 姓同名不同 → *不*折叠（名册键含名）。逐表可用 `bibliography(creator-idem: ..)` 覆盖。])
#let cs = (<nm-same-a>, <nm-same-b>, <nm-samename-a>, <nm-samename-b>)
#case("none（缺省）", gb7714.with(style: "author-date"), bib: EDGE, cites: cs, full: false)
#case(`"———"`.text, gb7714.with(style: "author-date", creator-idem: "———"), bib: EDGE, cites: cs, full: false)
#case(`"--"`.text, gb7714.with(style: "author-date", creator-idem: "--"), bib: EDGE, cites: cs, full: false)
#case("顺序编码制下同样生效", gb7714.with(creator-idem: "———"), bib: EDGE, cites: cs, full: false)
#case("逐表覆盖：全局 none，本表 「———」", gb7714.with(style: "author-date"), bib: EDGE, cites: cs, full: false,
  bib-args: (creator-idem: "———"))
