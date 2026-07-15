//! param: custom-drivers（别名链 A | B）
//! values: token|token, 串接三段, 组作操作数, 守卫组作操作数, 与守卫互不相干
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 别名链", controls: "`A | B`：A 非空出 A，否则出 B。",
  expect: [可串接成 `A | B | C`（左结合，逐个回退到*首个非空*）。
    两侧操作数都可以是*单个 token / 字面量*，也可以是*整个组*——条件组 `?<…>` / `&<…>` 与
    守卫组 `<… => …>` 都行，所以回退候选放哪边都成。
    `|` 与 `=>` *互不相干*：别名走 body 侧的取值回退，守卫走谓词判断。
    语料：`bm-zh` 有 edition 无 note；`ti-notitle` 无 title 有 author；`aj-en` 有 volume / number。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let one(name, tpl) = case(name, gb7714.with(custom-drivers: (book: tpl, article: tpl)),
  cites: (<bm-zh>, <ti-notitle>, <aj-en>), bib: mixed, full: false)
#one("token | token：note | edition", "author . title . note | edition")
#one("三段串接：note | keywords | edition", "author . title . note | keywords | edition")
#one("全空 → 整段消失：note | keywords", "author . title . note | keywords . year")
#one("题名兜底：title | subtitle | {（无题名）}", "author . title | subtitle | {（无题名）} . year")
#one("组回退到 token：?<{副：} subtitle> | title", "author . ?<{副：} subtitle> | title . year")
#one("token 回退到组：title | ?<{副：} subtitle>", "author . title | ?<{副：} subtitle> . year")
#one("组回退到组：?<{甲：} subtitle> | ?<{乙：} note>", "author . title . ?<{甲：} subtitle> | ?<{乙：} note> . year")
#one("回退到守卫组：note | <mark=M => {（图书兜底）}>", "author . title . note | <mark=M => {（图书兜底）}> . year")
#one("守卫组在前：<mark=J => volume> | edition", "author . title . <mark=J => volume> | edition . year")
#one("别名与守卫叠用：<mark=M => note | edition>", "author . title . <mark=M => note | edition> . year")
#one("&< 组作操作数：&<volume ( number )> | edition", "author . title . &<volume ( number )> | edition . year")
