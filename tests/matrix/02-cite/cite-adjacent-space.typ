//! param: cite-adjacent-space
//! values: auto, true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-adjacent-space", controls: "正文标注（`@key` / `#cite()`）两侧*源空格*的去留。",
  expect: [中文里 `见 @key 所述` 的空格是 Typst 标签语法逼出来的（`@key所述` 会把汉字吞进标签名），
    西文里同样的空格却是正常词距。`auto`（缺省）看邻字：空格挨着 CJK 字符那一侧吃掉、否则保留——
    纯中文得 `见[1]所述` / `见（张三，2020）所述`，西文与中西混排各得其所；上标编号前的空格照原生吞掉，不受本参数影响。
    `true` 一律保留（纯原生行为）；`false` 一律吃掉。末两块把同一档裹进*西文文档*作对照。])
#let zh = [见 #cite(<bm-zh>) 所述，另见 #cite(<bm-en>) 。混排 see #cite(<bm-en>) here。]
#let ay = [见 #cite(<bm-zh>) 所述，另见 #cite(<bm-en>) 。叙述式 #cite(<bm-zh>, form: "prose") 所述。]
#cite-only("auto（缺省）· 顺序编码制：标注后空格吃掉、西文邻字保留", gb7714.with(), body: zh)
#cite-only("auto · 著者-出版年制：括号前后空格都吃掉", gb7714.with(style: "author-date"), body: ay)
#cite-only("true · 一律保留（原生行为）", gb7714.with(style: "author-date", cite-adjacent-space: true), body: ay)
#cite-only("false · 一律吃掉（西文邻字也吃）", gb7714.with(cite-adjacent-space: false), body: zh)
#cite-only("auto · 西文文档：词距照留", in-lang("en", gb7714.with(style: "author-date")), body: [See #cite(<bm-en>) here, and #cite(<bm-zh>) too.])
#cite-only("false · 西文文档：一律吃掉", in-lang("en", gb7714.with(style: "author-date", cite-adjacent-space: false)), body: [See #cite(<bm-en>) here, and #cite(<bm-zh>) too.])
