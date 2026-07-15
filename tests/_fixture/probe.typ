// 矩阵用例的渲染器。
//
// 矩阵的形态：*一个参数 = 一个文件 = 一份 golden*，文件里穷举该参数的全部取值，
// 每个取值渲成一个区块（取值名 + 正文标注 + 文献表）。渲染结果是一张*人能直接判对错*的
// 对照表——golden 的差异就是该人工审核的地方。
//
// 用法：
//   #import "/tests/_fixture/probe.typ": *
//   #spec(param: "show-anon", controls: "责任者不明时的占位", expect: "…期望行为与权威依据…")
//   #case("auto · 著者-出版年制", gb7714.with(style: "author-date"), cites: (<bm-noauthor>,))
//   #case("false", gb7714.with(style: "author-date", show-anon: false), cites: (<bm-noauthor>,))
#import "/lib.typ": *

/// 区块计数器：每个 `case` 用一个*命名列表*把编号与消歧范围隔离开——
/// 否则同一文档里多个匿名文献表共享编号空间，第二块起的编号会接着往上加，
/// 正文标注与表内编号对不上（`正文 [1-2]` 而表里印 `[3][4]`）。
#let _case-n = counter("gb7714-matrix-case")

/// 八份共享语料。矩阵用例按需点名，绝大多数用 `MAIN`。
#let MAIN = bytes(read("/tests/_fixture/main.bib"))
#let EDGE = bytes(read("/tests/_fixture/edge.bib"))
#let LANG = bytes(read("/tests/_fixture/lang.bib"))
#let LATEX = bytes(read("/tests/_fixture/latex.bib"))
#let TYPES = bytes(read("/tests/_fixture/types.bib"))
#let PARSE = bytes(read("/tests/_fixture/parse.bib"))
#let ROLES = bytes(read("/tests/_fixture/roles.bib"))
#let ETAL-LAST = bytes(read("/tests/_fixture/etal-last.bib"))

/// 用例头：参数名、它控制什么、期望行为与权威依据。**用作 show 规则**：
///
///   #show: spec.with(param: "show-anon", controls: "…", expect: [ … ])
///
/// 必须是 show 规则而不是普通调用——`set` 只对*函数自身产出的内容*生效，写成 `#spec(..)` 的话
/// `set text(lang: ..)` 管不到后面的区块，整篇文档的语言就还是 typst 的缺省 `en`
/// （`title: auto` 会出 "Bibliography"、`by-doc-*` 标点档会走半角）。
///
/// `expect` 写*现在期望的行为*与依据（国标条款、官方 CSL、biblatex 实测），审 golden 时不用回翻。
/// 页面设成单页长条（`height: auto`）：pdftotext 出来不带分页噪声，diff 干净。
///
/// `doc-lang` 是*文档*语言（不是条目语言），缺省中文——这是本包的典型使用场景。
/// 要在同一文件里对照另一种文档语言，用下面的 `in-lang`。
#let spec(param: "", controls: "", expect: "", doc-lang: "zh", body) = {
  set page(width: 21cm, height: auto, margin: 1.2cm)
  set text(size: 9.5pt, lang: doc-lang)
  set par(justify: false)
  block(width: 100%, fill: luma(238), inset: 7pt, radius: 2pt)[
    #text(size: 13pt, weight: "bold")[#param]
    #if controls != "" [#linebreak() #controls]
    #if expect != "" [#linebreak() #text(fill: luma(80))[*期望*　#expect]]
  ]
  v(5pt)
  body
}

/// 把一个 `gb7714.with(..)` 配置裹进另一种*文档语言*，供 `by-doc-*` 一类跟文档语言走的档位做对照：
///
///   #case("by-doc · 西文文档", in-lang("en", gb7714.with(bib-punct-style: "by-doc-no-space")), ..)
#let in-lang(lang, config) = body => {
  set text(lang: lang)
  show: config
  body
}

/// 一个取值的区块。
///
/// - `label`：取值名（`"auto · 著者-出版年制"`），golden 的 diff 靠它定位是哪个取值变了；
/// - `config`：`gb7714.with(..)`，本区块作用域内生效；
/// - `cites`：正文标注要引哪些键（标签数组，如 `(<bm-zh>, <bm-en>)`）；
/// - `bib`：语料，缺省 `MAIN`；
/// - `body`：需要自定义正文时传（如测 `#cite()` 的单次覆盖、脚注制的重复引用梯子）。
///   传了 `body` 就不再自动发 `cites`。
/// - `full`：文献表是否收录未引用的条目，缺省 `true`（矩阵要看全表）。
/// - `title`：文献表标题，缺省 `none`（矩阵只有 `04-layout/title` 那一个用例要看标题）。
/// - `bib-args`：透传给 `bibliography(..)` 的逐表参数（测「逐表覆盖」用）。
/// - `own-bib`：本区块要不要由 probe 自己发一张文献表。缺省 `true`；
///   `body` 里自己建了列表（多列表用例）时传 `false`，免得多出一张没人要的表。
#let case(label, config, cites: (), bib: MAIN, body: none, full: true, title: none, bib-args: (:), own-bib: true) = {
  _case-n.step()
  context {
    let tag = "c" + str(_case-n.get().first())
    block(width: 100%, breakable: false, above: 6pt, below: 2pt,
          stroke: (top: 0.6pt + luma(150)), inset: (top: 4pt, bottom: 5pt))[
      #text(weight: "bold", fill: rgb("#166534"))[▸ #label]
      #v(2pt)
      #[
        #show: config
        #set-bib-label(tag)
        #if body != none {
          body
          linebreak()
        } else if cites.len() > 0 {
          [正文：]
          cites.map(k => cite(k)).join([ ])
          linebreak()
        }
        #if own-bib { bibliography(bib, title: title, full: full, label: tag, ..bib-args) }
      ]
    ]
  }
}

/// 纯正文用例（不渲染文献表）：给只影响标注、不影响著录的参数用（如 `cite-form`）。
#let cite-only(label, config, cites: (), bib: MAIN, body: none) = {
  _case-n.step()
  context {
  let tag = "c" + str(_case-n.get().first())
  block(width: 100%, breakable: false, above: 6pt, below: 2pt,
        stroke: (top: 0.6pt + luma(150)), inset: (top: 4pt, bottom: 5pt))[
    #text(weight: "bold", fill: rgb("#166534"))[▸ #label]
    #v(2pt)
    #[
      #show: config
      #set-bib-label(tag)
      #if body != none { body } else { cites.map(k => cite(k)).join([ ]) }
      // 文献表必须存在（cite 要解析编号与责任者），但既不显示、也不占版面——
      //   `hide` 只是隐形、仍占布局，会在 golden 里留下成片空行；`place` 才把它抽出文流。
      #place(hide(bibliography(bib, title: none, full: false, label: tag)))
    ]
  ]
  }
}
