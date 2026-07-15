//! param: custom-drivers（与外部配置的联动 · 逐表 / 逐次覆盖）
//! values: end-with-period, show-* 门控, punct-style, 逐表 bibliography(custom-drivers:), 逐次 cite(footnote:)
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 联动与覆盖", controls: "模板渲出来的条目怎样受其余配置管。",
  expect: [*末尾句点*由 `end-with-period` 控制：`true`（缺省）在条目末尾补一个*结构性句点*；
    已以句点收尾时不重复补（不会出现 `2nd ed..`）；`?` `!` `？` `！` 与表意句号 `。` 是*内容标点*，
    其后照常补结构句点。外层渲染对走模板路径的条目*整体跳过*补点逻辑，避免双重句点。
    *block token 仍受各自的 `show-*` 管*：`mark-medium` 受 `show-mark` / `show-medium` / `space-before-mark`；
    `imprint-block` 受 `show-sine-loco` / `show-sine-nomine` / `space-before-pages`；`access` 受 `show-url` / `show-pid`。
    裸 `mark` 受 `show-mark` 门控（关掉返回空）但*不受* `space-before-mark`。
    ⚠️ **括号在模板里没有任何特殊地位，就是普通字面量**。要它跟内容同进同退，
    把它和内容*一起*放进条件组（`<[mark]>`）。
    不包组时它的存亡**取决于塌缩规则**：空 token 两侧的字面量塌缩成一个，*段间句点*活下来、
    段内绑定符与包裹符跟着死——所以 `title [mark] . publisher` 里那对括号会被后面那个句点吞掉
    （下方第三块），而 `?<edition ( number )>` 里的 `）` 因为后面没有段可分隔，就留在那儿了
    （见 `03-groups`）。**别依赖这个——包组**。
    *裸标点随 `bib-punct-style`*；verbatim 不随。
    `bibliography(custom-drivers:)` 与 `cite(footnote: true, custom-drivers:)` 逐表 / 逐次覆盖，`auto` 继承全局。])
#let T = "author . title<mark-medium> . imprint-block . access"
// 一份文档只能有一套 bib 数据（`gb7714()` 把全文的 bib 源拼起来一次解析），
// 所以本文件所有区块共用同一份 `mixed`——混用 MAIN 与 MAIN+EDGE 会撞出「duplicate key」。
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let one(name, cfg) = case(name, cfg, cites: (<bm-zh>, <bm-online>, <im-nopub>), bib: mixed, full: false)
#one("基线（模板 = author . title<mark-medium> . imprint-block . access）", gb7714.with(custom-drivers: (book: T)))
#one("end-with-period: false（不补末尾句点）", gb7714.with(custom-drivers: (book: T), end-with-period: false))
#one("show-mark: false（方括号整块消失）", gb7714.with(custom-drivers: (book: T), show-mark: false))
#one("show-medium: false（只剩类型码）", gb7714.with(custom-drivers: (book: T), show-medium: false))
#one("space-before-mark: true（mark-medium 受它管）", gb7714.with(custom-drivers: (book: T), space-before-mark: true))
#one("裸 mark + show-mark: false · 括号进组 <[mark]>（正典写法：整块消失）", gb7714.with(custom-drivers: (book: "author . title <[mark]> . publisher"), show-mark: false))
#one("裸 mark + show-mark: false · 自造记号也进组 <-- mark -->（组不挑记号）", gb7714.with(custom-drivers: (book: "author . title <-- mark --> . publisher"), show-mark: false))
#one("裸 mark + show-mark: false · 括号*不*进组 [mark]（括号被后面那个段间句点塌缩掉了——别依赖它）", gb7714.with(custom-drivers: (book: "author . title [mark] . publisher"), show-mark: false))
#one("多 token 进组 <[mark<{/}medium>]>（任意多 token、任意嵌套都成立）", gb7714.with(custom-drivers: (book: "author . title <[mark<{/}medium>]> . publisher")))
#one("裸 mark + show-mark: false · 写法 [mark]（紧贴 → 括号配对，整块消失）", gb7714.with(custom-drivers: (book: "author . title [mark] . publisher"), show-mark: false))
#one("裸 mark + show-mark: false · 写法 {[}mark{]}（verbatim 括号 → 同样干净）", gb7714.with(custom-drivers: (book: "author . title {[}mark{]} . publisher"), show-mark: false))
#one("裸 mark：show-mark: true（对照）", gb7714.with(custom-drivers: (book: "author . title [ mark ] . publisher")))
#one("show-sine-loco / show-sine-nomine: true（imprint-block 补占位）", gb7714.with(custom-drivers: (book: T), show-sine-loco: true, show-sine-nomine: true))
#one("show-url: false（access 不出 URL）", gb7714.with(custom-drivers: (book: T), show-url: false))
#one("bib-punct-style: half（裸标点半角）", gb7714.with(custom-drivers: (book: "author , title , publisher"), bib-punct-style: "half"))
#one("bib-punct-style: full（同一模板，全角）", gb7714.with(custom-drivers: (book: "author , title , publisher"), bib-punct-style: "full"))
#one("末尾已是句点不重复补：模板尾写 {.}", gb7714.with(custom-drivers: (book: "author . title {.}")))
#one("内容标点 ？ 之后照常补结构句点", gb7714.with(custom-drivers: (book: "author . title {？}")))
#case("逐表覆盖：bibliography(custom-drivers:)（全局无模板）", gb7714.with(), bib: mixed,
  cites: (<bm-zh>,), full: false, bib-args: (custom-drivers: (book: "{【逐表模板】} author . title")))
#case("逐次覆盖：cite(footnote: true, custom-drivers:)", gb7714.with(cite-footnote: true), bib: mixed, full: false,
  body: [脚注 #cite(<bm-zh>, custom-drivers: (book: "{【逐次模板】} author . title"))。])
