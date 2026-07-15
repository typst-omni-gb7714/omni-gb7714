//! param: warn-missing-title
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "warn-missing-title", controls: "缺题名时是否*报错*。GB/T 7714 要求每条文献都著录题名。",
  expect: [`false`（缺省）：缺 / 空 `title` 软退化为空题名槽，其余各项照常著录（下方 `ti-notitle` 那条）。
    `true`：载入期急扫全表，任一非特殊类型条目缺 / 空 `title` 即*报错停编译*并指明该键
    （Typst 没有软警告机制，以报错代警告，让缺失早暴露）。
    ⚠️ 它扫的是*整个文档*的 bib 数据，不限于当前 `#show: gb7714(..)` 的作用域——
    所以「`true` + 缺题名语料」没法与本文件其它区块并置（一处报错整篇编不过）。
    该档的行为在 `contract/panic/warn-missing-title.typ` 验证：题名齐备时 `true` 与 `false` 渲染*完全相同*，
    缺题名时报 `load.missing-title`。])
#case("false（缺省）· 缺题名条目 → 空题名槽", gb7714.with(), bib: EDGE, cites: (<ti-notitle>, <ti-punct>), full: false)
#case("false · 空 title 字段（`title = {}`）同样软退化", gb7714.with(),
  bib: bytes("@book{empty-t, author={甲}, title={}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), full: true)
#case("false · 题名齐备（对照，与 true 无差别）", gb7714.with(), cites: (<bm-zh>, <aj-zh>), full: false)
