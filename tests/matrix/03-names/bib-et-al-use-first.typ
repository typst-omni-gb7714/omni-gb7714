//! param: bib-et-al-use-first
//! values: 0, 1, 3, 角色档
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-et-al-use-first", controls: "文献表截断后保留前 N 位责任者。",
  expect: [缺省 `3`（GB §7.1.2「录前 3 加，等」）。`0` 是合法值——只出截断词、*不留孤儿分隔符*
    （官方 GB CSL 设 `et-al-use-first="0"` 实测输出裸「等」）。
    也作用于其他责任者（编者、译者）与其角色词的接缝。

    末档证明本参数与 `bib-et-al-min` *同收三档取值*（整数 / 语言档 / 角色档，可两轴叠加）：
    `(principal: 1, host: 2, translator: 3, rest: 3)` 让同一条目里主责任者只留 1 位、母体责任者留 2 位、
    译者留 3 位——「留几位」和「何时截」两个参数各自都能按位置分设。])
#let cs = (<bm-zh>, <bm-en>, <nm-editor-only>, <nm-translator>)
#case("0（只出截断词，无孤儿分隔符）", gb7714.with(bib-et-al-min: 2, bib-et-al-use-first: 0), bib: EDGE, cites: (<nm-others>, <nm-editor-only>, <nm-translator>), full: false)
#case("1", gb7714.with(bib-et-al-min: 2, bib-et-al-use-first: 1), bib: EDGE, cites: (<nm-others>, <nm-editor-only>, <nm-translator>), full: false)
#case("3（缺省）", gb7714.with(), cites: cs, full: false, bib: MAIN)
#case("角色档 (principal: 1, host: 2, translator: 3, rest: 3)：同条目内三个位置各留不同位数",
  gb7714.with(bib-et-al-min: 2, bib-et-al-use-first: (principal: 1, host: 2, translator: 3, rest: 3)),
  bib: ROLES, cites: (<rl-part-en>,), full: false)
