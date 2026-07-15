//! combo: cite-footnote × footnote-repeat-style × footnote-ibid × footnote-repeat-reset × cite-merge
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：脚注制的梯子", controls: "重复引用的四个参数交叉出各家有据体例。",
  expect: [首次恒完整著录。之后两参正交：
    `footnote-ibid`（*紧邻*位）× `footnote-repeat-style`（*隔开*位）。
    - `true` × `"number"` = 官方 note CSL 的梯子（缺省）：同上 → 同③；
    - `false` × `"full"` = GB §9.2.1.3 纯重复著录；
    - `false` × `"shortened"` = Chicago 17th 全缩略；
    - `true` × `"full"` = 紧邻同上、隔开重著。
    `footnote-repeat-reset` 加一道界：界后首引*重新完整著录*，「同③」只在本域找注号。
    `cite-merge` 决定相邻引用是否合成*一个*脚注。
    ⚠️ `"reuse"` 不发新注（正文复用首注号），*装不下页码*，且不受重置界影响。])
#let ladder = [首 #cite(<bm-zh>) 邻 #cite(<bm-zh>) 换 #cite(<bm-en>) 隔 #cite(<bm-zh>) 页码 #cite(<bm-zh>, supplement: [88])。]
#let chapters = [
  == 甲章
  首 #cite(<bm-zh>) 邻 #cite(<bm-zh>)。
  == 乙章
  又引 #cite(<bm-zh>)。
]
#case("ibid: true × repeat: number（官方 note CSL，缺省）", gb7714.with(cite-footnote: true), full: false, body: ladder)
#case("ibid: false × repeat: full（GB 纯重复著录）", gb7714.with(cite-footnote: true, footnote-ibid: false, footnote-repeat-style: "full"), full: false, body: ladder)
#case("ibid: false × repeat: shortened（Chicago 17th）", gb7714.with(cite-footnote: true, footnote-ibid: false, footnote-repeat-style: "shortened"), full: false, body: ladder)
#case("ibid: true × repeat: full（紧邻同上、隔开重著）", gb7714.with(cite-footnote: true, footnote-repeat-style: "full"), full: false, body: ladder)
#case("ibid: true × repeat: shortened", gb7714.with(cite-footnote: true, footnote-repeat-style: "shortened"), full: false, body: ladder)
#case("repeat: reuse（不发新注、装不下页码）", gb7714.with(cite-footnote: true, footnote-repeat-style: "reuse"), full: false, body: ladder)
#case("+ 章界（界后重新完整著录）", gb7714.with(cite-footnote: true, footnote-repeat-reset: heading.where(level: 2)), full: false, body: chapters)
#case("+ 章界 × repeat: reuse（复用不受界影响）", gb7714.with(cite-footnote: true, footnote-repeat-style: "reuse", footnote-repeat-reset: heading.where(level: 2)), full: false, body: chapters)
#case("cite-merge: true（相邻引用合成一个脚注）", gb7714.with(cite-footnote: true), full: false,
  body: [合注 #cite(<bm-zh>)#cite(<bm-en>) 再引 #cite(<bm-zh>)。])
#case("cite-merge: false（各发各的脚注）", gb7714.with(cite-footnote: true, cite-merge: false), full: false,
  body: [分注 #cite(<bm-zh>)#cite(<bm-en>) 再引 #cite(<bm-zh>)。])
