//! param: 局部作用域（在文档一部分里应用 gb7714）
//! values: 两个独立作用域各自配置 · 脚注开关不串味
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "局部作用域", controls: "`#[#show: gb7714(..) …]` 只影响该块。",
  expect: [`gb7714()` 是 show 规则，可以只套在文档的一部分上。两个块各自的配置*互不干扰*——
    包括 `cite-footnote`：块 1 的引用不该被块 2 的 `cite-footnote: true` 变成脚注。
    实现上这要求状态按 `here()` 位置读、而不是 `.final()` 读全局终值
    （曾经用 `.final()`，块 1 的 `@a` 被块 2 的 `true` 错误地脚注化）。
    ⚠️ 但 *bib 数据是整篇文档一套*——两个块的 `.bib` 源会被拼起来一次解析，键不能撞。])
#case("两个作用域：块 1 行内标注、块 2 脚注", gb7714.with(), full: false, own-bib: false, body: [
  #[#show: gb7714.with(full: true)
    块 1（行内标注）：#cite(<bm-zh>)
    #bibliography(MAIN, title: none, full: false, label: "s-a")
  ]
  #[#show: gb7714.with(cite-footnote: true, full: true)
    块 2（脚注）：#cite(<bm-en>)
    #bibliography(MAIN, title: none, full: false, label: "s-b")
  ]
])
#case("两个作用域：不同 version / style", gb7714.with(), full: false, own-bib: false, body: [
  #[#show: gb7714.with(version: 2015)
    块 1（2015 · 顺序编码制）：#cite(<bm-zh>, bib-label: "v15")
    #bibliography(MAIN, title: none, full: false, label: "v15")
  ]
  #[#show: gb7714.with(version: 2025, style: "author-date")
    块 2（2025 · 著者-出版年制）：#cite(<bm-zh>, bib-label: "v25")
    #bibliography(MAIN, title: none, full: false, label: "v25")
  ]
])
