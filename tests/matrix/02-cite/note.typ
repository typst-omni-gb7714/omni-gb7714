//! param: note
//! values: none, "foot"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "note", controls: "注模式：引用是否走脚注制（完整著录落在脚注里，正文只留注号）。",
  expect: [`"foot"`：正文出圈码注号，脚注里给出完整著录；首次全著录，紧邻重复「同上」，隔开重复「同③」
    （官方 note CSL 的梯子）。相邻引用合成*一个*脚注。`none`（缺省）：常规行内标注。
    脚注里的引语词（同上 / Ibid.）按*被引条目*语言取。
    markup `@key` 与函数 `#cite()` 两种写法入脚注*完全一致*——两者在正文是分开的渲染路径
    （markup 走 `show ref`、函数走 `cite` 闭包），下面并列出来正是要让 golden 盯住它们同源。])
#case("none（缺省，行内）", gb7714.with(), cites: (<bm-zh>, <bm-en>), full: false)
#case("\"foot\" · 首次 + 紧邻重复 + 隔开重复", gb7714.with(note: "foot"), full: false,
  body: [首 #cite(<bm-zh>) 邻 #cite(<bm-zh>) 换 #cite(<bm-en>) 隔 #cite(<bm-zh>)。])
#case("\"foot\" · 相邻引用合成一个脚注", gb7714.with(note: "foot"), full: false,
  body: [合注 #cite(<bm-zh>)#cite(<bm-en>)。])
#case("\"foot\" · 西文条目的引语词（Ibid. / See note）", gb7714.with(note: "foot"), full: false,
  body: [首 #cite(<bm-en>) 邻 #cite(<bm-en>) 换 #cite(<bm-zh>) 隔 #cite(<bm-en>)。])
// markup `@key`（非 `#cite()`）在全局注模式下的入脚注路径：走 `show ref` 拦截而非 `cite` 闭包。
//   这条路径曾因 `gb-footnote` 误写成 `== "foot"` 的 bool、把默认 numeric 样式钉成 `false`
//   而不进脚注（parity 的 ours-15-note 抓到，但 matrix 早先全用 `#cite()` 漏了）。补两条盯住它。
#case("\"foot\" · markup @key 入脚注（默认 numeric 样式 + 全局 note 参数，曾漏渲的路径）", gb7714.with(note: "foot"), full: false,
  body: [markup @bm-zh 与函数 #cite(<bm-en>) 都落到脚注，正文只留注号。])
#case("\"foot\" · markup @key 与 #cite() 共享注号 / 重复空间（重复位指回前面 #cite 建的首注）", gb7714.with(note: "foot"), full: false,
  body: [首 @bm-zh 邻 @bm-zh 换 @bm-en 隔 @bm-zh。])
