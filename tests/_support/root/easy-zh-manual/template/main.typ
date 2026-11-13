#import "../src/lib.typ": manual, option, example, callout, arg, arg-ref, url, kbd, options-from-source, api-from-source, is-html-target, in-callout, auxiliary-size, output-label-size, hanging-label-width, hanging-label-dx, nested-hanging-label-dx, zebra-fill, zebra-rows, panel-radius, theme
#import "../../src/drivers/templates.typ": built-in-templates-2025
#import "entry-data-2025.typ": entry-data-examples-2025
#import "@preview/cuti:0.4.0": show-cn-fakebold
//#show: it => if is-html-target { it } else { show-cn-fakebold(it) }
// 我喜欢倾斜版的大（小）于等于号
#show math.equation: it => {
    show sym.lt.eq: sym.lt.eq.slant
    show sym.gt.eq: sym.gt.eq.slant
    it
  }
// 用户手册统一用弯引号，不用直角引号
// 含 API 区自源码抽取的内容。
#show "「": "“"
#show "」": "”"
#show "『": "‘"
#show "』": "’"

// 用「方正白正体」显示标点，所以在正文散文里替换为半角。
// 但 `demo` 的真实渲染输出区须保留包产出的原样全半角（否则会把 GB 全角标点误显为半角、
//   与「标点矫正 / punct-style」等章节自相矛盾）：用 `_raw-out` 状态显示条件，输出区内不替换。
// HTML 下不替换（网页字体的全角标点无多余留白，且 `context` 若进入标题会让目录 outline 报
//   「failed to determine link anchor」）；仅 PDF 下按 `_raw-out` 显示条件替换、demo 输出区让位保留全角。
// 显示条件信号是样式链上的自定义字体特征标记（demo 输出区 `set text(features: (RAWO: 1))`，
//   字体忽略未知特征标签，零视觉影响）——不用位置态：demo 的脚注体在页底重排，字级
//   `state.get()` 的读数随分页与正文锚点的相对位置震荡，5 轮收敛预算内定不下来
//   （曾是本文档「did not converge」警告的根源）；样式链随内容构造走，与布局无关。
#let _raw-flag(body) = { set text(features: (RAWO: 1)); body }
#let _in-raw-out() = text.features.at("RAWO", default: 0) != 0
#show "，": it => if is-html-target { it } else { context if _in-raw-out() { it } else { "," } }
#show "：": it => if is-html-target { it } else { context if _in-raw-out() { it } else { ":" } }
#show "；": it => if is-html-target { it } else { context if _in-raw-out() { it } else { ";" } }
#show "！": it => if is-html-target { it } else { context if _in-raw-out() { it } else { "!" } }
#show "？": it => if is-html-target { it } else { context if _in-raw-out() { it } else { "?" } }
// 脚注体收不到构造点的 set（Typst 脚注在 entry 处重新取样式链），标记进不去；改在 entry 处
//   按*锚点位置*读状态——锚点在正文流内、与 demo 输出区的 update 锚同页相邻，读数一轮即稳——
//   是 demo 里的脚注就把特征标记补挂到注体样式链，供上面的标点规则读取。
#let _raw-out = state("raw-out", false)
#show footnote.entry: it => {
  if is-html-target { it } else {
    context if _raw-out.at(it.note.location()) { _raw-flag(it) } else { it }
  }
}
// TeX 风格徽标：PDF 使用文字偏移；HTML 使用带 CSS 类的 span，以便跟随网页字体。
// 各 class 的偏移规则见 web/style.css 的 .logo-* 段。
// 注意：html.* 命名空间只在 --features html 编译下存在，PDF 模式必须 gate 在 if is-html-target 内。
#let TeX = if is-html-target {
  html.elem("span", attrs: (class: "logo-tex"))[T#html.elem("span", attrs: (class: "logo-mid"))[e]X]
} else {
  box(baseline: 0pt)[T#h(-0.14em)#text(baseline: 0.22em)[E]#h(-0.12em)X]
}
#let La = if is-html-target {
  html.elem("span", attrs: (class: "logo-la"))[L#html.elem("span", attrs: (class: "logo-a"))[a]]
} else {
  box(baseline: 0pt)[L#h(-0.30em)#text(size: 0.74em, baseline: -0.28em, weight: "bold")[A]#h(-0.12em)]
}
#let LaTeX = if is-html-target {
  html.elem("span", attrs: (class: "logo-latex"))[#La#TeX]
} else {
  box(baseline: 0pt)[#La#TeX]
}
#let Bib = if is-html-target {
  html.elem("span", attrs: (class: "logo-bib"))[B#html.elem("span", attrs: (class: "logo-ib"))[ib]]
} else {
  box[B#h(-.05em)#text(font: "Libertinus Serif")[#smallcaps[ib]]]
}
#let BibTeX = if is-html-target {
  html.elem("span", attrs: (class: "logo-bibtex"))[#Bib#TeX]
} else {
  box[#Bib#h(-.15em)#TeX]
}
#let BibLaTeX = if is-html-target {
  html.elem("span", attrs: (class: "logo-biblatex"))[#Bib#LaTeX]
} else {
  box[#Bib#h(-.05em)#LaTeX]
}
#let noindent = {h(-2em)}
#import "@preview/cjk-spacer:0.2.0": *
// cjk-spacer 在 HTML 输出下会把含点文本切断为多个 <p>，HTML 不需要它
#show: it => if is-html-target { it } else { cjk-spacer(it) }

// 实时示例：展示的代码也由 eval 运行，避免代码和输出不一致。
// `_raw-out` 使输出保留包生成的全角、半角标点。
#import "/lib.typ" as omni
// 各例共享 `refs.bib`；特定条目直接写在示例的 `bytes("...")` 中。
#let _demo-refs = bytes(read("/refs.bib"))
#let _demo-scope = (
  gb7714: omni.gb7714,
  bibliography: omni.bibliography,
  cite: omni.cite,
  "set-bib-label": omni.set-bib-label,
  refs: _demo-refs,
)
// 默认给每个示例分配独立列表，使编号从 [1] 开始。注入只作用于 eval 源码。
// `isolate: false` 用于已经显式设置 label 的多列表示例。
#let demo(title, code, lang: "zh", isolate: true) = example(title)[
  #code
  #context {
    set par(first-line-indent: 0em)
    let nested = in-callout()
    let n = counter("gb7714-demo").get().first()
    let lbl = "gbdemo-" + str(n)
    // 隐藏列表标题，避免示例把“参考文献”写入目录。
    let src = if isolate and code.text.contains("bibliography(") {
      "#set-bib-label(\"" + lbl + "\")\n" + code.text.replace("bibliography(", "bibliography(label: \"" + lbl + "\", title: none, ")
    } else { code.text }
    let output-box = block(
      width: 100%,
      breakable: false,
      above: 0.5em,
      stroke: 0.65pt + theme.result-accent.lighten(22%),
      radius: panel-radius,
      inset: 0pt,
      clip: true,
    )[
      #block(width: 100%, fill: zebra-fill(theme.result-bg, theme.result-stripe), inset: (x: 0.75em, y: 0pt))[
        // `_raw-flag` 标记输出；state 供脚注判断锚点是否位于示例中。
        #_raw-out.update(true)
        #_raw-flag(zebra-rows({
          set align(left)
          set par(justify: true)
          set text(lang: lang)
          eval(src, mode: "markup", scope: _demo-scope)
        }))
        #_raw-out.update(false)
      ]
    ]
    block(width: 100%)[
      #place(top + left, dx: if nested { nested-hanging-label-dx } else { hanging-label-dx }, dy: 0.32em)[
        #box(width: hanging-label-width)[
          #align(right, text(fill: theme.result-accent, weight: "bold", size: output-label-size, font: "FZHei-B01S", "输出"))
        ]
      ]
      #output-box
    ]
    counter("gb7714-demo").step()
  }
]

#show: manual.with(
  title: [*omni-gb7714*],
  description: [Typst 的 GB/T 7714 参考文献格式化包],
  authors: ([#link("https://www.github.com/schrodingerblume")[吴俊豪]#footnote[作者邮箱：#link("mailto:andrew.junhao.wu@gmail.com")；]],),
  version: "0.1.0",
  license: "Apache 2.0",
  date: datetime.today(),
  abstract: [
    omni-gb7714 在 Typst 中生成 GB/T 7714 引用和参考文献表，支持 2005、2015 和 2025 版，以及顺序编码制、著者-出版年制、多语言和双语条目、多列表、脚注与尾注引用。输入采用 #BibLaTeX 或 CSL JSON，常用扩展字段的写法见各类型说明。

    本包尚未发布到 Typst Universe，接口可能随 Typst 版本调整。
  ],
  show-example-list: false,
)

= 概述

GB/T 7714《信息与文献　参考文献著录规则》规定参考文献的著录和标引方法。`omni-gb7714` 读取文献数据，在 Typst 中生成正文标注和参考文献表。

== 适用场景

Typst 原生国标 CSL 可以完成常见的单语著录。如果文档还需要下列功能，可使用本包：

- GB/T 7714—2025、2015 和 2005 三个版本；
- 按条目语言选择“等”或“et al.”，以及中外文双语关联著录；
- 脚注、尾注、多列表、分章文献表或同一文档中的多种著录格式；
- 标准、档案、地图、数据集、预印本等扩展类型及其 #BibLaTeX 字段；
- 按学校或期刊要求精细调整姓名、标点、编号、永久标识符和条目格式。

只需基础的顺序编码制或著者-出版年制，且 Typst 原生 CSL 的输出已经符合要求时，可以继续使用原生 `bibliography`。

== 支持范围

本包默认采用 GB/T 7714—2025，也可切换到 2015 或 2005 版。主要输入为 #BibLaTeX `.bib`，也可读取 Zotero、Better #BibTeX 或 Pandoc 导出的 CSL JSON。输入格式兼容不表示每个扩展字段都会输出；例如 `howpublished` 尚不参与内置出版项，见@input-field-limits。

正文引用沿用 Typst 的 `@key`，参考文献表使用本包提供的 `bibliography`。最小用法见@quick-start-section；标准版本和标引体系分别由 `version` 与 `style` 设置。

== 使用条件

最低支持 Typst 0.14.0；使用全部功能时建议采用 Typst 0.15.1 或更高版本。本包尚未发布到 Typst Universe。

#pagebreak()
= 使用说明

== 快速上手 <quick-start-section>

将包源码保存在项目的独立目录中，例如 `omni-gb7714/`；保留其中的 `src/` 和随包资源，不要只复制 `lib.typ`。准备 `.bib` 文件后，导入入口、应用 `gb7714` 并生成文献表：

#example("最小用法")[
`refs.bib`：

```bib
@book{morris2010,
  author    = {Morris, Ian},
  title     = {Why the West Rules---for Now},
  location  = {New York},
  publisher = {Farrar, Straus and Giroux},
  date      = {2010},
  langid    = {english},
}
```

Typst 文档：

```typ
#import "omni-gb7714/lib.typ": *
#show: gb7714()

相关讨论见 @morris2010。

#bibliography(read("refs.bib"))
```
]<mwe-example>

```typc #show: gb7714()``` 应位于第一次引用之前。`@morris2010` 中的 `morris2010` 是 `.bib` 条目的键。包目录中的 `lib.typ` 是导入入口，正文另存为 `main.typ` 等文件。

=== 与原生用法的区别

Typst 原生写作 ```typc #bibliography("refs.bib")```。本包使用 ```typc #bibliography(read("refs.bib"))```，由调用方读取文件并传入内容，避免把调用方的相对路径误当成包内路径。

本包提供的是自己的著录与引用实现。Typst 原生也能通过 CSL 选择国标样式，并在 0.15 起支持多文献表；应根据所需的双语、注释及格式配置能力选择，而不是仅凭是否支持某个标准年份判断。

== 文献数据：以 #BibLaTeX `.bib` 为主 <input-format>

一般用户只需维护 `.bib` 文件。每条记录由条目类型、引用键和字段组成：上例中的 `@book` 是图书类型，`morris2010` 是正文引用使用的键，其余各行为字段。

常用字段如下：

- 责任者：`author`、`editor`、`translator`；
- 题名：`title`、`subtitle`、`journaltitle`、`booktitle`；
- 出版信息：`date`、`location`、`publisher`、`volume`、`number`、`pages`；
- 网络信息：`url`、`urldate`、`doi`、`cstr`。

图书、期刊文章、学位论文、标准、专利等类型所需的字段见@各类文献-2025-section。

=== CSL JSON

如果现有工作流程已经由 Zotero 或 Pandoc 等工具生成 CSL JSON，也可直接读取：

```typ
#bibliography(read("refs.json"))
```

本包会自动识别 JSON 内容，不需要额外设置输入格式。

=== Zotero 的 Extra 字段

Zotero 会把部分扩展信息写入 Extra。导出 `.bib` 后，这些内容通常位于 `note` 或 `annotation` 字段。本包可以读取常见的 `变量: 值` 写法：

```
note = {Original Date: 1705
PMID: 12345
page: 序2-3}
```

Extra 只补充缺失字段；`.bib` 中已经明确填写的 `date`、`pages` 等字段优先。一般不必手工维护 Extra，保留 Zotero 的导出内容即可。

=== 字段读取与输出范围 <input-field-limits>

解析器能保存一个字段，并不表示内置格式一定会输出它。新建数据时，出版地用 `location`（或 `address`），出版者用 `publisher`；不要把二者合写在 `howpublished`。已有文献库不能改动时，可通过 `custom-fields` 和自定义模板读取该字段，见@custom-howpublished。

Extra 中受支持的字段会被提取；已知但未参与著录的变量可能仅作为字段边界被消费。类型推断也依赖有限的线索，例如地图的比例尺、标准号或已知预印本平台，不能保证任意退化成 `@misc` 的条目都能还原。发现输出缺项时，应同时检查原始字段、解析后的类型和采用的著录格式。

== 正文引用：```typ @key``` 与 ```typ #cite(..)``` 的关系 <cite-syntax-section>

正文引用可使用 `@key` 或 `cite`，对应写法如下：

#table( columns: (auto, 1fr),
  table.header(repeat: true, [写法], [等价于]),
  [```typ @key```], [```typ #cite(<key>)``` 或 ```typ #cite[@key]```],
  [```typ @a@b```], [```typ #cite(<a>, <b>)``` 或 ```typ #cite[@a@b]```],
  [```typ #cite(<a>, <b>)[@c@d]```], [```typ @a@b@c@d```（位置参数和 content 中的 `@key` 可以混用）],
)

```typ @key``` 是 Typst 的引用简写。```typ #cite(..)``` 还可设置引文页码、样式和脚注等参数（见 @cite-fn）。不传额外参数时，两者的输出相同。

通常直接使用 ```typ @key```。需要附带页码可写 ```typ @key[1-2]```；需要其他引用形式或单次脚注时，使用 ```typ #cite(<key>, ..)```，也可用 ```typ #cite(..)[@a@b]``` 包住已有引用。补充信息的写法见@cite-supp-section，`cite` 的全部参数见@cite-fn。

== 选择标引体系：顺序编码制与著者-出版年制

GB/T 7714 规定顺序编码制和著者-出版年制两种参考文献标引体系。通过 `gb7714(.., style: ..)` 选择后，正文标注和参考文献表同时切换。以下实时示例使用项目附带的 `refs.bib`，代码中记作 `refs`：

#demo("顺序编码制（默认）")[```typ
#show: gb7714
苏格拉底是民主制度的坚决反对者@Morris2010。
#bibliography(refs, keys: [@Morris2010])
```]

#demo("著者-出版年制")[```typ
#show: gb7714(style: "author-date")
苏格拉底是民主制度的坚决反对者@Morris2010。
#bibliography(refs, keys: [@Morris2010])
```]

顺序编码制默认使用上标序号，参考文献表按首次引用顺序排列。著者-出版年制使用“著者，年”标注，参考文献表按责任者和出版年排序，默认不编号。两种体系的完整示例见 @mwe-example 和 @ay-example。

#figure(
  image("../examples/eg2.pdf"),
  caption: [著者-出版年制渲染示例（与 @mwe-example 顺序编码制对照）]
)<ay-example>

=== 分别设置正文标注和著录格式

`style` 同时控制两项相互独立的设置；标量写法表示两项使用同一个值：

- *①正文标注形式*：正文里出现的是 `[1]` 还是 `(张三, 2020)`；
- *②著录格式*：参考文献表条目里出版日期的位置——顺序编码制在末尾（`…社, 2020.`），著者-出版年制提到责任者之后（`张三, 2020. …`）。

要分别指定，使用字典 ```typc (cite: .., bib: ..)```。两个键必须同时给出；其中一项需要继承默认值时写 `auto`。两项相同时直接写标量：

```typ
// 著者-出版年制标注，文献表保留编号
gb7714(style: "author-date", bib-numbering-style: "bracket")
// 正文使用顺序编码制，文献表按著者-出版年制著录
gb7714(style: (cite: "numeric", bib: "author-date"))
```

#demo("混合设置：顺序编码制标注，著者-出版年制著录")[```typ
#show: gb7714(style: (cite: "numeric", bib: "author-date"))
标注仍是编号@Morris2010，著录里出版年却提到了责任者之后@Sunstein1996。
#bibliography(refs, keys: [@Morris2010@Sunstein1996])
```]

*③文献表编号*由 #arg-ref("gb7714", "bib-numbering-style")[`bib-numbering-style`] 控制。默认值 `auto` 在顺序编码制下显示编号，在著者-出版年制下不显示；显式设置后，著者-出版年制也可带编号。*④排序*分别由 #arg-ref("gb7714", "bib-sort-by")[`bib-sort-by`]（参考文献表）和 #arg-ref("gb7714", "cite-sort-by")[`cite-sort-by`]（合并引用内）控制。回引和编号列只在显示编号时生效。

全角编号样式（`"fullwidth-bracket"` 的 `［］`、`"shell"`、`"fullwidth-paren"`）默认保持标点全宽。Typst 会压缩行首、行尾的全角标点，使编号列缩短一个字宽。#arg-ref("gb7714", "number-punct-width")[`number-punct-width`] 控制这一行为：`"full"`（默认）保持全宽，`"native"` 使用 Typst 的标点压缩。半角编号不受影响。

使用国标 CSL 样式全名（如 `"gb-7714-2015-numeric"`）时，标准版本由样式名确定；此时 `style` 只能使用字符串。

=== 著者-出版年制文献表的缩进

著者-出版年制的文献表默认不编号，首行顶格，后续行缩进 `1.5em`。缩进量由 #arg-ref("gb7714", "entry-hanging-indent")[`entry-hanging-indent`] 控制。显式设置 `bib-numbering-style` 后，条目带有独立编号列；此时默认缩进为 `0pt`，各行均与条目正文左缘对齐。

编号位置由 #arg-ref("gb7714", "number-placement")[`number-placement`] 控制；首行和后续行的缩进分别由 #arg-ref("gb7714", "entry-first-line-indent")[`entry-first-line-indent`]、#arg-ref("gb7714", "entry-hanging-indent")[`entry-hanging-indent`] 控制。

```typ
  // GB/T 7714 原文采用首行缩进、其余行顶格
  #show: gb7714(number-placement: "inline", entry-first-line-indent: 2em)   // 顺序编码制
  #show: gb7714(style: "author-date", entry-hanging-indent: 0pt, entry-first-line-indent: 2em)

  // 编号挂到版心外
  #show: gb7714(number-placement: "margin")
```

#demo("GB 原文版式：编号排行内，条目首行缩进")[```typ
  #show: gb7714(number-placement: "inline", entry-first-line-indent: 2em)
  @Morris2010@Rogers2011
  #bibliography(refs, keys: [@Morris2010@Rogers2011])
```]

`style` 有三类取值：

- `"numeric"` / `"author-date"`：与 `version` 一起使用；
- 国标 CSL 全名，如 `"gb-7714-2015-numeric"`：名称中已包含版本；
- Typst 原生 CSL 样式，如 `"ieee"` / `"apa"`：只能写在 `bibliography(style: ..)` 中。

#callout(kind: "warning", title: "原生 CSL 样式与 GB 文献表混用")[
  文档中出现 `ieee`、`apa` 等原生 CSL 文献表时，全文的行内引用交给 Typst 原生引擎处理。此时指向 GB 文献表的引用不再进行区间压缩和同组去重。只使用 GB 样式的文档不受影响。
]

`style` 在 `gb7714(..)` 中设置一次即可。标准版本由 `version` 控制，默认是 2025；旧文档可改为 2015 或 2005。


=== 正文标注的消歧：补名 / 展开名单 / 年份后缀

著者-出版年制的正文标注可能相同，#arg-ref("gb7714", "disambiguate")[`disambiguate`] 会按以下顺序逐级消歧（次序与社区 CSL 一致）：

- *展开名单*（`names`）：第一责任者相同、合作者不同的条目，逐条展开被「等 / et al」截断的名单直到分开——`(Brown, Wang et al., 2020)` 与 `(Brown, Chen et al., 2020)`；
- *补名*（`given-name`）：同姓责任者无法区分时，先补名字首字母，如 `(Smith J, 2020)`；仍有重名时再显示全名，如 `(Miller John, 2020)`。参考文献表中的第一责任者也会同步补名。依据 GB/T 7714 §9.3.1 和 §7.1.1；
- *年份后缀*（`date`）：剩下的（真同一责任者同一出版日期）加 `a` / `b` / `c`——正文 `（张三，2020a）`、条目 `张三, 2020a. …`。

添加名字信息可区分“不同人同姓同年”的情况，避免仅用 `(Smith, 2020a)`、`(Smith, 2020b)` 而产生误解。

标量是三键同值的简写，字典逐机制指定：

```typ
disambiguate: auto                       // 默认：按正文标引体系启用（见下）
disambiguate: false                      // 全部禁用
disambiguate: (given-name: false)        // 仅禁用补名，其余仍取 auto
disambiguate: (given-name: true)         // 混合制下强制补名（见下）
```

#demo("消歧：补名与年份后缀")[```typ
#show: gb7714(style: "author-date")
同一人同年两篇得年份后缀@s2020a@s2020b；同姓不同人自动补名@j2020@m2020。
#bibliography(bytes("@book{s2020a, author={Smith, John}, title={Alpha}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{s2020b, author={Smith, John}, title={Beta}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{j2020, author={Smith, Jane}, title={Gamma}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{m2020, author={Smith, Mike}, title={Delta}, publisher={P}, address={X}, date={2020}, langid={english}}"))
```]

== 引用形式：叙述式、上标与仅责任者 <cite-form-section>

同一引用可切换形式，单次写 ```typ #cite(<key>, form: ..)``` 或全局 `gb7714(cite-form: ..)` 均可。各形式实测（作者 Morris、年 2010）：

#table(columns: (auto, 1fr, 1fr),
  table.header(repeat: true, [`form`], [顺序编码制], [著者-出版年制]),
  [`"normal"`（默认）], [`[1]`（上标）], [`(Morris, 2010)`],
  [`"inline"`], [`[1]`（正常字号、不上标）], [同 `normal`],
  [`"super"`], [`[1]`（强制上标）], [整段上标（CJK 全角括号基线可能不齐，见 `cite-punct-style` 注）],
  [`"prose"`（叙述式）], [`Morris [1]`], [`Morris (2010)` / `张三（2020）`],
  [`"author"`], [`Morris`], [`Morris`],
  [`"year"`], [`2010`（仅年份）], [`2010a`（仅年份，带消歧后缀）],
  [`"full"`], [原位完整著录条目（带 `[N]` 编号）], [原位完整著录条目（带「作者，年」前缀）],
  [`none`], [不输出标注], [不输出标注],
)

各值的完整说明见 #arg-ref("gb7714", "cite-form")[`cite-form`]。上表直接列出同一条文献在各形式下的结果，不再重复运行内容相同的示例。

== 引用补充信息（页码、章节） <cite-supp-section>

GB/T 7714 正文引用后常跟页码或章节，写作 ```typ @key[页码]```（等价于 ```typ #cite(<key>, supplement: [页码])```）。两制的形式都是「页码排在标注*之外*、以上标承接」：

- 顺序编码制：`[1]`#super[260] —— 标号与页码一并上标；
- 著者-出版年制：`（张三，2020）`#super[25] —— 圆括号行内，页码上标跟在括号之后。

这由 #arg-ref("gb7714", "cite-supplement-style")[`cite-supplement-style`] 控制。默认值 `auto` 在两种标引体系下均采用 `"split"`（页码位于标注外）。如需将页码置于标注内，可设为 `"compact"`：顺序编码制显示 `[1:260]`，著者-出版年制显示 `（张三，2020：25）`。

#demo("引用附页码")[```typ
#show: gb7714
引文见@Morris2010[260]；跨页见@Morris2010[260-329]。
#bibliography(refs, keys: [@Morris2010])
```]

多键引用需要分别附加补充信息时，可在每个 `@key` 后分别写 `[..]`，即 `@key[supp]`（直接书写或置于 `#cite[..]` 中均可）：

```typ
@a[111]@b[222]            // 输出 [1]¹¹¹[2]²²²，每条引用使用自己的页码
#cite[@a[111]@b[222]]     // content 写法的输出相同
```

也可用数组形式的 `supplement` 统一给出。数组按位置对应各条引用，引用自身所带的补充信息优先，单值只用于第一条；空位和去重规则见 #arg-ref("cite", "supplement")[`cite.supplement`]。带补充信息的键不参与区间压缩，各自保留编号。

=== 多次引用同一文献：页码在方括号外 <cite-repeat-page>

顺序编码制下，同一文献被多次引用时，*每次都标首次引用的那个序号*，引文页码写在方括号*外*——国标 §9.2.1.3：

#quote(block: true)[多次引用同一著者的同一文献时，在正文中标注首次引用的序号，并在序号的「\[\]」外著录引文页码。在文献表中，此文献不重复标注引文页码。]

本包会为同一 `key` 保持相同序号，`[..]` 中的页码显示在方括号外。

```typ
正文乙 @li。                                   // 输出 [2]
……“方针”指“引导事业前进的方向和目标”@li[354]。  // 输出 [2]³⁵⁴，页码在括号外
第三次引用 @li[12]。                            // 输出 [2]¹²
```

对同一图书多次引用、且引文页码不同时，将每次定位写在正文的 `[..]` 中，不要把某次引文页码固定写入该图书的 `pages`。期刊论文、图书章节等析出文献的 `pages` 是文献自身的起讫页码，应保留；它和正文引用到的具体页码不是同一信息。

本包分别使用两处数据，不会因为正文附了页码就自动删去条目的 `pages`。图书误填了某一次引文页码时，应更正文献数据；析出文献在文献表显示完整页码、正文显示其中某一页，则是正常情况。

== 多键合并与范围压缩

顺序编码制下，相邻引用合并、连续编号自动压缩为范围，非连续则并列：

#demo("多键合并与范围压缩")[```typ
#show: gb7714
连续的三个编号@a@b@c 合并为编号范围；不连续的编号@a@c 分别列出。
#bibliography(bytes("@book{a, author={甲}, title={书一}, publisher={P}, address={B}, date={2020}}
@book{b, author={乙}, title={书二}, publisher={P}, address={B}, date={2021}}
@book{c, author={丙}, title={书三}, publisher={P}, address={B}, date={2022}}"))
```]

压缩阈值由 `cite-compress-min` 控制：

```typ
gb7714(.., cite-compress-min: 4) // 至少 4 个连续编号才压缩，3 个仍写作 [1,2,3]
```

=== 禁用合并：`cite-merge: false` 与单次 `merge: false`

默认 #arg-ref("gb7714", "cite-merge")[`cite-merge: true`]，相邻引用合并、连续编号压缩为范围。要让引用各自独立成方括号、不合并也不压缩，全局设 `gb7714(.., cite-merge: false)`：

#demo("禁用合并")[```typ
#show: gb7714(cite-merge: false)
相邻的三个引用@a@b@c 分别显示，不合并，也不压缩为范围。
#bibliography(bytes("@book{a, author={甲}, title={书一}, publisher={P}, address={B}, date={2020}}
@book{b, author={乙}, title={书二}, publisher={P}, address={B}, date={2021}}
@book{c, author={丙}, title={书三}, publisher={P}, address={B}, date={2022}}"))
```]

单次设置 `merge: false` 只拆开当前引用。其他相邻引用仍按默认规则合并和压缩：

```typ
#cite(<a>, <b>, merge: false)    // 输出 [1][2]，本次调用中的两条引用分开
#cite(<a>, merge: false) @b      // 输出 [1][2]
#cite(<a>, merge: false) @b @c   // 输出 [1][2-3]；b、c 仍会合并
```

组内编号或条目的次序由 #arg-ref("gb7714", "cite-sort-by")[`cite-sort-by`] 控制：顺序编码制默认按编号升序；2025 版著者-出版年制按责任者和年份排序；2015、2005 版保持书写顺序。排序规则见@sort-section。

#callout(kind: "note", title: "什么算“相邻”")[
  如果引用之间只有空格、源码换行（Typst 将其视为空格）或自动换行，则这些引用视为相邻并合并。显式 ```typ \``` 换行或中间插入其他文字会中断分组。例如，```typ @a@b\ @c@d``` 分别显示 ```typc [1-2]``` 和 ```typc [3-4]```，不会合并为 ```typc [1-4]```。
]

=== 著者-出版年制的年份折叠：`cite-collapse-date`

著者-出版年制合并引用多篇文献时，排序后著者标签相同的相邻条目自动合并：著者仅显示一次，年份连续列出。这相当于 CSL 的 `collapse="year"`（社区版 2015 和 2025 CSL 均已启用）：

#demo("年份折叠")[```typ
#show: gb7714(style: "author-date")
同著者两篇@zh2020@zh2021 与他人一篇@li2021 合引；
同著者同年经消歧后缀连列@wangA@wangB。
#bibliography(bytes("@book{zh2020, author={张三}, title={书一}, publisher={P}, address={B}, date={2020}}
@book{zh2021, author={张三}, title={书二}, publisher={P}, address={B}, date={2021}}
@book{li2021, author={李四}, title={书三}, publisher={P}, address={B}, date={2021}}
@book{wangA, author={王五}, title={书四}, publisher={P}, address={B}, date={2022}}
@book{wangB, author={王五}, title={书五}, publisher={P}, address={B}, date={2022}}"))
```]

判断条件、`supplement` 的处理和参数说明见 #arg-ref("gb7714", "cite-collapse-date")[`cite-collapse-date`]。

== 正文标注的全角与半角标点 <cite-punct-section>

正文引用标注中的逗号、冒号、分号和圆括号可以使用半角（`,` `:` `;` `(` `)`）或全角（`，` `：` `；` `（` `）`），由 #arg-ref("gb7714", "cite-punct-style")[`cite-punct-style`] 统一控制。该参数适用于以下位置：

#table(columns: (auto, 1fr),
  table.header(repeat: true, [位置], [半角 / 全角]),
  [著者-出版年制圆括号及其内逗号], [`(Zhang, 2020)` / `（张三，2020）`],
  [多键之间分号、补充信息冒号], [`(A, 2020; B)` / `（A，2020；B）`],
  [顺序编码制多键逗号], [`[1,3]` / `[1，3]`],
)

顺序编码制标注的括号由 #arg-ref("gb7714", "cite-numbering-style")[`cite-numbering-style`] 控制，连号由 #arg-ref("gb7714", "cite-range-separator")[`cite-range-separator`] 控制，默认 `-`。它们不由 `cite-punct-style` 改写；参考文献表的括号另由 `bib-numbering-style` 控制。

取值分三类：*按语言选择*（推荐，`by-doc-*` 随文档语言，`by-entry-*` 随被引条目语言）、*固定设置*（`"half"` / `"half-with-space"` / `"full"`）和*按标引体系分别设置的字典*。`-and-style` / `-no-space` / `-with-space` 后缀用于控制间距；默认值 `"by-doc-and-style"` 适合中文文档。完整取值见 #arg-ref("gb7714", "cite-punct-style")[`cite-punct-style`]。

它和 #arg-ref("gb7714", "cite-terms-lang")[`cite-terms-lang`] 使用相同的语言来源：`by-doc(-*)` 按文档语言，`by-entry(-*)` 按条目的 `langid`。因此，西文文档引用中文文献时，前者使用半角标点，后者使用全角标点。参考文献表的标点由 #arg-ref("gb7714", "bib-punct-style")[`bib-punct-style`] 单独控制。

```typ
// 著者-出版年制整段上标时 CJK 全角括号基线 / 字号易与 Latin 不齐，可强制半角规避
#show: gb7714(style: "author-date", cite-punct-style: "half")
```
- 关键字 `auto` 等价于默认字符串 `"by-doc-and-style"`，仍可传。

=== 标注两侧的空格：`cite-adjacent-space`

中文正文常写成 `见 @key 所述`，因为 `@key所述` 会把后面的汉字识别为标签名的一部分。#arg-ref("gb7714", "cite-adjacent-space")[`cite-adjacent-space`] 控制这些源码空格：默认值 `auto` 会删除引用与相邻 CJK 字符之间的空格，并保留西文词间空格。因此中文输出为 `见[1]所述` 或 `见（张三，2020）所述`。`true` 始终保留，`false` 始终删除。上标编号前的空格仍按 Typst 原生规则处理。

#demo("标注两侧的空格：中文邻字不留")[```typ
#show: gb7714(style: "author-date")
见 @Morris2010 所述，另见 @Sunstein1996 。
#bibliography(refs, keys: [@Morris2010@Sunstein1996])
```]

西文邻字的空格照留（`see @key here` 仍是 `see (Smith, 2021) here`）；本手册正文另有 cjk-spacer 调整中西间距，演示里就不混排了。

== 脚注与尾注引用 <note-section>

`note` 控制引用位置：`"foot"` 使用脚注，`"end"` 使用尾注，`none` 保留在正文中。重复引用和编号格式等设置使用 `note-*` 参数，脚注和尾注共用这些参数。

```typ #cite(note: "foot")[@key]``` 把单次引用降为脚注，参考文献条目直接渲染在脚注里，常见于古籍、法律文书等非主体文献的轻型引用：

```typ
古希腊三贤是民主制度的坚决反对者#cite(note: "foot")[@Morris2010]
```

设置 `gb7714(.., note: "foot")` 后，全文默认使用脚注引用。

文献第一次出现在脚注中时显示完整著录，格式由 `style.bib` 决定。重复引用由两个相互独立的参数控制：

- #arg-ref("gb7714", "note-repeat-style")[`note-repeat-style`]：重复引用时的著录形式；
- #arg-ref("gb7714", "note-ibid")[`note-ibid`]：紧邻重复是否简化为“同上”。默认 `auto` 在 2005、2015 版启用，在 2025 版关闭；关闭后采用 `note-repeat-style` 指定的形式，只有默认的 `"number"` 才显示“同③”。

默认组合随版本切换：`version: 2015` 使用 `"number"` 和「同上」规则，与社区 2015 note CSL（china-national-standard-gb-t-7714-2015-note）一致；`version: 2025` 默认关闭 `note-ibid`，重复引用统一显示「同③」，与社区 2025 note CSL 一致：

```
// version: 2015（默认 version: 2025 无「同上」，②处也是「同①」）
① 张三. 现代汉语研究[M]. 北京: 商务印书馆, 2020.   // 首次完整著录
② 同上: 25.                                        // 紧邻重复；2025 版显示“同①: 25.”
③ Smith J. Style Manual[M]. New York: Press, 2019.
④ 同①: 130.                                        // 隔开后再次引用，指向首次注释
```

社区 CSL 注释样式不能生成带圈注号的“同③”，本包补充了这一写法。`note-repeat-style` 有四种取值；“同上”由 `note-ibid` 单独控制：

#table(columns: (auto, 1fr, auto),
  table.header(repeat: true, [取值], [重复引用的形式], [引文页码]),
  [`"full"`], [整条著录（GB §9.2.1.3「重复著录」）], [完整著录中的页码位置],
  [`"number"`], [引用首次注号，如“同③”], [中日 `: 页码`、其余 `, 页码`],
  [`"shortened"`], [缩略著录：责任者、题名和文献类型标识], [作为独立著录项],
  [`"reuse"`], [复用首次注号，不新增脚注], [不支持新的引文页码],
)

例如，重复引用时保留完整著录并禁用“同上”：

```typ
#show: gb7714(note: "foot", note-repeat-style: "full", note-ibid: false)
```

=== 单次脚注的格式设置

`cite` 的 `footnote-punct-style`、`footnote-custom-punct` 分别控制本次脚注著录的标点样式和具体符号；`footnote-url-break-every` 调整网址断行；`footnote-related-indent` 调整双语条目第二语言版本的缩进。默认 `auto` 继承相应设置或使用自动缩进，仅在 `note: "foot"` 时生效。`punct-style` 则控制正文标注的标点，二者不要混用。

```typ
#cite(<key>, note: "foot", footnote-punct-style: "half-with-space")
```

=== 重复引用的页码和文字

首次引用或 `note-repeat-style: "full"` 时，`supplement` 优先作为引文页码；未提供时才使用条目的 `pages` 字段。使用“同上”“同③”或 `"shortened"` 时，页码只取自 `supplement`。引语语言由 `cite-terms-lang` 决定，默认随被引条目；中文显示“同上”“同③”，英文显示 `Ibid.`、`See note ③`。中日文在页码前使用冒号，其他语言使用逗号。缩略形式的页码作为独立著录项，如 `张三. 甲书[M]. 77.`。文字和分隔符可通过 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 修改。

#callout(kind: "warning", title: "使用限制")[
  - “紧邻”按脚注引用的顺序判断：上一条脚注引用具有相同的 key，即可适用“同上”。中间的普通脚注不影响这一判定。
  - 两次引用的页码相同时，“同上”不重复页码；上次提供了页码、本次未提供时，改用“同N”，避免让读者误以为仍引用上次的页码。
  - “同③”的序号取自脚注计数器。按章重置计数器时，也需设置 `note-repeat-reset`，否则可能引用上一章的注号。
  - `"reuse"` 复用全文首次引用的注号，不新增脚注，也不受 `note-repeat-reset` 影响。重复引用需要附带新页码时，使用 `"number"`。
]

脚注默认使用 Unicode 带圈数字。使用默认模式时，可在 `show: gb7714(...)` 之后通过 ```typ #set footnote(numbering: "1")``` 指定其他编号样式，“同③”中的编号也会随之改变。

设置 `note-numbering-style: (circled: "quan")` 可使用 quan 包：默认 ①～⑩ 仍取自字体，其余编号由文字和圆圈组合绘制。此时由 quan 接管编号显示，覆盖范围和样式用其 `quan-init`、`quan-style` 调整。详细取值见 #arg-ref("gb7714", "note-numbering-style")[`note-numbering-style`]。

quan 通常以 ⑩ 为尺寸和基线参照，较宽的数字会缩小到圆内。默认几何且未指定描边、圆角时，已收录字体按常规、粗体分别校准左右、上下和斜向的线厚，外圈保持正圆，内孔透明；未收录字体使用基础估计。手动指定粗细可用 `quan-style(stroke: ...)`。

数字比例匹配默认关闭。`quan-style(digit-fit: true)` 会根据字体组合分别调整自绘数字的宽高：已校准的 0～99 以原生数字高度为目标，必要时收窄宽度以留出圈内空间；更长的整数和负数等比缩放，未收录组合使用近似值。圈线校准与此开关独立，直接使用 Unicode 的编号不受影响。

开启匹配通常能改善高度和内部间距，但宋体等字体的自绘数字可能明显偏窄，小字号尤为明显，因此保留为按需开启的试验功能。默认模式保留普通数字的宽高比例，只调整字号和字距；关闭并不保证内部数字彼此分离，默认负字距也可能使数字连接。

匹配生效时不使用 `kern`。显式设置 `size`、`height`、`inset`、`outset`，或清空 Unicode 覆盖范围，会停用匹配；可用 `digit-fit: false` 显式关闭。

=== 多篇合并脚注 <footnote-merge-section>

相邻的标记式引用（如 `@a@b`，中间可以有空格）会合并为一个脚注。脚注中的条目以分号分隔，末尾只保留一个句点。全局参数为 #arg-ref("gb7714", "cite-merge")[`cite-merge`]；单次引用可用 `merge: false` 分开。

同一脚注中的每条引用分别应用重复引用规则，不进行去重：

```typ
一 @a@b 二。词 @a 后。三 @a @a[25] 四。
// ① 甲…; 乙….         相邻引用合并为一个脚注
// ② 同①.              上一条是合并脚注，不能简化为“同上”
// ③ 同上; 同上: 25.   同组内的重复引用分别判断
```

`#cite(<a>, <b>)` 一次调用内的多个键会合并为一条脚注；相邻的两次 `#cite()` 也会合并。需要分别显示时，可设置 `merge: false`，或将全局 `cite-merge` 设为 `false`。

#callout(kind: "note", title: "「同③」指向合并脚注时的语义")[
  重复引用指向的首次注释若为合并脚注（一注多条），「同③」按常见 CSL 样式的处理方式指向*整条脚注*，具体文献须结合页码与上下文判断。若需明确指出文献，可将 ```typc note-repeat-style``` 设为 `"shortened"`，改用缩略著录。另外，合并脚注中 `"reuse"` 会自动按 `"number"` 处理，因为同一脚注只能设置一个原生标签。
]

=== 章界重置：`note-repeat-reset` <note-repeat-reset-section>

论文常按章重编脚注号，这时“同上/同③”的判定也必须以章为界，否则跨章引用会指错注。#arg-ref("gb7714", "note-repeat-reset")[`note-repeat-reset`]（#BibLaTeX `citereset` 的对应物）接收一个 *selector*（也可取 `"per-page"`，用于幻灯片，见@touying-section）。每个匹配位置都是分界：重复引用只在最近的分界之后判定，因此不会跨章使用“同上”，每章首次引用均完整著录，“同③”也只引用本章脚注号：

```typ
#show: gb7714(
  note: "foot",
  version: 2015,                             // 示例中的紧邻重复使用“同上”
  note-repeat-reset: heading.where(level: 1),   // 一级标题为界
)
// 脚注编号由文档设置；本包不修改编号计数器：
#show heading.where(level: 1): it => { counter(footnote).update(0); it }

= 第一章
…@a      // ① 完整著录        …@a[11]  // ② 同上: 11.
= 第二章                  // 脚注号回到①，判定同步清零
…@a[25]  // ① 完整著录；页码 25 写入著录中的页码位置
…@a      // ② 同①，指本章的注①
```

本参数仅控制重复引用的判定范围。脚注编号是否重新开始由文档自身设置；两者应采用相同的分界。selector 可使用标题或自定义标签，见 #arg-ref("gb7714", "note-repeat-reset")[`note-repeat-reset`]。

=== 尾注模式：条目集中列于文末 <note-end-section>

`note: "end"` 与脚注模式使用相同的引用规则：正文显示带圈的上标注号，完整著录则集中排在 ```typ #bibliography(..)``` 所在位置。该*尾注列表*取代参考文献表，不再另列一份文献表。首次著录、重复引用、合并引用、`note-repeat-reset` 的章节重置和编号样式均与脚注模式一致，区别仅在著录位置；「同③」中的 ③ 指尾注号，而不是脚注号。

```typ
#show: gb7714(note: "end", version: 2015)

正文甲#super[①] 紧邻乙#super[②] ……

= 注释
#bibliography(read("refs.bib"))
// ① 完整著录…    ② 同上.    ③ 完整著录…    ④ 同①.  （尾注列表，取代参考文献表）
```

*分章尾注*：为每章设置一个命名列表；用 `set-bib-label` 指定引用归属，并以 ```typ #bibliography(.., label: ..)``` 在章末生成列表。各列表仅收录归属于本章的尾注（与@print-bib 的多列表分区采用同一机制）：

```typ
#set-bib-label("ch1")
第一章正文……@a @b
== 第一章注释
#bibliography(read("refs.bib"), label: "ch1", title: none)

#set-bib-label("ch2")
第二章正文……@c
== 第二章注释
#bibliography(read("refs.bib"), label: "ch2", title: none)
```

显式 `title` 会作为尾注列表的一级标题；默认（`auto`）*不*自动补「参考文献」——尾注列表通常跟在用户自己的章节标题（如 `= 注释`）下。

章末尾注也可用 Typst 0.15 的原生 `target` 分区：为每章设置一个按位置划界的 selector（如下例的 `.before(<ch2>)` / `.after(<ch2>)`）。标签位于章标题时，宜使用 `before` / `after`；`within` 仅在标签包住整段正文时才能选中章内引用。本包按照 `target` 的选区生成各章尾注，效果与上述 `label` 方案相同：

```typ
#show: gb7714(note: "end", version: 2015)
= 第一章 <ch1>
正文……@a @b
= 第二章 <ch2>
正文……@c
== 第一章尾注
#bibliography(read("refs.bib"), target: selector(std.cite).before(<ch2>))  // ①②
== 第二章尾注
#bibliography(read("refs.bib"), target: selector(std.cite).after(<ch2>))   // ③
```

#callout(kind: "note", title: "尾注模式的限制")[
  - *注号跨列表连续*：分章尾注的编号不会逐章从①重新开始。当前没有按章重置编号的参数；
  - *`target` 需要 Typst 0.15 或更高版本*。Typst 0.14 可改用 `set-bib-label` 和 `label` 分区。
]

#callout(kind: "note", title: "与原生 note 样式的区别")[
  二者都把引用放进脚注，但著录规则不同，不宜混用：
  - 本包 `note`（及 `#cite(note: "foot")`）：脚注里按国标 GB/T 7714 著录完整条目；
  - 原生 CSL note 样式：传入相应 CSL 的字节内容或本包未映射的原生样式名，由 Typst 的 CSL 引擎渲染。

  字符串 `"gb-7714-2015-note"` 已由本包映射到自身的 2015 脚注实现，不能用它测试原生引擎；要明确指定 CSL 文件，可用 `bibliography(style: read("style.csl", encoding: none))`。
]

== 多列表与分章参考文献表 <multi-bib-section>

需要把法规、古籍、学术文献等分区呈现时，多次调用 `bibliography` 即可，每次调用是一个独立列表：

```typ
== 学术文献
#bibliography(read("scholar.bib"), title: none)

== 法律法规
#bibliography(read("law.bib"), title: none)
```

来源不重叠时，引用会自动归入相应列表。默认情况下（无 `label`，且 `group: auto`），多个列表连续编号；各列表需要从 [1] 重新编号时，可使用命名列表或 Typst 0.15 的 `group: none`。Typst 0.15 还可用 `target: selector(std.cite).within(<ch1>)` 指定列表收录范围，并用 `group:` 控制编号分组。

同一份 `.bib` 要分区切换归属时，用 `label` 命名列表配合 ```typ #set-bib-label("..")```：

```typ
正文默认归属主列表 @key1 …
#set-bib-label("法规")
这之后的引用归属“法规”列表 @key2 …
#set-bib-label(none) // 切回主列表

#bibliography(read("refs.bib")) // 主列表
#bibliography(read("refs.bib"), label: "法规", title: [法律法规]) // 命名列表，独立编号
```

单条引用也可用 ```typ #cite(<key>, bib-label: "法规")``` 临时指定列表。列表生成见@print-bib，列表切换见@set-bib-label。

#callout(kind: "warning", title: "两种多列表模式不可混用")[
  - 命名列表模式（`label:` 配合 `set-bib-label`）：0.14 和 0.15 均可使用，每个列表独立编号；
  - 原生列表模式（多次无 `label` 调用，或使用 `target:`、`group:`、原生 CSL `style:`）：条目归属和编号方式与 Typst 0.15 一致；Typst 0.14 仅支持一个原生文献表。

  两种模式不能混用，否则会报错。
]

在原生列表模式下，省略 `group`（默认 `auto`）时全文连续编号；设置相同的 `group` 时，这些列表共享编号；设置 `group: none` 时，各列表独立编号：

```typ
= 第一章
内容 @a。
#bibliography(read("ch1.bib"), group: "正文", title: [第一章文献]) // [1]

= 第二章
内容 @b。
#bibliography(read("ch2.bib"), group: "正文", title: [第二章文献]) // 接续 [2]
```

各多列表能力在两个 Typst 版本上的支持情况：

#table(columns: (auto, 1fr, 1fr), align: (left, center, center),
  table.header(repeat: true, [能力], [typst 0.14], [typst 0.15+]),
  [单参考文献表], [支持], [支持],
  [命名列表（`label:` 配合 `set-bib-label`，各自重起编号）], [支持], [支持],
  [使用原生 `target:` / `group:` 分配列表], [不支持], [支持],
  [列表级原生 CSL 样式（`style:` 传 CSL 名 / bytes）], [仅单表], [支持],
  [`note` 脚注引用], [支持], [支持#super[\*]],
)

#super[\*] Typst 0.15 中，`note` 可与 `target:` 同时使用。脚注内容仍由本包渲染，文献则进入目标列表。原生 CSL 样式不能与本包的 GB 脚注格式混用。没有 `target` 的多个未命名列表会连续编号。

=== 筛选文献与完整收录 <bib-filter-section>

`bibliography` 默认收录已引用文献。设置 `full: true` 可同时收录未引用文献，适合阅读书目；其排列仍受排序设置控制，见 @sort-section。

筛选参数只改变文献表显示的条目，不改变正文中的引用编号。分表展示时，应确保各表合起来包含全部已引用文献。

#table(columns: (auto, 1fr),
  table.header(repeat: true, [参数], [筛选方式]),
  [`entry-type`], [按数据中的条目类型，如 `"book"` 或 `("book", "article")`],
  [`mark`], [按文献类型标识代码，如 `"M"` 或 `("M", "J")`；载体标识不参与比较],
  [`keyword`], [匹配 `keywords` 字段中的子串，区分大小写],
  [`filter`], [自定义判断函数 `entry => bool`，字段通过 `entry.fields` 读取],
  [`keys`], [指定条目键，如 `[@a@b]` 或 `("a", "b")`；指定后忽略其他筛选条件],
)

```typ
// 仅显示已引用的图书
#bibliography(read("refs.bib"), entry-type: "book", title: [参考图书])
// 收录含指定关键词的全部文献，包括未引用条目
#bibliography(read("refs.bib"), full: true, keyword: "综述", title: [相关阅读])
```

筛选与独立编号是两件事。需要各表重新编号时，使用 @multi-bib-section 的列表设置；仅需将指定文献排列在表首时，使用 `sort-keys`，其余条目仍会保留。各参数的定义见 @print-bib。

== 在 Touying 幻灯片中使用 <touying-section>

本包可直接用在 #link("https://github.com/touying-typ/touying")[Touying] 幻灯片里：把主题的 show 规则放外层、本包的放内层即可，正文引用、参考文献表、脚注引用、多列表、跨片消歧等照常工作：

```typ
#import "@preview/touying:0.8.0": *
#import themes.simple: *
#show: simple-theme.with(aspect-ratio: "16-9")
#show: gb7714(version: 2025)      // 本包规则写在内层
= 幻灯片标题
正文引用 @key。
= 参考文献
#bibliography(read("refs.bib"))
```

=== 文献表位于 `#pause` 页面时编号偏大

使用 `#pause` 时，Touying 会为一张幻灯片生成多个逐步显示的页面。文献表即使尚未显示，也可能参与排版和编号。因此，文献表与 `#pause` 位于同一张幻灯片时，编号可能重复累计，导致首条文献不从 `[1]` 开始。

这不是本包特有的：原生 `#bibliography` 在同样的写法下同样偏大（Typst 0.15 起多个文献表能编译通过，以前会直接编译失败）。麻烦之处在于*编译不报错，数字悄悄错*。相关讨论见 #link("https://github.com/touying-typ/touying/issues/415")[touying\#415]。

可根据页面结构选择以下处理：

- 将文献表放在不含 `#pause` 的独立幻灯片中。
- 使用 ```typ #only("h", bibliography(read("refs.bib")))```，只在当前显示阶段生成文献表。其他阶段不保留文献表的位置，页面内容可能随之移动。
- 将本包提供的 `gb7714-frozen-states` 加入 Touying 的 `frozen-states` 设置，使各显示阶段从相同的编号状态开始。此方法仅适用于本包。

```typ
#show: simple-theme.with(config-common(
  frozen-states: gb7714-frozen-states,   // `#import ".." as omni` 时写 omni.gb7714-frozen-states
))
```

设置后，含 `#pause` 的幻灯片也能从 `[1]` 开始编号，并保留文献表的位置。此设置仅用于 Touying 的逐步显示。

如果只有正文引用位于 `#pause` 页面，而参考文献表位于其他页面，则无需采用上述处理。本包根据 query 确定编号，编号与重复渲染次数无关。

=== 脚注引用配 `#pause`：`note-repeat-reset: "per-page"`

用脚注引用（```typ note: "foot"```）又用了 `#pause` 时，「同上」的重复判定会被上面同样的「逐 subslide 重渲」搞乱（首次引用被误判成重复、显示成「同上 / 同①」）。给 #arg-ref("gb7714", "note-repeat-reset")[`note-repeat-reset`] 设 ```typc "per-page"```（每页重置判定域，Touying 里一张 subslide 就是一页）即可：

```typ
#show: gb7714(version: 2025, note: "foot", note-repeat-reset: "per-page")
```

若希望每次均完整著录，可同时设置 `note-repeat-style: "full", note-ibid: false`，避免旧版默认的“同上”规则覆盖完整形式。

`note-repeat-reset` 只控制重复引用的判断范围。脚注是否随 `#pause` 逐步出现由 Touying 决定；0.8.0 起支持这一行为，早期版本的限制见 @touying-074。

=== Touying 自家的 `bibliography-as-footnote`

Touying 的 `magic.bibliography-as-footnote` 也可以将引用转为脚注。与本包配合时，应将其 show 规则写在 `gb7714` 之后；仅在主题中设置 `show-bibliography-as-footnote: true` 不会生效：

```typ
#show: gb7714(version: 2025, style: "author-date")
#show: magic.bibliography-as-footnote      // 写在本包之后
```

使用这一方法时，文档中仍须调用 `bibliography` 供 Touying 读取文献；不需要显示时可使用 `hide`。一般情况下直接设置本包的 `note: "foot"` 即可。

=== 用 Touying 0.7.4 及更早的版本 <touying-074>

Touying 0.8.0 要求 Typst ≥0.15。使用 0.7.4 时，文献表独立成片、`only("h", ..)` 和冻结编号状态的方法仍适用；下面列出脚注逐步显示、原生脚注转换和 article mode 的主要差异。完整示例需使用其注明的 Touying 版本。

*脚注与逐步显示*：Touying 0.7.4 会在第一阶段显示全部脚注，还可能将首次引用误判为重复引用。`note-repeat-reset: "per-page"` 只能解决后一个问题。此版本应避免在同一张幻灯片中同时使用脚注引用和 `#pause`，或启用讲义模式 `config-common(handout: true)`。两版输出对比如下：

#table(columns: (auto, 1fr, 1fr), align: (center, left, left),
  table.header(repeat: true, [子片], [Touying 0.7.4], [Touying 0.8.0]),
  [1], [①②③ 三条全部排出], [只有 ①],
  [2], [①②③（同子片 1）], [①②],
  [3], [①②③（同子片 1）], [①②③],
)

同一份三次引用、两处 `#pause` 的幻灯片，两侧都设了 ```typc note-repeat-reset: "per-page"```，所以两侧的每条脚注都是完整著录。若不设 `per-page`，0.7.4 上从子片 2 起首次引用还会被误判成重复，排成「同①　同②　See note ③」。

*二、Touying 自家的 `bibliography-as-footnote` 是另一套写法。* 0.7.4 把文献表元素交给它，收集表另用 `magic.bibliography()` 排；0.8.0 改成布尔开关并删掉了 `magic.bibliography()`，两版互不通用。0.7.4 的形态是：

```typ
#show: gb7714(version: 2025, style: "author-date")
#show: magic.bibliography-as-footnote.with(none)   // 0.7.4：传 none，写在本包之后
= 收集表
#magic.bibliography(title: "参考文献")
// Touying 靠「文档里存在一个 bibliography」解析引用键，用 place(hide(..)) 让它存在而不占版面
#place(hide(bibliography(read("refs.bib"), title: none, full: true)))
```

同样出 GB 著录（脚注体与收集表都是）。上一节讲的「官方开关静默失效」是 0.8.0 才有的问题，0.7.4 没有那个开关。

*三、article mode 是 0.8.0 的新功能*，0.7.4 没有。

#block(fill: luma(245), inset: 8pt, radius: 3pt, width: 100%)[
  更多可直接编译的完整示例（顺序编码制、著者-出版年制、暂停页、脚注、多文献表、讲义、消歧和 CSL JSON 等），见项目仓库的 `touying-examples/` 目录。
]

== 局部用法：单独设置内容块 <local-config-section>

```typ #show: gb7714(..)``` 不必作用于整篇文档。将其写入内容块 ```typ #[ … ]``` 后，设置仅在该块内生效；块内引用和参考文献表使用独立编号。因此，同一文档可以使用多组设置，包括 ```typ note```、```typ note-repeat-style``` 和 ```typ style```：

```typ
#[
  #show: gb7714(style: "numeric")
  第一部分按顺序编码制 @key1 @key2。
  #bibliography(read("a.bib"))
]

#[
  #show: gb7714(style: "author-date")
  第二部分按著者-出版年制 @key3。
  #bibliography(read("b.bib"))
]
```

上例分别使用顺序编码制和著者-出版年制，两块内容的设置与编号相互独立。写在内容块之外的 `#show: gb7714(..)` 则作用于后续全文。

局部用法与命名列表的取舍如下：

- 只想分区切换样式或引用配置（`style`、`note-repeat-style`、`bib-numbering-style` 等），使用 @local-config-section 所述的内容块作用域；
- 分章独立编号可使用 @multi-bib-section 所述的命名列表（`label:` 配合 `set-bib-label`），Typst 0.15 也可使用 `group: none`；
- 两者可叠加：内容块里照常调用命名列表、`target:` 或 `group:`。

== 条目语言与多语言排版 <lang-section>

本包按条目的 `langid` 选择著录术语，并在启用按条目语言的设置时选择标点和排序规则。文档自身的语言仍由 `set text(lang: ..)` 设置；它影响列表标题及 `by-doc-*` 参数，不能用条目语言代替。

#figure(
  image("../examples/eg8.pdf", width: 100%),
  caption: [同一文献表内，中文条目截断作「等」、西文条目作「et al」],
)

最可靠的办法是每条显式标 `langid`（或 `language`）：

```bib
@book{a, ..., langid = {chinese}}   % 也接受 zh / english / en / japanese / korean / russian / french …
```

未填写语言字段时，#arg-ref("gb7714", "entry-lang-detect")[`entry-lang-detect`] 自动识别中文、日文、韩文、俄文、法文和英文；无法识别时按英文处理。可选择以下识别方式：

#table(columns: (auto, 1fr),
  table.header(repeat: true, [`entry-lang-detect`], [行为]),
  [`"auto"`（默认）], [先扫描整份书目；含假名或日文特有汉字时使用 `accurate`，否则使用 `fast`],
  [`"fast"`], [只按字符类别判断：假名为 ja，谚文为 ko，西里尔字母为 ru，汉字为 zh，拉丁字母为 en。无需额外依赖，边缘语料准确率约 78%],
  [`"accurate"`], [结合中日特有汉字表、《百家姓》和 `glotter` 的语言模型，边缘语料准确率约 100%，首次加载约增加 0.1 s],
)

含未标注的法文条目时，显式选 `"accurate"` 或直接标 `langid`（法、英都是拉丁字母，`fast` 区分不了）。多语言混排的分组顺序由 #arg-ref("gb7714", "entry-lang-order")[`entry-lang-order`]（默认 `("zh", "ja", "ko", "en", "fr", "ru")`）控制，靠前的语种排前面。

内置列表以外的西文语种（如德文）可用 #arg-ref("gb7714", "custom-languages")[`custom-languages`] 注册语言代码，并用 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 设置本地化术语；`de` 已预置 o. A. 和 o. J.。取值形式与限制见这两个参数的链接。

=== 中西文共用标点的字体 <shared-punct-fonts>

`“ ” ‘ ’ … — – ·` 在中西文中使用相同码位，但不同字体可能采用不同字宽。CJK 字体优先时，西文题名中的引号可能显示为全宽；西文字体优先时，中文条目中的间隔号和破折号可能显示较窄。全角字符 `，。、；（）《》！？` 不受此问题影响；西文字体缺少相应字形时会自动采用 CJK 字体。

要各归各，只能按上下文分别指定字体。本包按条目语言把每一条著录包在 ```typc text(lang: ..)``` 里（见 #arg-ref("gb7714", "entry-localized-glyphs")[`entry-localized-glyphs`]），宿主一条 show 规则就能钩住：

```typ
#set text(font: ("Noto Serif CJK SC", "Libertinus Serif"), lang: "zh")   // 文档主栈：中文优先
#show text.where(lang: "en"): set text(font: ("Libertinus Serif", "Noto Serif CJK SC"))
```

这样，西文条目整体使用西文字体，中文条目继续使用文档字体。该规则作用于 `text`；正文中标记为 `lang: "en"` 的段落也会受到影响。若只需影响参考文献表，请将规则限制在参考文献表所在的内容块内。

此方法要求启用 `entry-localized-glyphs`（2015、2025 版默认启用）。设为 `false` 后不会生成 ```typc text(lang: ..)``` 包装，相应的 show 规则也无法匹配。

== 排序：参考文献表与合并引用 <sort-section>

排序参数分为两组：`bib-*` 控制参考文献表的条目顺序，`cite-*` 控制合并引用（如 `@a@b@c`）内部的顺序。著者-出版年制的参考文献表默认按责任者排序；2025 版的合并引用也按责任者排序。顺序编码制则按正文中的首次引用顺序编号。`#bibliography(sort-by: ..)` 对应文献表排序，`#cite(sort-by: ..)` 对应单次合并引用排序。

合并引用组内的次序由 #arg-ref("gb7714", "cite-sort-by")[`cite-sort-by`] 控制。`auto` 根据标引体系和标准版本确定：2025 版著者-出版年制按责任者和年份排序，2015、2005 版及顺序编码制保持书写顺序。

=== 文献表排序键 `bib-sort-by`

#arg-ref("gb7714", "bib-sort-by")[`bib-sort-by`] 指定参考文献表的排序键，可使用 `"name"`、`"date"` 和 `"title"`。`auto` 在著者-出版年制中依次按责任者、年份和题名排序，在顺序编码制中按引用次序排列。

#demo("著者-出版年制的文献表排序：先文种、再拼音字顺")[```typ
#show: gb7714(style: "author-date", full: true)
#bibliography(bytes("@book{srt-wang, author={王五}, title={乙}, publisher={P}, address={X}, date={2020}}
@book{srt-an, author={安一}, title={甲}, publisher={P}, address={X}, date={2021}}
@book{srt-brown, author={Brown, Ann}, title={Delta}, publisher={P}, address={X}, date={2019}, langid={english}}
@book{srt-zhao, author={赵六}, title={丙}, publisher={P}, address={X}, date={2018}}"))
```]

#callout(kind: "note", title: "启用排序时的文种分组")[
  使用非空排序键数组时，先按 #arg-ref("gb7714", "entry-lang-order")[`entry-lang-order`] 分组，再在组内比较排序键。`sort-by: none` 保留原顺序，不会额外按文种重排；顺序编码制的默认引用次序也不因此改变。

  设为空数组 ```typc entry-lang-order: ()``` 可关闭文种分组。此时全部条目按同一套字顺排列，例如 `Adams`、`陈明`、`Zhao`。这不符合 §9.3.2 的文种分组要求，只适合需要贴近 CSL 常见排序的场合。```typc entry-lang-order: ("en", "zh")``` 仍保留分组，只是把西文组放在中文组之前。

  于是 ```typc bib-sort-by: (("date": "descending"),)``` 下，一条 1980 年的中文文献仍排在一条 2020 年的英文文献之前。
]

=== 中文排序：拼音与笔画

中文排序也分别设置：#arg-ref("gb7714", "bib-sort-zh-by")[`bib-sort-zh-by`] 用于参考文献表，#arg-ref("gb7714", "cite-sort-zh-by")[`cite-sort-zh-by`] 用于合并引用。可选 `"pinyin"`（默认，自动注音）或 `"bihua"`（先按笔画数，再按笔顺）。

#figure(
  image("../examples/eg5.pdf", width: 100%),
  caption: [同一批中文条目分别按拼音、笔画排序（著者-出版年制）],
)

=== 西文姓名前缀：`sort-use-prefix`

西文姓名的前缀（van / von / de / della 等）默认不参与排序与正文标注，这是本包采用的默认设置（对应 #BibLaTeX 的 `useprefix=false`）：`Ludwig van Beethoven` 按 `Beethoven` 排序，正文标注作 `(Beethoven, 2020)`。不同姓名的习惯可能不同，不能只凭条目的语言推断前缀如何处理。

需要让前缀计入（排在 V 区、标注作 `(van Beethoven, 2020)`）时，设 `sort-use-prefix: true`：

```typ
#show: gb7714(style: "author-date", sort-use-prefix: true)
```

#demo("前缀计入排序：van Beethoven 排 V 区")[```typ
#show: gb7714(style: "author-date", sort-use-prefix: true, full: true)
#bibliography(bytes("@book{lvb, author={van Beethoven, Ludwig}, title={Alpha}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{adams, author={Adams, John}, title={Beta}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{zweig, author={Zweig, Stefan}, title={Gamma}, publisher={P}, address={X}, date={2020}, langid={english}}"))
```]

#arg-ref("gb7714", "sort-use-prefix")[`sort-use-prefix`] 是全局默认值，可由条目级 ```bib options = {useprefix=true}``` 或姓名级 `useprefix=..` 覆盖；其优先级见参数链接。该参数不改变参考文献表中的姓名形式，前缀位置由 #arg-ref("gb7714", "prefix-last")[`prefix-last`] 控制，姓名格式见@name-style-section。CJK 姓名没有前缀字段。

=== 手动指定排序键（覆盖自动拼音 / 笔画）

多音字、特殊排序需求下可逐条目覆盖。优先级从高到低：

#table(columns: (auto, auto, 1fr),
  table.header(repeat: true, [机制], [写法], [说明]),
  [`sortkey` 字段], [`sortkey = {Ma3 Ke4 Si1}`], [biber 现代写法，*最高优先*],
  [`key` 字段], [`key = {makesi}`], [#BibTeX 惯例，次优先],
  [`\noopsort{X}` 代理], [`author = {\noopsort{Ma3}马克思}`], [兼容传统 #BibTeX：命令不显示，排序使用 `X`],
  [（皆无）], [—], [依次使用作者、编者、题名的拼音或笔画],
)

三者都经规范化（转小写、去非字母数字）且保留声调数字 1–5，这正是多音字的解法。例如姓「单」应读 shàn 而非 dān：

```bib
@book{shan2020,
  author  = {单某某},
  title   = {...},
  sortkey = {Shan4 Mou3 Mou3},   % 强制按 shàn 排，不被误注成 dān
}
```

`\noopsort{X}` 是 #BibTeX 使用的排序辅助宏，接收一个参数但不显示内容，通常定义为 `\providecommand{\noopsort}[1]{}`。本包将其参数用作排序键：`author = {\noopsort{Ma3}马克思}` 显示“马克思”，按 `Ma3` 排序。新建条目宜直接填写 `sortkey`；`\noopsort` 用于兼容已有文献库。

另有*参数* `sort-keys`（注意带 s，与本节的条目字段 `sortkey` 是两回事）把指定条目提到表首：```typ #show: gb7714(sort-keys: [@important1@important2])```，其余条目照常排在后面，见 #arg-ref("gb7714", "sort-keys")[`sort-keys`]。

== 同责任者的紧邻替代：`creator-idem`

*相邻*条目为同一责任者时，从第二条起可用指定字符串替换整个责任者部分。这是 MLA、Chicago 等样式采用的写法，一些中文社科期刊的西文条目也会使用：

#demo("紧邻同责任者替代")[```typ
#show: gb7714(creator-idem: "———", full: true)
#bibliography(bytes("@book{crane1972, author={Crane, Diana}, title={Alpha}, publisher={P}, address={X}, date={1972}, langid={english}}
@book{crane1987, author={Crane, Diana}, title={Beta}, publisher={P}, address={X}, date={1987}, langid={english}}
@book{doe2000, author={Doe, Jane}, title={Gamma}, publisher={P}, address={X}, date={2000}, langid={english}}"))
```]

默认值为 `none`，不替代责任者。比较依据是完整责任者名单，而非截断后的显示文本；只比较相邻条目，佚名和双语条目的第二语言版本不参与替代。

== 双语关联著录（中外文对照）<related-section>

同一文献的两个语言版本（如朝鲜文原作与中译名、中文与英译）可合并为一条著录：主条目下方接续渲染第二语言版本，共用一个编号，而非各占一条。这是 GB/T 7714 对中外文对照文献的著录方式。

写法：在第一语言条目上加 `related` 与 `relatedtype` 两个字段，指向第二语言条目。正文只引主条目，第二条目接续在缩进续行、不单独编号：

#demo("双语关联著录")[```typ
#show: gb7714
参见双语对照著录@primary。
#bibliography(bytes("
@book{primary, author={이병목}, title={도서관법규총람: 제1권},
  address={서울}, publisher={구미무역 출판부}, year={2005}, pages={67--68},
  related={secondary},       % 指向第二语言条目的 key
  relatedtype={lanversion}}  % 固定写法（不区分大小写），触发语言版本合并
@book{secondary,             % 第二语言条目，无需单独引用
  author={李炳穆}, title={图书馆法规总览: 第1卷},
  address={首尔}, publisher={九美贸易出版部}, year={2005}, pages={67--68}}
"))
```]

续行缩进由 `bibliography(.., related-indent: ..)` 控制（`auto` 跟随编号宽度）。要关闭合并、让两条各自独立编号，设 #arg-ref("gb7714", "show-related")[`show-related: false`]。

== `@set`：将多部分或多卷合并为一条 <set-section>

丛书的多卷、文集的多篇等要合并成一条著录、共用一个编号时，用 `@set` 条目（与上面的双语 `related` 类似，但用于同语言多成员）。引用 `@set` 得单个编号，各成员完整著录、第 2 个起悬挂续行、成员不单独占号：

#demo("@set 多卷合并")[```typ
#show: gb7714
参见丛书@series。
#bibliography(bytes("
@set{series, entryset={vol1, vol2}}   % 成员用逗号/空白分隔；支持嵌套 @set
@book{vol1, author={张三}, title={某丛书: 第一卷}, year={2020}, publisher={P}, address={B}}
@book{vol2, author={李四}, title={某丛书: 第二卷}, year={2021}, publisher={P}, address={B}}
"))
```]

直接引用成员（```typ @vol1```）等价于引用整个集合，不会产生额外编号，反向链接也能正确对应；脚注引用同理，整个集合均在脚注中著录。

#callout(kind: "note", title: "著者-出版年制下引用 @set：用 `label` 字段给标签")[
  顺序编码制下，`@set` 共用一个编号。著者-出版年制需要著者和年份；若 set 没有这些信息，本包与 #BibLaTeX 3.8 以后的行为相同，改为显示 set 的键，例如 ```typ @combined``` 显示为 `(combined)`。

  要获得明确的标注，可在 `@set` 上添加 `label` 字段，作为整个条目集的标注标签（对应 #BibLaTeX 的静态条目集）：

  ```bib
  @set{combined, entryset={zh1, en1}, label={张三, 等, 2020}}
  ```
  此时正文显示 `(张三, 等, 2020)`。也可以直接使用便于阅读的 set 键，但键中不要含空格或英文逗号。
]

== 责任者截断：按角色、按语言分设阈值 <et-al-section>

著者-出版年制的正文标注默认只显示姓，如 `(Zhang, 2020)`；著者人数达到阈值时截断。`*-et-al-min` 与 CSL 的 `et-al-min` 含义相同。截断词默认随条目语言：中文用“等”，西文用“et al.”，如 `(王一等, 2021)`、`(Wang et al., 2021)`。相关参数为 #arg-ref("gb7714", "cite-name-style")[`cite-name-style`]、#arg-ref("gb7714", "cite-terms-lang")[`cite-terms-lang`]、`cite-et-al-min` 和 `cite-et-al-use-first`。

责任者截断由两组参数控制：参考文献表使用 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`] 和 #arg-ref("gb7714", "bib-et-al-use-first")[`bib-et-al-use-first`]，正文标注使用对应的 `cite-*` 参数。它们与 CSL 的同名属性含义相同。

GB/T 7714 §7.1.2 规定，责任者不超过 3 位时全部著录，超过 3 位时著录前 3 位并加「等」。这对应参考文献表默认的 `(4, 3)`；正文标注默认用 `(2, 1)`，通常更早截断。四个参数均支持*三种写法*：用整数统一设置；按条目语言设置（`zh` / `en` / … / `rest`）；按责任者位置设置（`principal` / `host` / `editor` / `rest`），其中位置值还可按语言细分。因此可同时表达责任者位置和语言两个维度：

```typc
bib-et-al-min: (
  principal: 4,                      // 责任者：4 位及以上截断
  editor: (en: 5, ja: 3, rest: 4),   // 编者：西文 5 位起截、日文 3 位、其余 4 位
  rest: 4,                           // 其余位置的默认处理
)
```

角色键 `principal`、`host`、`editor`、`translator` 表示责任者在著录中的位置，不是 `.bib` 字段名。角色设置和语言设置不能位于同一层；需要同时设置时，将语言字典写在角色值中。结构说明见 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`]。

#demo("按语言分设截断阈值")[```typ
#show: gb7714(bib-et-al-min: (zh: 4, rest: 3), full: true)
#bibliography(bytes("@book{zh4, author={张三 and 李四 and 王五 and 刘七}, title={甲}, publisher={P}, address={X}, date={2020}}
@book{en4, author={Smith, Ann and Jones, Ben and Brown, Cid and Diaz, Eva}, title={Delta}, publisher={P}, address={X}, date={2020}, langid={english}}"))
```]

第三个参数 #arg-ref("gb7714", "bib-et-al-use-last")[`bib-et-al-use-last`]（正文侧为 #arg-ref("gb7714", "cite-et-al-use-last")[`cite-et-al-use-last`]）可保留前 N 位和末 M 位责任者，中间用省略号表示。GB/T 7714 没有这项规定；它用于兼容采用这种写法的期刊。取值见参数链接。

== 字段内标点的转换 <correct-punct-section>

`correct-punct: true` 转换长文本字段中的逗号、冒号、分号、圆括号、问号和感叹号。目标由 `bib-punct-style` 和条目语言决定，支持半角与全角互转；句点、斜杠及数字之间的时间冒号不按普通标点改写。

单独设置 `custom-punct` 不改字段内容。启用 `correct-punct` 后，其适用标点的 `text` 值也用于字段转换；字体、字重等样式仍仅用于生成的结构标点。参见 #arg-ref("gb7714", "custom-punct")[`custom-punct`]。

#demo("标点矫正")[```typ
#show: gb7714(correct-punct: true, bib-punct-style: "by-entry-with-space")
#bibliography(bytes("@book{zh, author={张三}, title={我说;再说;还说}, publisher={社}, address={北京}, date={2020}, langid={chinese}}
@book{en, author={Lee, Sam}, title={Hi; Bye; So Long}, publisher={P}, address={NY}, date={2021}, langid={english}}"), full: true)
```]

花括号中的文本不转换标点，输出时省略花括号。例如 ```bib title={外面;{内部;不矫正}外面;}``` 只转换花括号以外的分号。

#callout(kind: "warning", title: "只能在 gb7714() 初始化时设")[
  `correct-punct` 和 `titles-text-case` 在读取文献数据时生效，不能通过单次 `cite` 或 `bibliography` 调用覆盖。需要局部设置时，使用 @local-config-section 的内容块写法。
]

== 长标题字段的字母大小写 <text-case-section>

西文文献的题名大小写风格各刊不一：`.bib` 里可能是作者原样、全大写、或 Title Case。#arg-ref("gb7714", "titles-text-case")[`titles-text-case`] 在解析期对*长标题类字段*统一转换（Rust 侧逐字段应用，`{}` 保护括号内不动）：

#table(
  columns: (auto, 1fr, auto),
  table.header(repeat: true, [取值], [输出（源 `the quick {BROWN} fox jumps over the lazy dog`）], [语义]),
  [`none`（默认）], [the quick BROWN fox jumps over the lazy dog], [不转换，按 `.bib` 原样],
  [`"sentence"`], [The quick BROWN fox jumps over the lazy dog], [按句首大写规则转换，保留受保护内容],
  [`"title"`], [The Quick BROWN Fox Jumps over the Lazy Dog], [按内置词表处理标题大小写],
)

标量作用于全部白名单字段；字典按字段分设、`rest` 默认处理：

```typ
titles-text-case: "sentence"                                  // 全体句首大写
titles-text-case: (title: "sentence", journaltitle: "title", rest: none)  // 分字段
```

#demo("句首大写：转换全大写题名")[```typ
#show: gb7714(titles-text-case: "sentence", full: true)
#bibliography(bytes("@article{shout, author={Smith, Ann}, title={DEEP LEARNING FOR {DNA} ANALYSIS}, journal={Nature}, date={2020}, volume={1}, pages={1-9}, langid={english}}"))
```]

按字段设置时使用字典。可用的标题字段、`rest` 的含义以及 CJK 文本和花括号保护规则见 #arg-ref("gb7714", "titles-text-case")[`titles-text-case`]；字段中的 #LaTeX 命令见@latex-section。

词内已有大写或数字的词（如 `mRNA`、`pH`、`DNA`、`3D`）通常保留；整个题名全为大写时，先统一处理未受保护部分，再转换。内置词表不能代替各语种、期刊的专用大小写规范，重要专名宜用花括号明确保护。

#callout(kind: "note", title: "保留专名的大小写")[
  *首字母之后仍含大写字母，或含数字*的词会保留原样：`mRNA`、`pH`、`DNA`、`iPhone`、`FLUENT`、`3D`、`COVID-19` 无须添加花括号。这与 CSL 对 mixed / uppercase 词的处理相同；但全大写题名仍会整体转换，例如 `RESEARCH ON ...` 变为 `Research on ...`。该判断只依据字形：纯小写词（`von`、`rna`）和仅首字母大写的专名（`Neumann`、`China`）仍须用 `{}` 保护。命令参数不构成保护范围，`\textbf{Bold}` 中的 `Bold` 仍参与大小写转换。
]

#demo("保留 mRNA、pH、3D 的大小写")[```typ
#show: gb7714(titles-text-case: "sentence", full: true)
#bibliography(bytes("@article{ttc-prot, author={Smith, Ann}, title={Study of mRNA and DNA in pH 7 buffer using FLUENT 3D models}, journal={Journal of CFD}, year={2021}, volume={2}, pages={1-8}, langid={english}}"))
```]

== 姓名格式选项 <name-style-section>

#arg-ref("gb7714", "bib-name-style")[`bib-name-style`] 控制参考文献表，#arg-ref("gb7714", "cite-name-style")[`cite-name-style`] 控制正文标注。两者接受 `auto` 或同一种字典；字典中的键均可省略。

#table(columns: (auto, 1fr),
  table.header(repeat: true, [键], [作用与取值]),
  [`order`], [姓名顺序：`"family-ahead"` 姓在前，`"given-ahead"` 名在前；字典 `(first:, rest:)` 可分别设置第一责任者和其余责任者，两个键均须提供],
  [`family-case`], [姓氏大小写：`none` 保留原样，`"uppercase"` 大写，`"lowercase"` 小写],
  [`given-form`], [名字形式：`none` 省略，`"initials"` 缩写，`"pinyin-initials"` 按拼音音节缩写，`"full"` 完整拼写；也可用 `(pinyin:, rest:)` 分别设置],
  [`given-case`], [完整名字的大小写：`none` 保留原样，`"uppercase"` 大写，`"lowercase"` 小写，`"capitalize-first"` 首部分首字母大写，`"capitalize-each"` 各部分首字母大写；缩写字母始终大写],
  [`given-initial-separator`], [每个缩写字母后的字符串，如 `"."`],
  [`given-separator`], [名字各部分之间的字符串，如 `"-"` 或 `""`；`none` 保留来源中的连接符],
  [`family-given-separator`], [姓在前时，姓与名之间的字符串],
  [`given-family-separator`], [名在前时，名与姓之间的字符串],
)

`auto` 使用标准版本和标注位置对应的默认值；拼音姓名的版本差异见本节后文。

`family-case` 目前不接受 `"capitalize-first"`、`"capitalize-each"` 或 `"title"`。这些值不能从 `given-case` 直接套用到姓氏。2025 版默认保留姓氏原样，因此数据中的 `DUBAR` 不会自动变成 `Dubar`；应在文献数据中按所需拼写填写，尤其不要统一改写含前缀、连字符或词内大写的姓氏。

`*-separator` 接受三种写法：单个标点按当前标点样式转换全角或半角；普通字符串原样输出；`"{…}"` 保留定界符内的内容，适合精确控制空格。该规则适用于姓名、日期、页码、引用区间和脚注补充信息等分隔符。相关参数见 @gb7714-fn 中的 `*-separator` 项。

`*-separator` 可以按条目语言分别设置。例如 ```typc page-range-separator: (zh: "～")``` 使中文条目使用全角波浪线，其他语言仍使用默认的 `"-"`。字典的键为语言代码，如 `zh`、`en`、`ja`、`ko`、`ru`、`fr`；无效的语言代码（如 `cn`）会导致编译错误。

要同时设置其他语言，使用 `rest`：```typc (zh: "～", rest: "–")```。未单独列出的语言使用 en dash，不再沿用预设的 `"-"`。

多语言字典先按语言选择一个值，再按上述三种规则处理。例如 ```typc bib-name-date-separator: (zh: ",", rest: "{ / }")``` 中，`zh` 的逗号会在中文条目中转换为全角「，」，`rest` 的 verbatim 值则原样输出为 " / "。

常用组合速查：

```typ
bib-name-style: (given-form: "full")            // Zhao Yu Xin（全名照原样，最常要的「别缩写」）
bib-name-style: (family-case: "uppercase",      // ZHAO Yu-xin（拼音）
  given-form: "full", given-separator: "-", given-case: "capitalize-first")
bib-name-style: (given-form: "full",            // Zhao Yuxin（完整拼写）
  given-separator: "", given-case: "capitalize-first")
bib-name-style: (order: "given-ahead",          // YuXin Zhao（西文自然序驼峰）
  given-form: "full", given-separator: "", given-case: "capitalize-each")
bib-name-style: (family-case: none,             // Crane, D. R.（带点倒装，西文期刊惯例）
  given-initial-separator: ".", family-given-separator: ", ")
cite-name-style: (given-form: "initials")       // 行内 (Smith J, 2020)
```

缩写后的句点与结构句点相邻时自动去重：设置 `(given-initial-separator: ".")` 后，顺序编码制显示 `MILLER K. Gamma[M].`，不会出现 `K..`。

=== 拼音名字的缩写：`pinyin-initials`

`given-form` 除 `"initials"`（名字缩写为一个首字母）和 `"full"`（完整拼写）外，还可设为 `"pinyin-initials"`。此时各拼音音节分别缩写，如 `Yanshuo` 显示为 `Y S`，`Erting` 显示为 `E T`；无法识别为两个拼音音节的名字（如 `Martin` 或单音节 `Xiu`）仅保留一个首字母。包含连字符或空格的 `Yan-Shuo` 和 `Yan Shuo` 已有分隔，不再拆分。音节首字母之间固定使用空格，不受 `given-separator` 影响。该行为与李泽平 gbt7714 宏包 `initializepinyin` 选项的默认值一致。

参考文献表中的 `given-form: auto` 根据 `version` 确定：2025 版为 `(pinyin: "full", rest: "initials")`，即拼音名字采用完整拼写 `Chu Yanshuo`（§7.1.1）；2015 和 2005 版为 `(pinyin: "pinyin-initials", rest: "initials")`，显示为 `CHU Y S`。正文标注进行姓名消歧时，各版本的中间形式均为 `Chu Y S`。

#demo("2015 版的姓名缩写")[```typ
#show: gb7714(full: true, version: 2015)
#bibliography(bytes("@book{py-chu, author={Chu, Yanshuo and Pan, Erting and Smith, Anna}, title={Alpha}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{py-li, author={Li, Changan and Chu, Yan-Shuo and Ouyang, Xiu}, title={Beta}, publisher={P}, address={X}, date={2021}, langid={english}}"))
```]

直接设置 `given-form: "pinyin-initials"` 会尝试拆分所有名字，包括 `Anna`。使用 `(pinyin:, rest:)` 字典时，先判断是否为拼音名字，再分别应用两种设置。

自动判断时，如果名字的每一部分都是合法拼音音节，就按拼音名处理。`Anna Wang`、`Lisa Chen` 等西文名字也可能满足这一条件，因此本包用内置排除表将常见情况按西文名处理。若仍有误判，可全局设置 `bib-name-style: (given-form: "initials")` 关闭自动判断，或在条目中用 `nameformat` 单独指定。


#demo("拼音名字采用完整拼写：ZHAO Yu-xin")[```typ
#show: gb7714(full: true, bib-name-style: (
  family-case: "uppercase", given-form: "full",
  given-separator: "-", given-case: "capitalize-first"))
#bibliography(bytes("@book{ns-zhao, author={Zhao, Yu Xin}, title={Alpha}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{ns-crane, author={Crane, Diana R.}, title={Beta}, publisher={P}, address={X}, date={2020}, langid={english}}"))
```]

西文姓名前缀（如 `van der`、`von`）的位置由 #arg-ref("gb7714", "prefix-last")[`prefix-last`] 控制，与 `name-style` 相互独立。默认将完整前缀置于姓前（`van der Veen P H`）；设为 `true` 时置于名后（`Veen P H van der`，ISO 690 形式）。真正的姓名前缀不缩写；`Veen P H v d` 是将前缀误填入名字字段后随名字一同缩写的结果。排序时是否计入前缀见 #arg-ref("gb7714", "sort-use-prefix")[`sort-use-prefix`]。

机构名应使用双花括号，如 ```bib author = {{中国科学院}}```，这样会按原文著录。对于 ```bib author = {Trisco ICAP Pty Ltd}``` 这类单层花括号写法，本包会检查末词是否为 Ltd、Inc、Co、GmbH、Pty 等企业标识，并据此识别机构。带逗号的“姓, 名”始终按人名处理，因此 `Co, Carl` 会显示为 `Co C`。

需要为个别条目指定姓名格式时，在 `.bib` 中填写 `nameformat`，其优先级高于全局设置。取值沿用 #BibLaTeX 国标样式的命名：

#table(columns: (auto, 1fr),
  table.header(repeat: true, [取值], [姓名格式]),
  [`uppercase`、`familyahead`], [姓在前且大写，名字缩写],
  [`lowercase`], [保留姓氏原有大小写，名字缩写；并非将姓名全部改为小写],
  [`givenahead`], [名字缩写在前，姓氏大写],
  [`fullname`], [名字在前，完整拼写],
  [`pinyin`], [姓氏大写，名字完整拼写，各部分以短横线连接],
  [`quanpin`], [保留姓氏大小写，名字完整拼写，各部分连写],
)

例如 `nameformat = {pinyin}` 可为该条目指定拼音姓名格式。各项的详细调整仍使用 @name-style-section 的姓名格式字典。

== 按条目控制标识、路径和永久标识符 <display-control>

#arg-ref("gb7714", "show-mark")[`show-mark`] 默认为 `true`。设为 `auto` 时，仅含一个著录项目的条目可以省略文献类型标识代码。`show-mark`、#arg-ref("gb7714", "show-url")[`show-url`] 和 #arg-ref("gb7714", "show-pid")[`show-pid`] 也可按条目类型或标识代码设置；`rest` 用于其他条目。`show-url` 和 `show-pid` 的 `"online-only"` 仅对网络资源生效。允许的键和判断顺序见这三个参数的链接。

`show-url` 只控制 URL，不抑制 DOI 等标识符或引用日期。例如 `show-url: "online-only", show-pid: (doi: true)` 会隐藏普通期刊条目的 URL，但保留已有 DOI。引用日期仍按 `show-urldate` 和对应版本的规则处理，不补造缺失日期。

引用日期按实际著录形式取用。2005、2015版保留已有日期；2025版的网站／网页、独立数据集和预印本格式列有引用日期，图书、期刊等格式不列。数据集以图书或期刊形式出现时，按相应出版形式处理（§8.14.1），不只看DS代码。网络软件或数据库入口可采用网页式，光盘软件不因此被当成下载网页；非联机的独立数据集仍可保留已有引用日期。

载体按条目数据判定，不随路径显隐改变。普通图书、期刊仅有 URL 或 DOI 时，不自动添加 `/OL`；若所著录的是联机版本，应在数据中写明 `medium = {OL}` 或相应的显式载体段。`@online` 等网络文献类型默认按联机处理，软件、数据集等还结合访问数据判断。`show-medium: false` 只隐藏载体码，不改变联机属性或 `"online-only"` 的筛选结果。

#demo("show-url: online-only（只有联机条目著录 URL）")[```typ
#show: gb7714(show-url: "online-only", full: true)
#bibliography(bytes("@online{web, author={Smith, Ann}, title={Alpha}, url={https://example.org/a}, urldate={2024-01-02}, date={2023}, langid={english}}
@book{print, author={Jones, Ben}, title={Beta}, publisher={P}, address={X}, date={2020}, url={https://example.org/b}, langid={english}}"))
```]

`show-pid` 只控制是否显示，不影响次序：```typc (issn: true, isbn: true)``` 与 ```typc (isbn: true, issn: true)``` 的输出相同。次序由 #arg-ref("gb7714", "pid-priority")[`pid-priority`] 控制；若只需启用默认不显示的标识符，可设置 `rest: true`。`max` 是总额上限，显式 `doi: true` 也不会突破它；`max: 0` 隐藏全部 PID。自动去重只检查实际输出的 URL，被隐藏的 URL 不会抑制 PID。

#arg-ref("gb7714", "custom-drivers")[`custom-drivers`] 除小写 entry_type 外，也接受大写文献类型标识代码，例如 `D: "模板"` 可匹配全部学位论文。内部类别词（`monograph`、`component-part` 等）不能用作键。

=== 缺失信息与出版年推定 <missing-data-section>

应优先补全原文能够查明的责任者、出版地、出版者和出版日期。缺失信息的显示由下列参数控制：

- `show-anon` 控制责任者缺失时的占位词；默认在著者-出版年制下显示“佚名”，顺序编码制省略责任者。
- `show-no-date` 控制著者-出版年制中的“无日期”等占位词；`show-sine-anno` 控制著录格式中的出版年不详项。
- `show-sine-loco`、`show-sine-nomine` 分别控制出版地和出版者不详时的占位内容。

本包默认不推定出版年。确需以引用日期的年份作为估计值时，可设置 `date-fallback: "urldate"`；仅在 `date`、`year` 均缺失时使用，并加方括号表示推定值。推定年份也参与排序和消歧。2025 版网页式、独立数据集式和预印本式没有出版年位置，不据此另造出版年；以图书形式出版的数据集仍按图书处理。具体取值见 #arg-ref("gb7714", "date-fallback")[`date-fallback`]。

=== 缺年占位与估计年份

`show-no-date` 用于著者-出版年制的标签位置，默认显示“无日期”／`n.d.`；`show-sine-anno` 用于出版项的年位置，默认关闭，开启后可显示“出版年不详”／`s.a.`。两者的词语由 `custom-terms.no-date` 和 `custom-terms.sine-anno` 分别设置。

GB/T 7714—2025 §7.5.4.3允许依次采用版权年、印刷年或估计的出版年，并要求估计年加方括号。它没有规定 `n.d.`、`s.a.` 等缺年占位词，也没有要求以引用年份估计出版年。占位词和 `date-fallback` 都是本包提供的可选处理，应与有来源依据的年份区分。

#demo("同一缺年图书的两种位置：出版项占位")[```typ
#show: gb7714(show-sine-anno: true)
#bibliography(bytes("@book{missing-year, author={张三}, title={缺年图书}, location={北京}, publisher={某社}}"), full: true)
```]

#demo("同一缺年图书的两种位置：著者-出版年标签")[```typ
#show: gb7714(style: "author-date")
参见@missing-year。
#bibliography(bytes("@book{missing-year, author={张三}, title={缺年图书}, location={北京}, publisher={某社}}"))
```]

== 起讫页码的位数：`page-range-style` <page-range-style-section>

`.bib` 中的页码范围既可完整写作 `321-328`，也可按期刊惯例缩写为 `321-28`。#arg-ref("gb7714", "page-range-style")[`page-range-style`] 将两者统一为指定格式；#arg-ref("gb7714", "page-range-separator")[`page-range-separator`] 单独控制连接符。连接符还可按条目语言设置，例如 ```typc page-range-separator: (zh: "～", rest: "-")``` 使中文条目使用全角波浪线，其他语言使用半角短横。多语言字典适用于全部 `-separator` 参数，参见 @name-style-section 末尾。

*默认 `none`，页码保持原样。* GB/T 7714—2025 §7.7 只规定页码使用阿拉伯数字，没有要求缩写或展开页码范围。因此，本包默认不改写 `pages` 数据；选择其他取值即表示允许按相应规则转换页码范围。

#table(
  columns: (auto, auto, auto, auto, auto, auto),
  table.header(repeat: true, [`.bib` 里写的], [`none`（默认）], [`"expanded"`], [`"minimal"`], [`"minimal-two"`], [`"chicago-16"`]),
  [`321-328`], [321-328], [321-328], [321-8], [321-28], [321-28],
  [`321-28`（已折叠）], [321-28], [321-328], [321-8], [321-28], [321-28],
  [`101-107`], [101-107], [101-107], [101-7], [101-07], [101-7],
  [`100-104`], [100-104], [100-104], [100-4], [100-04], [100-104],
  [`1496-1500`], [1496-1500], [1496-1500], [1496-500], [1496-500], [1496-500],
)

`"chicago-15"`、`"chicago-16"` 的区别及罗马数字页码的处理见 #arg-ref("gb7714", "page-range-style")[`page-range-style`]。这些设置只影响 `pages` 字段。

== 排版微调速览

下列参数用于调整参考文献表的版式。参数名直接链接到相应定义：

#table(columns: (auto, 1fr),
  table.header(repeat: true, [参数], [作用]),
  [#arg-ref("gb7714", "entry-spacing")[`entry-spacing`]], [条目之间的垂直间距],
  [#arg-ref("gb7714", "entry-hanging-indent")[`entry-hanging-indent`]], [条目第二行及后续各行的缩进量；`auto` 在无编号的著者-出版年制中为 1.5em，其余情况为 0pt],
  [#arg-ref("gb7714", "entry-first-line-indent")[`entry-first-line-indent`]], [条目首行缩进量；正值表示首行缩进、其余行顶格，与悬挂缩进互斥],
  [#arg-ref("gb7714", "hyphenate")[`hyphenate`]], [参考文献表内西文是否允许断字],
  [#arg-ref("gb7714", "number-align")[`number-align`] / #arg-ref("gb7714", "number-width")[`number-width`]], [编号列的对齐 / 宽度],
  [#arg-ref("gb7714", "number-gutter")[`number-gutter`]], [编号与条目正文之间的间距],
  [#arg-ref("gb7714", "emphasis")[`emphasis`]], [按位置施加斜体 / 加粗 / 书名号（题名 / 刊名 / 卷 / 责任者等）],
  [#arg-ref("gb7714", "period-after-creator")[`period-after-creator`]], [责任者之后是否加点],
  [#arg-ref("gb7714", "url-break-every")[`url-break-every`]], [URL 的断行密度],
  [#arg-ref("gb7714", "url-break-hyphen")[`url-break-hyphen`]], [URL 断点处是否显示连字符（默认否）],
  [#arg-ref("gb7714", "url-break-hyphen-at-delimiters")[`url-break-hyphen-at-delimiters`]], [显示连字符时，是否包括 URL 分隔符（`/ . : ? &`）处的断点],
  [#arg-ref("gb7714", "name-suffix-separator")[`name-suffix-separator`]], [姓名与世系后缀（Jr. 等）之间的分隔符],
  [#arg-ref("gb7714", "et-al-translator-separator")[`et-al-translator-separator`]], [译者截断词与角色词之间的分隔符],
  [#arg-ref("gb7714", "page-range-separator")[`page-range-separator`]], [起讫页码之间的连接符（默认 `-`）],
  [#arg-ref("gb7714", "page-range-style")[`page-range-style`]], [起讫页码的位数形式（默认 `none`，规则见 @page-range-style-section）],
  [#arg-ref("gb7714", "cite-range-separator")[`cite-range-separator`]], [引文区间 `[1-5]` 的连接符（默认 `-`，与页码独立）],
  [#arg-ref("gb7714", "cite-numbering-style")[`cite-numbering-style`]], [正文引用编号的括号样式；不改变文献表编号],
  [#arg-ref("gb7714", "cite-name-date-separator")[`cite-name-date-separator`]], [著者-出版年制标注中姓名与年份的分隔符],
  [#arg-ref("gb7714", "volume-title-gutter")[`volume-title-gutter`]], [多卷书中卷号与分卷题名的间距],
  [#arg-ref("gb7714", "mark-medium-bracket-style")[`mark-medium-bracket-style`]], [文献类型与载体标识的括号：`"half"` 半角或 `"full"` 全角],
  [#arg-ref("gb7714", "space-before-pages")[`space-before-pages`]], [页码前是否添加空格],
  [#arg-ref("gb7714", "show-series")[`show-series`]], [是否著录丛书项；默认关闭],
)

=== 链接与编辑器补全 <links-completion-section>

`hyperlink` 默认将 URL、DOI 等显示为可点击的链接；设置 `hyperlink-title: true` 可使题名链接到条目的网址或 DOI。`back-ref: true` 则使文献表编号返回正文首次引用处，需要该条目显示编号。三者控制的位置不同，可以分别设置。

`cite-completion` 默认启用，用于编辑器中的 `@key` 补全，不产生可见的文献表。参数补全的调用写法见 @completion-section。

== 输入校验与报错 <errors-section>

配置错误会中止编译，并在消息中指出参数名、错误值及允许的取值。例如：

```
gb7714: bib-numbering-style 收到非法值 "bracet"; 合法值: "bracket" / "paren" / "dot" /
"plain" / "fullwidth-bracket" / "fullwidth-paren" / "shell" / "circled" / none
```

- *结构字典键校验*：`custom-marks`、`custom-terms`、`custom-fields`、`custom-pids` 和 `custom-drivers` 会检查同名冲突、缺少必填键和值类型错误；文献类型标识代码按照附录 A 及 `custom-marks` 中的自定义代码检查；`titles-text-case` 仅接受规定的字段名。
- *设置冲突*：样式全名指定的版本与 `version` 不一致、原生 CSL 列表与本包脚注模式混用等情况会报错，并给出修改建议。
- `version` 为兼容旧版本，在取值无效时使用 2025，不报错。全局 `style` 接受 `"numeric"`、`"author-date"` 和国标 CSL 全名；其他 CSL 样式应写在 `bibliography(style: ..)` 中。

`warn-missing-title: true` 可启用缺失题名诊断；它不能代替对原始文献数据的检查。语法正确的数据仍可能缺少著录所需信息，字段填写见 @各类文献-2025-section。

== 设置文献表样式：沿用 `std.bibliography` 的操作 <bib-style-section>

本包的 `#bibliography` 每次会生成一个 `std.bibliography` 元素。因此，在 Typst 0.15 及以后版本中，可以继续使用针对原生文献表的 show 规则：

#table(columns: (auto, 1fr),
  table.header(repeat: true, [原生写法], [作用]),
  [```typ #show std.bibliography: set block(..)```], [整表加边框 / 底色 / 内边距 / 圆角（只套一个框，不逐条目套）],
  [```typ #show std.bibliography: set text(..)```], [整表文字颜色 / 字号 / 字体],
  [```typ #show std.bibliography: set par(..)```], [整表行距 / 段距 / 对齐],
  [```typ #show std.bibliography: it => ..```], [整体包裹 / 变换（只命中一次，无多余空框漏出）],
  [```typ #query(std.bibliography)```], [每张表恰查到*一个*元素],
)

例如为整张文献表添加浅灰底框：

```typ
#show std.bibliography: set block(fill: luma(245), stroke: 0.5pt + gray, inset: 8pt)
#bibliography(read("refs.bib"))
```

顺序编码制文献表使用两列 `grid`：`x:0` 是编号，`x:1` 是著录内容。```typ #show grid.cell.where(x: 1): it => ..``` 可只处理条目正文，不影响编号列。该结构在 Typst 0.14 中也可用。

Typst 0.14 不支持上述 `show std.bibliography` 写法。该版本可将排版设置与文献表放在同一内容块中；此方法也适用于后续版本：

```typ
#[
  #set block(fill: luma(245), stroke: 0.5pt + gray, inset: 8pt)
  #bibliography(read("refs.bib"))
]
```

#demo("整表加浅灰底框（作用域写法，全版本通用）")[```typ
#show: gb7714
@Morris2010@Rogers2011
#[
  #set block(fill: luma(245), stroke: 0.5pt + gray, inset: 8pt)
  #bibliography(refs, keys: [@Morris2010@Rogers2011])
]
```]

#pagebreak()
// API 参数名悬挂在正文左侧，因此仅本章加宽左页边距。
#set page(margin: (left: 4cm, right: 1.5cm, top: 2.2cm, bottom: 2.4cm))
= API 参考 <api-section>

`gb7714` 设置全局格式；`bibliography` 读取文献数据并生成文献表；`cite` 设置单次引用；`set-bib-label` 切换后续引用所属的命名列表。

下列默认值以公开接口为准。列表级或单次引用参数为 `auto` 时，通常继承相应的全局设置；不同名称的对应关系以各参数说明为准。常用任务和完整示例见 @quick-start-section 至 @bib-style-section；本章用于查阅参数。

// 公共 API：gb7714、bibliography、cite、set-bib-label。
// 文档注释和参数定义集中在 src/api.typ；lib.typ 仅提供公开入口。
// 注：参考文献表函数的文档块挂在引擎的 `print-bib` 上（标题即“bibliography”），故下方抽取名仍含 print-bib。
// API 文档生成器须从真正含 doc-comment / 参数定义的源文件抽取。
#let gb-source = read("../../src/api.typ")

// HTML 模式在 API 章节顶部提供参数排序控件；默认采用源码顺序，也可按字母顺序排列。
// PDF 不提供此控件；site.js 通过 id 处理该元素。
#if is-html-target [
  #html.elem("div", attrs: ("id": "api-sort-toggle"))[]
]

#api-from-source(gb-source, (
  "gb7714",
  "set-bib-label",
  "cite",
  "print-bib",
), heading-level: 2, doc-scope: (LaTeX: LaTeX, BibLaTeX: BibLaTeX, BibTeX: BibTeX))

#if not is-html-target [#pagebreak()]
// 后续章节恢复正文页边距。
#set page(margin: (left: 2.5cm, right: 2.5cm, top: 2.2cm, bottom: 2.4cm))

= GB/T 7714—2025 标引规则 <standard-section>

本章概述 GB/T 7714—2025 第 9 章的标引规则，并说明各文献类型在本包中的数据写法。标准原文未规定的扩展功能不在本章重复说明。

== 顺序编码制

=== 参考文献表编制要求

参考文献表按正文中的文献序号依次列出（§9.2.2）。

=== 正文中的引用

文献按其在正文中首次出现的顺序连续编码，序号置于方括号内（§9.2.1.1）。同一处引用多篇文献时，序号之间用逗号分隔；连续序号的起讫序号之间用短横线连接（§9.2.1.2）。

同一文献被多次引用时，仍使用首次引用的文献序号；引文页码著录在方括号外（§9.2.1.3）。本包通过引用的 `supplement` 提供页码，写法见@cite-supp-section。

采用脚注时，注号可以使用带圈数字；重复引用应再次著录，著录项目可以简化为文献序号和引文页码（§9.2.1.1、§9.2.1.3）。本包的脚注与尾注设置见@note-section。

== 著者-出版年制

=== 参考文献表编制要求

参考文献先按文种集中，再按责任者字顺和出版年排列。中文文献可按汉语拼音或笔画排列（§9.3.2）。设置 ```typc style: "author-date"``` 即可采用本体系；排序设置见@sort-section。

=== 正文中的引用

标注内容由责任者姓氏和出版年组成，并置于圆括号内；无法仅凭姓氏识别时，可标注责任者姓名。正文已经提及责任者时，括号内仅著录出版年（§9.3.1.1）。本包分别使用 ```typc form: "year"``` 和 ```typc form: "prose"``` 生成这两种形式。

多责任者文献仅标注第一责任者；中文责任者后加“等”，欧美责任者后加“et al.”（§9.3.1.2）。同一责任者同年出版的多篇文献以 a、b、c 等小写字母区分（§9.3.1.3）。引文页码置于圆括号外并以上标形式著录（§9.3.1.4）。

// 四项依次说明标准规则、包内实现、输入数据和最终结果。
#let _entry-stage(index, title, accent, bg, stripe, body) = block(
  width: 100%,
  stroke: (bottom: 0.45pt + accent.lighten(42%)),
  inset: 0pt,
  above: 0pt,
  below: 0pt,
)[
  #block(width: 100%, fill: bg, inset: (x: 0.8em, y: 0.32em), below: 0pt)[
    #set par(first-line-indent: 0em)
    #grid(
      columns: (1.25em, 1fr),
      column-gutter: 0.35em,
      align: (center + horizon, left + horizon),
      circle(radius: 0.55em, fill: accent)[#text(size: 7.5pt, weight: "bold", fill: white, str(index))],
      text(size: 11.25pt, weight: "bold", fill: accent, title),
    )
  ]
  #block(width: 100%, fill: zebra-fill(stripe, bg), inset: (x: 0.8em, y: 0pt), zebra-rows(body))
]

// 代码与数据折行后的悬挂缩进量：9 pt 等宽字体下约四个字符宽。
#let snippet-hanging-indent = 2.4em

// 所在的斑马纹环境已设好行格，这里不再改行距，上下也不留内边距。
// 数据一个字段一行，逐行发段落：栏宽放不下时折行，续行悬挂缩进到字段名之后，
// 与下一个字段的行首区分开。悬挂缩进必须用 par 函数，set par 在嵌套 block 内不生效。
#let _snippet-pane(title, source) = block(
  width: 100%,
  inset: (x: 0.45em, y: 0pt),
)[
  #text(weight: "bold", fill: theme.data-accent, title)
  #linebreak()
  #block(width: 100%)[
    #for line in source.text.split("\n") {
      par(
        justify: false,
        hanging-indent: snippet-hanging-indent,
        text(font: ("Latin Modern Mono", "FZFangSong-Z02S"), line),
      )
    }
  ]
]

// 按 GB/T 7714—2025 第 8 章渲染四项对照。
#let render-entry-types-2025(specs) = {
  for spec in specs [
    #let built-in-template = built-in-templates-2025.at(spec.entrytype, default: none)
    #let data-example = entry-data-examples-2025.at(spec.chinese, default: none)
    === #spec.chinese / #spec.entrytype
    #label("2025-" + spec.chinese)

    #[
      #set par(first-line-indent: 0em)
      Typst 条目类型：#raw(spec.entrytype)；文献类型标识代码：#raw("[" + spec.mark + "]")；标准章条：§#spec.gb-section。
    ]

    #block(
      width: 100%,
      breakable: false,
      stroke: 0.65pt + luma(58%),
      radius: panel-radius,
      clip: true,
      above: 0.65em,
      below: 0.65em,
    )[
      #if spec.at("format-string", default: none) != none [
        #_entry-stage(1, [著录格式], theme.format-accent, theme.format-bg, theme.format-stripe)[
          #text(font: ("Noto Serif CJK SC"))[#spec.format-string]
        ]
      ]

      #if built-in-template != none [
        #_entry-stage(2, [对应内置模板], theme.fields-accent, theme.fields-bg, theme.fields-stripe)[
          // 模板是代码：关掉两端对齐，否则段间那个空格会被拉成大空隙；折行后悬挂缩进。
          // `_raw-flag` 让全角冒号、逗号按源码原样显示，不走正文的半角替换。
          #par(
            justify: false,
            hanging-indent: snippet-hanging-indent,
            _raw-flag(text(font: ("Latin Modern Mono", "FZFangSong-Z02S"), built-in-template)),
          )
        ]
      ]

      #if data-example != none [
        #_entry-stage(3, [数据写法], theme.data-accent, theme.data-bg, theme.data-stripe)[
          #grid(
            columns: (1fr, 1fr),
            column-gutter: 0.55em,
            align: top,
            stroke: (x, y) => if x == 1 { (left: 0.45pt + theme.data-accent.lighten(45%)) } else { none },
            _snippet-pane([BibLaTeX（`.bib`）], data-example.bib),
            _snippet-pane([CSL JSON], data-example.csl),
          )
        ]
      ]

      #if spec.at("examples", default: ()).len() > 0 [
        #_entry-stage(4, [标准示例（摘录）], theme.standard-accent, theme.standard-bg, theme.standard-stripe)[
          #spec.examples.first()
        ]
      ]
    ]

    #if spec.at("extra", default: none) != none {
      spec.extra
    }
  ]
}

== 文献类型与字段（GB/T 7714—2025） <各类文献-2025-section>

GB/T 7714—2025 第 8 章分别规定图书、连续出版物、会议录、学位论文、报告、标准、专利、网站与网页、档案、地图、数据集和预印本等类型的著录格式。本节按照第 8.2～8.15 节的顺序，列出相应的 Typst 条目类型、文献类型标识代码、著录格式和数据说明。

每类文献并列给出 `.bib` 与 CSL JSON。日常录入建议使用 `.bib`；CSL JSON 一般由 Zotero、Pandoc 等工具导出，此处仅供核对字段对应关系。

本包默认按照 GB/T 7714—2025 著录。字段含义和 `@key` 引用方式在三个版本中相同；文献类型标识代码、著录项目和格式的版本差异在各类型下说明。仅在需要旧版格式时设置 #arg-ref("gb7714", "version")[`version`]：

```typ
#show: gb7714()                // 默认即 GB/T 7714—2025，无需任何设置
#show: gb7714(version: 2015)   // 仅在需要旧版时显式切换（或 version: 2005）
```

下列参数默认值为 `auto`，随 `version` 自动取值；显式赋值优先。#arg-ref("gb7714", "entry-localized-glyphs")[`entry-localized-glyphs`] 也随版本选择：CJK 条目在 2015、2025 版启用，在 2005 版关闭。

- #arg-ref("gb7714", "bib-punct-style")[`bib-punct-style`]：2025 版默认采用混合宽度，逗号、冒号、分号和圆括号使用全角，句点、斜杠和方括号使用半角；2015 版默认使用带后置空格的半角标点。
- #arg-ref("gb7714", "bib-name-style")[`bib-name-style`] 的 `given-form: auto`：2025 版完整著录拼音名字，其他西文名字缩写为首字母；2005 和 2015 版按拼音音节分别缩写（`CHU Y S`，与李泽平 gbt7714 的 `initializepinyin` 默认值一致）。见 @name-style-section。
- #arg-ref("gb7714", "bib-name-style")[`bib-name-style`] 的 `family-case: auto`：2025 不处理（`Smith`）；2005 / 2015 姓全大写（`SMITH`）。`given-separator: auto` 同为版本自动适配：2025 保留来源连接符（`J-P`）、2005 / 2015 各段空格连（`J P`）。
- #arg-ref("gb7714", "dedup-url-pid")[`dedup-url-pid`]：默认 `auto`——2025 版为 `true`（§7.9.1 是那一版的条款），2015 版为 `false`（URL 与 DOI 并列著录）。判据是「*印出来的*路径里含*这一个*标识符」：`show-url: false` 时路径根本不印，标识符照常著录；条目的 `url` 指向*另一个* DOI（比如配套数据集的）时，本文的 DOI 也照常著录。

永久标识符方面，GB/T 7714—2025 §7.9 统一引入「永久标识符」：当条目同时含有 `url` 与 `doi` / `cstr` 时，获取和访问路径（§7.8）写在前、永久标识符（§7.9）写在后；若路径自身已含该标识符，则不重复著录（§7.9.1）。

§7.9 没有规定标识符的数量和次序。本包默认输出全部不同标识符；只需一个时，设置 ```typc show-pid: (max: 1)```。#arg-ref("gb7714", "pid-priority")[`pid-priority`] 控制顺序，默认值为 ```typc ("cstr", "doi", "eprint", "isbn", "issn")```。该顺序是本包的默认设置，并非国标要求。

GB/T 7714—2015 无「永久标识符」统称，CSTR 默认关闭；GB/T 7714—2005 不著录任何永久标识符（仅著录获取和访问路径）。

#arg-ref("gb7714", "pid-colon-style")[`pid-colon-style`] 单独控制 `DOI:`、`CSTR:` 后的冒号。默认值 `auto` 跟随 #arg-ref("gb7714", "bib-punct-style")[`bib-punct-style`]。若只想把 PID 冒号改为半角，可设置 ```typc pid-colon-style: "half"```；全部取值见该参数链接。

新建文献数据时，直接使用相应的条目类型，如 `@standard`、`@map`、`@archive`、`@dataset` 或 `@preprint`。本包会保留这些扩展类型，并按照标准版本确定文献类型标识代码。

已有 `.bib` 数据中的 `usera`、`entrytypeid`、`entrysubtype` 和 `mark` 字段继续有效，分别兼容胡振震和李泽平样式。显式字段优先于条目类型的默认值；#arg-ref("gb7714", "custom-marks")[`custom-marks`] 可为某类条目设置全局默认值，完整优先级见参数链接。

视听类 `@image`、`@video`、`@artwork` 和 `@audio` 没有专用标识代码。包含 `url`、`doi` 或 `eprint` 的网络资源著录为 `[EB/OL]`；GB/T 7714—2025 §8.11 的网络图片和视频即采用该形式。非网络资源著录为 `[Z]`（其他）。`@map` 可作为完整地图著录为 `[CM]`，题名后可以著录卷次；责任者可取自 `namea` 或 `editora`。`@patent` 优先使用 `holder`（专利申请者或所有者），缺失时使用 `author`（发明人）。

预印本的文献类型标识代码随版本变化：2025 版使用 `[PP]`，2015 版使用 `[A]` 或 `[A/OL]`，2005 版使用 `[Z]`。`@unpublished` 在 2025 版使用 `[A]`，旧版使用 `[Z]`。`@preprint`、包含 arXiv 字段的 `@article` 和设置 `entrysubtype = preprint` 的 `@article` 均可表示预印本。

条目类型提供的默认标识优先级最低。`usera` 可对单个条目明确指定标识，`custom-marks` 可为某类条目设置全局默认。自定义标识会选择相应的内置条目格式；如果没有相应格式，则仍采用原条目类型的格式。

以下几个字段语义跨多种条目类型生效：

- *`pages` 与 `eid`*：期刊文章优先使用 `pages`；没有页码时，使用 `eid` 中的电子文章编号。两者同时存在时只输出 `pages`。依据 GB/T 7714—2025 §7.7。
- *姓氏前缀不参与排序*：西文姓名前的 `van` / `von` / `de` / `della` 等冠词不进入排序键，`Ludwig van Beethoven` 排在 B 区段（按 `Beethoven`），不排在 V。这与 #BibLaTeX 默认的 `useprefix=false` 一致，是西文书目惯例。CJK 姓名无前缀字段，行为不变。
- *永久标识符*：内置 DOI、CSTR、ISBN、ISSN 和 `eprint`；`custom-pids` 可增加其他标识符。显示、顺序和去重分别由 `show-pid`、`pid-priority` 和 `dedup-url-pid` 控制，见 @display-control。
- *用户附加注释*：设置 #arg-ref("gb7714", "show-annotation")[`show-annotation: true`] 后，在条目末尾输出 `annotation` 或 `annote`。#arg-ref("gb7714", "space-before-annotation")[`space-before-annotation`] 控制句点后的空格；`auto` 会按注释首字符选择。参考 #link("https://github.com/hushidong/biblatex-gb7714-2015/issues/154")[hushidong#154]。

// 示例中的 DOI 和 CSTR 使用可点击链接，与本包实际输出一致。
// URL 无需处理——Typst markup 会自动把裸 `https://…` 转成链接。用显式 link 而非 show-regex，
// 文档级 `cjk-spacer` 会在字母和数字之间插入间距，导致 DOI/CSTR 无法整体匹配；
// 显式 link 元素则能安然穿过 cjk-spacer（仅内部文字被加间距、link 包裹保留）。尾随句点写在调用外。
#let eg-doi(v) = link("https://doi.org/" + v, v)
#let eg-cstr(v) = link("https://cstr.cn/" + v, v)

#let entry-type-docs-2025 = (
  // 8.2 图书
  (
    chinese: "图书",
    entrytype: "@book",
    mark: "M",
    gb-section: "8.2",
    required-fields: (
      ("主要责任者",   "有则必备",      "7.1"),
      ("题名",         "必备",          "7.2"),
      ("其他题名信息", "有则必备",      "7.2.3"),
      ("文献类型标识", "必备",          "7.3, A.1"),
      ("文献载体标识", "电子资源必备",  "7.3, A.2"),
      ("其他责任者",   "可选",          "7.1"),
      ("版本",         "有则必备",      "7.4"),
      ("出版地",       "有则必备",      "7.5.2"),
      ("出版者",       "有则必备",      "7.5.3"),
      ("出版年",       "有则必备",      "7.5.4"),
      ("引文页码",     "有则必备",      "7.7"),
      ("获取和访问路径","电子资源必备", "7.8"),
      ("永久标识符",   "电子资源可选",  "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. 其他责任者. 版本. 出版地: 出版者, 出版年: 引文页码. 获取和访问路径. 永久标识符.",
    examples: (
      [张伯伟. 全唐五代诗格汇考\[M\]. 南京: 江苏古籍出版社, 2002: 288.],
      [康熙字典: 巳集上 水部\[M\]. 影印本. 北京: 中华书局, 1962: 50.],
      [Praetzellis A. Death by theory: a tale of mystery and archaeological theory\[M/OL\]. Rev. ed. \[S. l.\]: Rowman & Littlefield Publishing Group, Inc., 2011: 13. http://lib.myilibrary.com/Open.aspx?id=293666.],
    ),
    extra: [
      - 永久标识符（`doi` / `cstr`）置于 URL 之后；若 URL 已含 DOI 则不重复著录。
      - 注：图书表（表 1）本身不含"丛书"项，这与 2015 版一致；本包对 `series` / 丛书号的支持是对胡振震样式的兼容扩展，不属于国标必备元素，2015 / 2025 两版都按相同逻辑输出。
    ]
  ),

  // 8.3 图书中的析出文献
  (
    chinese: "图书中的析出文献",
    entrytype: "@inbook",
    mark: "M",
    gb-section: "8.3",
    required-fields: (
      ("析出文献主要责任者",   "有则必备",     "7.1"),
      ("析出文献题名",         "必备",         "7.2"),
      ("析出文献其他题名信息", "有则必备",     "7.2.3"),
      ("文献类型标识",         "必备",         "7.3, A.1"),
      ("文献载体标识",         "电子资源必备", "7.3, A.2"),
      ("析出文献其他责任者",   "可选",         "7.1"),
      ("图书主要责任者",       "有则必备",     "7.1"),
      ("图书题名",             "必备",         "7.2"),
      ("其他题名信息",         "有则必备",     "7.2.3"),
      ("版本",                 "有则必备",     "7.4"),
      ("出版地",               "有则必备",     "7.5.2"),
      ("出版者",               "有则必备",     "7.5.3"),
      ("出版年",               "有则必备",     "7.5.4"),
      ("析出文献页码",         "有则必备",     "7.7"),
      ("获取和访问路径",       "电子资源必备", "7.8"),
      ("永久标识符",           "电子资源可选", "7.9"),
    ),
    format-string: "析出文献主要责任者. 析出文献题名: 析出文献其他题名信息[文献类型标识/文献载体标识]. 析出文献其他责任者//图书主要责任者. 图书题名: 其他题名信息. 版本. 出版地: 出版者, 出版年: 析出文献页码. 获取和访问路径. 永久标识符.",
    examples: (
      [周易外传: 卷5\[M\]/\/王夫之. 船山全书: 第 1 册. 修订版. 长沙: 岳麓书社, 2011: 983-1029.],
      [Weinstein L, Swartz M N. Pathogenic properties of invading microorganisms\[M\]/\/Sodeman W A Jr, Sodeman W A. Pathologic physiology: mechanisms of disease. 5th ed. Philadelphia: Saunders, 1974: 457-472.],
    ),
    extra: [
      - 汇编析出（`@incollection`）在 2025 版同样著录为 `[M]`（2025 §8.3 示例全为 `[M]`）；2015 版为 `[G]`，本包按 `version` 自动改判。
    ]
  ),

  // 8.4 连续出版物
  (
    chinese: "连续出版物",
    entrytype: "@periodical",
    mark: "J",
    gb-section: "8.4",
    required-fields: (
      ("主要责任者",   "有则必备",     "7.1"),
      ("题名",         "必备",         "7.2"),
      ("其他题名信息", "有则必备",     "7.2.3"),
      ("文献类型标识", "必备",         "7.3, A.1"),
      ("文献载体标识", "电子资源必备", "7.3, A.2"),
      ("年卷期或其他标识","有则必备",  "8.5.1"),
      ("出版地",       "有则必备",     "7.5.2"),
      ("出版者",       "有则必备",     "7.5.3"),
      ("出版年",       "有则必备",     "7.5.4"),
      ("获取和访问路径","电子资源必备","7.8"),
      ("永久标识符",   "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. 年, 卷(期)—年, 卷(期). 出版地: 出版者, 出版年. 获取和访问路径. 永久标识符.",
    examples: (
      [中华医学会湖北分会. 临床内科杂志\[J\]. 1984, 1(1)—. 武汉: 中华医学会湖北分会, 1984—.],
      [Public Library Quarterly\[J/OL\]. 1979, 1(1)—. Philadelphia: Taylor & Francis, 1979—. http://www.tandfonline.com/journals/wplq20.],
    ),
    extra: [
      - 连续出版物的年卷期区间由本包根据 `date`、`volume` 和 `number` 字段生成（如 `volume = {1-15}`、`date = {1957/1990}`，或表示仍在出版的 `date = {1957/..}`）。由于单个字段 token 无法生成交叉排列的起讫项，该区间合并为 `serial-block` token（类似 `imprint-block` 和 `series-block`）。该 token 仅用于连续出版物，其他类型返回空值。出版项末尾的出版年区间以起始年表示。连续出版物通常著录析出文献（见下）。
    ]
  ),

  // 8.5 连续出版物中的析出文献
  (
    chinese: "连续出版物中的析出文献",
    entrytype: "@article",
    mark: "J",
    gb-section: "8.5",
    required-fields: (
      ("析出文献主要责任者",   "有则必备",     "7.1"),
      ("析出文献题名",         "必备",         "7.2"),
      ("析出文献其他题名信息", "有则必备",     "7.2.3"),
      ("文献类型标识",         "必备",         "7.3, A.1"),
      ("文献载体标识",         "电子资源必备", "7.3, A.2"),
      ("析出文献其他责任者",   "可选",         "7.1"),
      ("连续出版物题名",       "有则必备",     "7.2"),
      ("其他题名信息",         "有则必备",     "7.2.3"),
      ("年卷期/版次标识与页码","有则必备",     "8.5.1"),
      ("获取和访问路径",       "电子资源必备", "7.8"),
      ("永久标识符",           "电子资源可选", "7.9"),
    ),
    format-string: "析出文献主要责任者. 析出文献题名: 析出文献其他题名信息[文献类型标识/文献载体标识]. 析出文献其他责任者. 连续出版物题名: 其他题名信息, 年, 卷(期/版次): 页码. 获取和访问路径. 永久标识符.",
    examples: (
      [于潇, 刘义, 等. 互联网药品可信交易环境中主体资质审核备案模式\[J\]. 清华大学学报 (自然科学版), 2012, 52(11): 1518-1523.],
      [张群, 程志宝, 石志飞. 惯性增强动力吸振器-浮置板轨道低频减振性能研究\[J/OL\]. 铁道学报, 2024-05-09. https://kns.cnki.net/kcms/detail/11.2104.u.20240507.1737.002.html.],
      [丁文详. 数字革命与竞争国际化\[N\]. 中国青年报, 2000-11-20 (15).],
      [Myburg A A, Grattapaglia D, Tuskan G A, et al. The genome of Eucalyptus grandis\[J/OL\]. Nature, 2014, 510: 356-362. https://www.nature.com/articles/nature13308. DOI: #eg-doi("10.1038/nature13308").],
    ),
    extra: [
      - 8.5.1.1 节支持文章编号、在线优先发表日期写法（如 `2024-05-09` 替代 `年, 卷(期): 页码`），本包通过 `date` 字段自动识别。
      - 8.5.1.4 节：从报纸析出的文献按“报纸名 + 出版日期 + 版次”著录（`[N]`）；`@newspaper` 或 `entrysubtype = newspaper` 自动采用报纸格式。
      - `pages` 与 `eid` 可提供同一著录项目：优先使用 `pages`；缺失时使用 `eid`（文章编号）。两者同时存在时仅输出 `pages`。依据 8.5.1.1 示例 6，即 GB/T 7714—2025 §7.7“无页码有文章编号的，应将文章编号按页码著录”，并参考李泽平在 #link("https://github.com/hushidong/biblatex-gb7714-2015/issues/230")[hushidong#230] 中的建议。
    ]
  ),

  // 8.6 会议录
  (
    chinese: "会议录",
    entrytype: "@inproceedings / @conference",
    mark: "C",
    gb-section: "8.6",
    required-fields: (
      ("主要责任者",   "有则必备",     "7.1"),
      ("题名",         "必备",         "7.2"),
      ("其他题名信息", "有则必备",     "7.2.3"),
      ("文献类型标识", "必备",         "7.3, A.1"),
      ("文献载体标识", "电子资源必备", "7.3, A.2"),
      ("会议名称",     "有则必备",     "—"),
      ("会议年份",     "有则必备",     "—"),
      ("引文页码",     "有则必备",     "7.7"),
      ("获取和访问路径","电子资源必备","7.8"),
      ("永久标识符",   "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]//会议名称, 会议年份: 引文页码. 获取和访问路径. 永久标识符.",
    examples: (
      [李妍, 王莹. 医疗机构保洁人员"一前五后"手卫生干预效果研究\[C\]/\/中华预防医学会医院感染控制分会第 31 次全国医院感染学术年会, 2022: 2.],
      [Wang Shanshan. Application of improved SOM neural network in intelligent auditing of hospital financial vouchers\[C/OL\]/\/2022 6th Asian Conference on Artificial Intelligence Technology, 2022: 2. https://ieeexplore.ieee.org/document/10137867. DOI: #eg-doi("10.1109/ACAIT56212.2022.10137867").],
    ),
    extra: [
      - 与 2015 版相比格式完全重写：2015 版无独立的会议录节，会议录归入专著（2015 §4.1）、其析出走专著析出（§4.2）；2025 版独立成节（§8.6），删除编者、出版地、出版者、版本项，只保留题名、会议名称、会议年份、引文页码、URL、永久标识符。
      - 整本会议录（不是析出）按 8.2 图书规则著录，对应 `@proceedings`。
    ]
  ),

  // 8.7 学位论文
  (
    chinese: "学位论文",
    entrytype: "@thesis / @mastersthesis / @phdthesis",
    mark: "D",
    gb-section: "8.7",
    required-fields: (
      ("主要责任者",         "有则必备",     "7.1"),
      ("题名",               "必备",         "7.2"),
      ("其他题名信息",       "有则必备",     "7.2.3"),
      ("文献类型标识",       "必备",         "7.3, A.1"),
      ("文献载体标识",       "电子资源必备", "7.3, A.2"),
      ("学位授予单位所在地", "有则必备",     "7.5.1, 7.5.2"),
      ("学位授予单位",       "必备",         "7.5.1, 7.5.3"),
      ("学位授予年",         "有则必备",     "7.5.1, 7.5.4"),
      ("引文页码",           "有则必备",     "7.7"),
      ("获取和访问路径",     "电子资源必备", "7.8"),
      ("永久标识符",         "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. 学位授予单位所在地: 学位授予单位, 学位授予年: 引文页码. 获取和访问路径. 永久标识符.",
    examples: (
      [王琦. 融合星载 GNSS-R 和 SAR 数据的高时空分辨率土壤湿度反演方法研究\[D\]. 武汉: 武汉大学, 2022: 87.],
      [井丽南. 支持状态可编程的 SDN 交换机关键技术研究\[D/OL\]. 北京: 中国科学院大学, 2022: 43. http://dpaper.las.ac.cn/Dpaper/detail/detailNew?paperID=20209289. CSTR: #eg-cstr("35001.37.01.33142.20220037").],
    ),
    extra: [
      - 字段语义与 2015 版一致，渲染等价；启用 #arg-ref("gb7714", "show-degree")[`show-degree`] 仍可在 `[D]` 后追加学位级别。
      - 2025 表 6 明确列出「引文页码」项（2015 版学位论文按专著著录、格式串本就含引文页码），本包按 `pages` 字段对接。
    ]
  ),

  // 8.8 报告
  (
    chinese: "报告",
    entrytype: "@report",
    mark: "R",
    gb-section: "8.8",
    required-fields: (
      ("主要责任者",   "有则必备",     "7.1"),
      ("题名",         "必备",         "7.2"),
      ("其他题名信息", "有则必备",     "7.2.3"),
      ("报告编号",     "有则必备",     "—"),
      ("文献类型标识", "必备",         "7.3, A.1"),
      ("文献载体标识", "电子资源必备", "7.3, A.2"),
      ("发布日期",     "有则必备",     "7.5.1, 7.5.4"),
      ("引文页码",     "有则必备",     "7.7"),
      ("获取和访问路径","电子资源必备","7.8"),
      ("永久标识符",   "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息: 报告编号[文献类型标识/文献载体标识]. 发布日期: 引文页码. 获取和访问路径. 永久标识符.",
    examples: (
      [汤万金, 杨跃翔, 刘文, 等. 人体安全重要技术标准研制最终报告: 7178999X-2006BAK04A10/10.2013\[R/OL\]. 2013-09-30. http://www.nstrs.cn/xiangxiBG.aspx?id=41707.],
      [Calkin D E, Ager A A, Thompson M P, et al. A comparative risk assessment framework for wildland fire management: the 2010 cohesive strategy science report: RMRS-GTR-262\[R/OL\]. 2011: 8-9. https://www.fs.usda.gov/rm/pubs/rmrs_gtr262.pdf.],
    ),
    extra: [
      - 格式简化：2025 版删除出版地与出版者；报告编号嵌入到 `[R]` 之前；只保留发布日期。
      - 当报告以图书 / 析出 / 连续出版物形式出现时，2025 8.8.1 通用要求规定按对应规则著录（即 8.2\~8.5）。
    ]
  ),

  // 8.9 标准
  (
    chinese: "标准",
    entrytype: "@standard",
    mark: "S",
    gb-section: "8.9",
    required-fields: (
      ("标准编号",     "必备",         "—"),
      ("标准名称",     "必备",         "7.2"),
      ("文献类型标识", "必备/可选",    "7.3, A.1"),
      ("文献载体标识", "电子资源必备", "7.3, A.2"),
      ("获取和访问路径","电子资源必备","7.8"),
      ("永久标识符",   "电子资源可选", "7.9"),
    ),
    format-string: "标准编号 标准名称[文献类型标识/文献载体标识]. 获取和访问路径. 永久标识符.",
    examples: (
      [GB/T 3792—2021 信息与文献 资源描述\[S\].],
      [GB/T 20090.16—2016 信息技术 先进音视频编码 第 16 部分: 广播电视视频\[S/OL\]. http://c.gb688.cn/bzgk/gb/showGb?type=online&hcno=1D4AC2D4256C8DE7E0AA286CA7649300.],
      [ISO 21378: 2019 Audit data collection\[S\].],
    ),
    extra: [
      - 完全重写：2025 版去除作者、出版地、出版者、出版年；只保留"标准编号 标准名称\[S\]. URL. 永久标识符."。
      - 标准编号在最前；其与标准名称之间用*空格*分隔（不是冒号）。
      - 表 8 注明标准化文件的 `[S]` 为可选项，其他文献类型的标识为必备项。本包默认著录 `[S]`；如需省略，可设置 #arg-ref("gb7714", "show-mark")[```typ show-mark: (S: false)```]，无需增加专用参数。见#link(<display-control>)[“按条目控制显示”]。
    ]
  ),

  // 8.10 专利
  (
    chinese: "专利",
    entrytype: "@patent",
    mark: "P",
    gb-section: "8.10",
    required-fields: (
      ("专利申请者/所有者", "必备",         "7.1"),
      ("题名",             "必备",         "7.2"),
      ("其他题名信息",     "有则必备",     "7.2.3"),
      ("专利申请号",       "必备",         "—"),
      ("文献类型标识",     "必备",         "7.3, A.1"),
      ("文献载体标识",     "电子资源必备", "7.3, A.2"),
      ("公告(公开)日期",   "有则必备",     "7.5.1, 7.5.4.2"),
      ("引文页码",         "有则必备",     "7.7"),
      ("获取和访问路径",   "电子资源必备", "7.8"),
      ("永久标识符",       "电子资源可选", "7.9"),
    ),
    format-string: "专利申请者/所有者. 题名: 其他题名信息: 专利申请号[文献类型标识/文献载体标识]. 公告(公开)日期: 引文页码. 获取和访问路径. 永久标识符.",
    examples: (
      [邓一刚. 全智能节电器: CN200610171314.3\[P\]. 2008-01-16: 8-9.],
      [西安电子科技大学. 光折变自适应光外差探测方法: CN01128777.2\[P/OL\]. 2002-03-06. http://211.152.9.47/sipoasp/zljs/hyjs-yx-new.asp?recid=01128777.2&leixin=0.],
      [Trisco Icap Pty Ltd. Storage and delivery system: AU2022228203A\[P/OL\]. 2022-10-06. https://worldwide.espacenet.com/patent/search/family/061561249/publication/AU2022228203A1?q=AU2022228203A.],
    ),
    extra: [
      - 专利国（国别）随版本不同：GB/T 7714—2005 将专利国单独著录于题名与专利申请号之间（`题名：专利国，专利申请号`）；GB/T 7714—2015 与 2025 均不单独著录专利国（2025 建议把国别前缀并入专利申请号，如 `CN200610171314.3`）。因此本包 `version: 2005` 的内建条目格式为 `holder|author. title：country，number<mark-medium>. date. access.`（较上方多一个 `country` 项，取自 `location` / `address`），2015 / 2025 则按上方所示著录。
      - .bib 写法：专利申请号写 `number = {CN200610171314.3}`；`version: 2005` 下的专利国写 `location = {中国}`（2015 / 2025 两版此字段不参与拼接）。
      - "引文页码"在公告(公开)日期之后以 `: 引文页码` 接续；网络专利末尾的永久标识符在 2025 统一由 7.9 节"永久标识符"著录。
    ]
  ),

  // 8.11 网站、网页
  (
    chinese: "网站、网页",
    entrytype: "@online / @webpage",
    mark: "EB",
    gb-section: "8.11",
    required-fields: (
      ("主要责任者",     "有则必备",     "7.1"),
      ("题名",           "必备",         "7.2"),
      ("其他题名信息",   "有则必备",     "7.2.3"),
      ("文献类型标识",   "必备",         "7.3, A.1"),
      ("文献载体标识",   "必备",         "7.3, A.2"),
      ("创建或修改日期", "有则必备",     "7.6"),
      ("引用日期",       "必备",         "7.6"),
      ("获取和访问路径", "必备",         "7.8"),
      ("永久标识符",     "可选",         "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. (创建或修改日期)[引用日期]. 获取和访问路径. 永久标识符.",
    examples: (
      [中国国家博物馆\[EB/OL\]. \[2025-05-06\]. https://www.chnmuseum.cn/.],
      [许振超. "好好干, 当一个好工人"\[EB/OL\]. (2025-02-17)\[2025-06-22\]. http://cpc.people.com.cn/n1/2025/0217/c443712-40419790.html.],
    ),
    extra: [
      - 2025 版 8.11 将网站（8.11.2）与网页（8.11.3）分列两节，但著录格式相同；本包均采用内置的电子资源驱动。
      - 与 2015 版的关键差异：删除出版地 / 出版者；只保留"(创建/修改日期)\[引用日期\]. URL. 永久标识符."。
      - 文献类型标识代码 `[EB]` 在 2025 版中专指“网站、网页”，不再表示 2015 版的“电子公告”。
    ]
  ),

  // 8.12 档案
  (
    chinese: "档案",
    entrytype: "@archive",
    mark: "A",
    gb-section: "8.12",
    required-fields: (
      ("主要责任者",     "有则必备",     "7.1"),
      ("题名",           "必备",         "7.2"),
      ("其他题名信息",   "有则必备",     "7.2.3"),
      ("档号",           "有则必备",     "—"),
      ("文献类型标识",   "必备",         "7.3, A.1"),
      ("文献载体标识",   "电子资源必备", "7.3, A.2"),
      ("收藏者所在地",   "有则必备",     "7.5.1, 7.5.2"),
      ("收藏者",         "有则必备",     "7.5.1, 7.5.3"),
      ("形成日期",       "有则必备",     "7.5.1, 7.5.4"),
      ("引文页码",       "有则必备",     "7.7"),
      ("获取和访问路径", "电子资源必备", "7.8"),
      ("永久标识符",     "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息: 档号[文献类型标识/文献载体标识]. 收藏者所在地: 收藏者, 形成日期: 引文页码. 获取和访问路径. 永久标识符.",
    examples: (
      [李鸿章. 奏请上海道库洋务外销要款无款可筹仍拨药厘接济事: 04-01-35-0399-039\[A\]. 北京: 中国第一历史档案馆, 1887 (光绪十三年三月十三日).],
      [湖北省建设厅. 湖北省建设厅关于检发实业部农工矿业团体登记规则的布告、训令及湖北省政府的训令: LS031-001-0001-001\[A/OL\]. 武汉: 湖北省档案馆, 1931-11-07. https://www.hbda.gov.cn/pdf/LS031-001-0001-001.PDF.PDF.],
    ),
    extra: [
      - 2025 版 8.12 节正式独立成节；2015 版对应"专著中的档案"。
      - `number` 字段表示档号，自动嵌入到 `[A]` 之前，即 `主要责任者. 题名: 档号\[A\]. 收藏者所在地: 收藏者, 形成日期.`。
      - `@letter` / `@legislation` 等亲缘类型也统一映射到 `[A]`。
    ]
  ),

  // 8.13 地图
  (
    chinese: "地图",
    entrytype: "@map",
    mark: "CM",
    gb-section: "8.13",
    required-fields: (
      ("主要责任者",   "有则必备",     "7.1"),
      ("题名",         "必备",         "7.2"),
      ("其他题名信息", "有则必备",     "7.2.3"),
      ("比例尺",       "有则必备",     "—"),
      ("文献类型标识", "必备",         "7.3, A.1"),
      ("文献载体标识", "电子资源必备", "7.3, A.2"),
      ("版本",         "有则必备",     "7.4"),
      ("出版地",       "有则必备",     "7.5.2"),
      ("出版者",       "有则必备",     "7.5.3"),
      ("出版年",       "有则必备",     "7.5.4"),
      ("尺寸",         "纸质单幅地图必备", "—"),
      ("获取和访问路径","电子资源必备","7.8"),
      ("永久标识符",   "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息. 比例尺[文献类型标识/文献载体标识]. 版本. 出版地: 出版者, 出版年. 尺寸. 获取和访问路径. 永久标识符.",
    examples: (
      [胡健民. 东南极拉斯曼丘陵地区地质图. 1: 25 000\[CM\]. 北京: 科学出版社, 2021. 128 cm×84 cm.],
      [刘祥沈. 沈阳市政区图. 1: 170 000\[CM\]. 武汉: 武汉大学出版社, 2016. 138 cm×96 cm.],
      [国家测绘地理信息局. 一带一路经济走廊及其途经城市分布地势图\[CM/OL\]. http://ydyl.china.com.cn/2016-10/27/content_39582227.htm.],
    ),
    extra: [
      - 2025 版将地图单列一节，文献类型标识代码仍为 `[CM]`（2015 版称“舆图”，也使用 `[CM]`；2005 版未规定该代码，本包按 `[Z]` 处理）。
      - 关键字段位置：`scale`（比例尺）紧贴 `[CM]` 之前；`dimensions`（尺寸）写在出版年之后、URL 之前。
      - `dimensions` 仅纸质单幅地图必备；电子地图可省略。
    ]
  ),

  // 8.14 数据集
  (
    chinese: "数据集",
    entrytype: "@dataset",
    mark: "DS",
    gb-section: "8.14",
    required-fields: (
      ("主要责任者",       "有则必备",     "7.1"),
      ("题名",             "必备",         "7.2"),
      ("其他题名信息",     "有则必备",     "7.2.3"),
      ("文献类型标识",     "必备",         "7.3, A.1"),
      ("文献载体标识",     "电子资源必备", "7.3, A.2"),
      ("版本",             "可选",         "7.4"),
      ("发布平台",         "电子资源可选", "7.5.1"),
      ("发布或修改日期",   "有则必备",     "7.6"),
      ("引用日期",         "必备",         "7.6"),
      ("获取和访问路径",   "电子资源必备", "7.8"),
      ("永久标识符",       "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. 版本. 发布平台(发布或修改日期)[引用日期]. 获取和访问路径. 永久标识符.",
    examples: (
      [周壮, 李盛阳, 吴薇, 等. 天宫二号遥感图像自然景物分类科学数据\[DS/OL\]. V1.0. 国家基础学科公共科学数据中心(2023-09-10)\[2025-07-15\]. https://www.nbsdc.cn/general/dataLinks/CSTR:16666.11.nbsdc.tfpbwtqf.],
      [IHME. Global burden of disease study 2019 (GBD 2019) data resources\[DS/OL\]. Global Health Data Exchange(2021)\[2025-07-15\]. https://ghdx.healthdata.org/gbd-2019.],
    ),
    extra: [
      - 2025 版 8.14 节独立。`publisher` 字段在数据集条目里语义为*发布平台*。
      - `version` 字段（如 V1.0）紧贴 `[DS]` 之后；缺失时本包跳过该位置。
      - 永久标识符以 `cstr` 字段对接（中国 CSTR 标识符），与 `doi` 同级。
    ]
  ),

  // 8.15 预印本
  (
    chinese: "预印本",
    entrytype: "@preprint",
    mark: "PP",
    gb-section: "8.15",
    required-fields: (
      ("主要责任者",     "有则必备",     "7.1"),
      ("题名",           "必备",         "7.2"),
      ("其他题名信息",   "有则必备",     "7.2.3"),
      ("文献类型标识",   "必备",         "7.3, A.1"),
      ("文献载体标识",   "电子资源必备", "7.3, A.2"),
      ("版本",           "有则必备",     "7.4"),
      ("出版平台",       "电子资源可选", "7.5.1"),
      ("创建或修改日期", "有则必备",     "7.6"),
      ("引用日期",       "必备",         "7.6"),
      ("获取和访问路径", "必备",         "7.8"),
      ("永久标识符",     "电子资源可选", "7.9"),
    ),
    format-string: "主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. 版本. 出版平台(创建或修改日期)[引用日期]. 获取和访问路径. 永久标识符.",
    examples: (
      [肖玲, 张雪, 王永. 数据要素的统计测算方法探究\[PP/OL\]. PSSXiv(2024-07-02)\[2024-09-30\]. https://zsyyb.cn/abs/202408.01096. CSTR: #eg-cstr("32012.36.PSSXiv.202408.01096").],
      [Jenkins S D, Ruostekoski J. Controlled manipulation of light by cooperative response of atoms in an optical lattice\[PP/OL\]. V2. (2012-03-18)\[2020-06-24\]. https://doi.org/10.48550/arXiv.1112.6136.],
    ),
    extra: [
      - 2025 版 8.15 节*新增独立类型代码* `[PP]`（GB/T 7714—2015 没有该代码）。
      - 出版平台依次读取 `archiveprefix`、`eprinttype` 和 `publisher`。
      - 带 `arxiv` 字段或 `entrysubtype = preprint` 的 `@article` 也按预印本著录。三种写法在 2025 版中的结果相同。
      - 永久标识符按 `cstr` > `doi` > `eprint` 优先级输出。
    ]
  ),
)

#render-entry-types-2025(entry-type-docs-2025)


= 自定义条目格式 <custom-format>

使用 #arg-ref("gb7714", "custom-drivers")[`custom-drivers`] 可为指定类型的文献设置著录格式。未指定的类型继续使用内置格式。

== 何时使用

- 如果只需调整断字、上标括号或 ISBN 显示等行为，使用 #arg-ref("gb7714", "show-pid")[`show-pid`]、#arg-ref("gb7714", "emphasis")[`emphasis`] 等参数即可，无须自定义模板。
- 更改著录项目及其排列顺序，使用 `custom-drivers`。
- 添加按语言选择的文字，使用 `custom-terms`；读取自定义数据字段，使用 `custom-fields`。
- 修改“等”“编”“译”等内置术语，也使用 `custom-terms`，可覆盖的名称见 @builtin-terms。
- 修改析出文献标识符 `//` 时，使用 `component-part-separator`。该参数属于标点设置，不使用 `custom-terms`。默认值为 `"//"`；旧式“见:”或“In:”可写为 ```typc component-part-separator: (zh: ". 见: ", en: ". In: ")```。未指定的语言仍使用 `//`。#footnote[该参数按字面输出标点，不自动转换全角、半角。]

常用格式调整应优先使用现有参数；只有需要改变著录结构时才编写模板。

== `custom-drivers` 写法

字典形式 `(<键>: "<模板字符串>", ...)`。键有两种，匹配优先级：

- *条目类型*（小写，对应 #BibLaTeX 的 `entry_type`，如 `book` / `inproceedings` / `patent` / `online` / `standard` 等，也包括解析器保留的非标准类型）；
- *文献类型标识代码*：使用 GB/T 7714 附录 A 中的大写代码，如 `M`、`J`、`D`、`S`、`N` 和 `EB`，也可使用 `custom-marks` 中登记的自定义代码。例如，`D:` 匹配学位论文，`J:` 匹配期刊论文。

匹配时先检查 `entry_type`，未匹配时再检查大写文献类型标识代码；匹配到的模板决定条目的著录格式。标识由 `entrysubtype`、`usera` 和 `mark` 等字段确定。内部类别名（如 `monograph`、`component-part`）不能用作键。

```typ
#show: gb7714(
  custom-drivers: (
    // 仅作用于 @patent
    patent: "author . title ?<country {, } number> mark-medium . ?<date> urldate access",
    // 仅作用于 @incollection；其他析出文献类型（如 @inbook）可分别设置。
    // 也可使用大写文献类型标识代码，例如 D: 可匹配全部学位论文。
    incollection: "author . component-part-title-block . {In:} booktitle . imprint-block {: } pages",
  ),
)
#bibliography(read("refs.bib"))
```

#arg-ref("print-bib", "custom-drivers")[`bibliography`] 与 #arg-ref("cite", "custom-drivers")[```typ #cite(note: "foot", ..)```] 也接受同名参数，默认 `auto` 继承全局；传字典则在该次调用范围内临时覆盖。

== 模板字符串语法

模板字符串由标识符（token）、字面量和标点组成。标识符提供字段内容或预定义著录项目，字面量用于插入固定文字。

=== 标识符（token）

标识符采用 `[a-z][a-z0-9_-]*` 形式，如 `author`、`title` 和 `imprint-block`。可使用内置标识符或通过 `custom-terms`、`custom-fields` 定义的名称。内置项目见 @template-built-in-tokens。

=== 字面量字符串

用一对花括号 `{…}` 包裹的内容原样进入条目（verbatim，含 CJK、空格和标点，不受标点矫正与软空格影响；作用类似 #BibTeX 的花括号保护）。要输出花括号本身，使用 `\{` `\}` 转义。这是模板中唯一需要转义的字符；由于模板写在 Typst 字符串中，源码应写成 `\\{` `\\}`。反引号没有特殊含义，可直接输出。

```typ
// 模板片段
"creator {《} titles {》} "
```

#callout(kind: "warning", title: "成对定界符应与 token 位于同一组")[
  字面量位于非空 token 与可空 token 之间时，视为后者的前导分隔符；后者为空时，该字面量也会省略。这可避免 `address{：}publisher` 在出版者缺失时留下冒号，但成对定界符需要另行分组：

  ```typ
  "title{”}<{, }volume>"     // volume 为空时，右引号也被省略
  ```

  正确写法是把定界符和它包住的 token 一起放进可选组——组为空时两个符号一起消失，组非空时一起出现：

  ```typ
  "<{“}titles{”}>"           // 定界符与题名同时显示或省略
  "titles<{[}mark{]}>"       // 同理
  ```

  可选组 `<…>` 用于表示可能缺失的内容。把定界符放在组内，内容缺失时定界符也会一同省略。
]

=== 标点 <template-punct-section>

模板中的结构标点按 `bib-punct-style` 输出；采用全角设置时，`,`、`(` 等变为 `，`、`（`。句点和析出斜杠保持半角，其他非结构标点按字面处理，也可由 `custom-punct` 覆盖。需要保留某个标点字符时放入花括号，如 `{,}`；花括号字面量仍参与所在组的去留。

方括号 `[` `]` 是普通标点，不是条件组。直接写 `[M]` 时，它仍可能随邻近空项一起省略；文献标识宜使用 `mark-medium`。`?<`、`&<`、`>`、`{`、`}`、`=>` 和 `|` 是模板语法符号，按字面输出时用 `{...}` 包裹；字面花括号用 `\{`、`\}`。

=== 自动空白：软空格

模板里的单个空格用于提高源码可读性，是否输出由下列统一规则决定：

- 一般保留一个空格，如 `author title` 输出“author title”；
- 句点、逗号、冒号、分号、问号、感叹号、右括号及全角标点之前省略空格；全角标点或左括号之后也省略空格。

所以 `author . title` 输出“author. title”；中文条目的 `title , year` 输出“书名，2020”。

需要保留固定空格时，可使用花括号字面量，如 `author { , } title`；也可连续输入多个空格，输出的空格数比输入少一个。

=== 条件组 `?<...>` / `&<...>`

条件组按内部数据 token（标识符 / 别名 / 子组，不含字面标点）的空缺情况决定整组去留：

- `?<…>`（任一项非空）：组内任一 token 非空时渲染整组，全部为空时省略。适用于可选字段，如 `?<：subtitle>` 和 `?<volume, number>`。
- `&<…>`（全部非空）：组内全部 token 非空时才渲染。适用于字段必须成组出现的结构，如 `&<（第 volume 卷共 count 册）>`。

组满足条件时，无对应内容的分隔符会被省略。第一个数据 token 之前的字面量作为整组前缀：例如，`?<附： edition note>` 中只有 `note` 非空时，仍输出“附：”和 `note`。

圆括号和方括号都是普通标点。分组使用 `?<…>`、`&<…>` 或 `<… => …>`；需要输出尖括号本身时，使用 `{<}`、`{>}`。

=== 条件 `<EXPR => body>`

`<EXPR => body>` 仅在条件 `EXPR` 成立时输出 `body`。它可以与按内容是否为空判断的条件组嵌套使用：

- *比较条件* `field=value` / `field!=value`：`mark` 比较文献类型标识代码，`medium` 比较文献载体标识代码，`entry-type` 比较条目类型，其余名称比较 .bib 字段值。缺失字段按空字符串处理。带连字符的名称由本包计算，不带连字符的名称视为 .bib 字段；
- *存在条件*：单独写 `field`（如 `<doi => …>`）表示该 token 有输出；前置 `!` 表示无输出；
- *多个候选值* `field=v1?v2`：匹配其中任意值时成立，例如 `mark=M?R` 表示图书或报告；
- *与* `&` ／ *或* `?` ／ *非* `!`：`mark=M & langid=english`（且）、`mark=M ? langid=english`（或）、`!mark=J`（非，等价 `mark!=J`）；优先级 `!` > `&` > `?`；
- *分组* `<…>`：`<mark=M ? mark=J> & langid=english` 用尖括号做布尔括号、覆盖优先级。

`mark=M` 比较条目的文献类型标识代码，不受显示参数影响；单独写 `mark` 则检查实际输出，因此 `show-mark: false` 时为假。

例如，`<mark=M => {（图书）}>` 仅为图书添加“（图书）”；`<mark=J & !doi => …>` 仅用于没有 DOI 的期刊；`<entry-type!=article => note>` 仅为非期刊条目著录 `note`。`body` 可以是字面量或字段 token。谓词只决定分支是否采用；如需同时判断 `body` 是否为空，应嵌套条件组，例如 `<mark=C => &<editor booktitle>>`。

#callout(kind: "note", title: "用 token 组合 `[M/OL]`：推荐写法")[
  直接组合 `mark` 和 `medium` 时，需要自行处理方括号和斜杠，相关规则见@template-punct-section。要复现内置 `mark-medium` 的行为，即缺少 `mark` 时整项省略、缺少 `medium` 时仅省略 `/OL`，可写成：

  ```typ
  custom-drivers: (book: "author . title <mark => <[mark<{/}medium>]>> . publisher")
  ```

  外层 `<mark => …>` 决定整块是否显示；`<[…]>` 使方括号和内容同时出现；`<{/}medium>` 只在存在载体码时输出斜杠和载体码。其行为与内置 `mark-medium` 相同。

  仅使用条件组 `?<[mark<{/}medium>]>` 仍不充分：当 `show-mark: false` 且条目包含载体类型时，会输出无意义的 `[/OL]`。这是因为条件组在任一数据 token 非空时即成立，无法限定为仅由 `mark` 决定。空值谓词用于表达这一条件。
]

各条件分支独立求值。多个条件同时为真时，对应内容都会输出；需要互斥时，应分别写正条件和反条件。

=== 默认分支 `< => body>` 与内置格式 `built-in`

`=>` 左侧为空时表示默认分支，仅在同一层的其他条件均不成立时输出。嵌套组内的默认分支只检查该组内的条件。

`built-in` 输出当前条目按内置格式生成的完整著录结果。以下示例为西文期刊条目指定格式，其余条目使用内置格式：

```typ
custom-drivers: (
  // 西文条目采用自定义格式，其余条目仍使用国标内置驱动
  article: "<entry-lang=en => author{, }<{“}titles{”}><{, }journaltitles>{.}>< => built-in>",
)
```

若模板中没有 `built-in`，就必须写出该类型的完整格式。使用 `built-in` 可在内置结果前后增加内容，也能避免复制整段内置模板。

`built-in` 可以出现在条件分支或可选组里，也能与其他内容并列，例如 `built-in{ 补一段}`。它不读取当前模板，因此不会自引用。

#callout(kind: "warning", title: "条件均不成立时的输出")[
  `custom-drivers` 覆盖某一类型后，如果没有条件成立，该条目只保留编号。可用 `< => built-in>` 调用内置格式，或写明默认格式。
]

`=>` 左侧的空白不影响解析（`mark=M&x` 与 `mark=M & x` 等价）。值中包含空格或冒号时，使用花括号原样定界（如 `t={10:30}`）。`|` 用于依次选择非空值，`=>` 用于条件判断，二者相互独立。

`?` 既可表示逻辑“或”，也可分隔同一字段的多个候选值。当它后面直接出现 token 名时会产生歧义：`mark=M ? doi` 既可能表示“`mark` 为 M，或存在 DOI”，也可能表示“`mark` 为 M 或 doi”。此时编译器会报错。检查字段是否存在时写 `mark=M ? <doi>`；把 `doi` 当作 `mark` 的候选值时写 `mark=M?{doi}`。候选值不是 token 名时没有歧义，如 `entry-type=book?article`。

`=>` 分隔条件与分支内容。每个条件分支只能包含一个 `=>`，且不能在组外使用。需要在分支内继续判断时，使用嵌套条件组，如 `<mark=C => &<…>>`。

=== 别名链 `A | B`

`A` 非空时输出 `A`，否则输出 `B`。可以写成 `A | B | C`，按照从左到右的顺序选择第一个非空值，如 `location | address | publisher`。

两侧均可使用单个 token、字面量、条件组 `?<…>` / `&<…>` 或条件分支 `<… => …>`：

- `?<副：subtitle> | title`：有副题名时输出“副：副题名”，否则输出题名；
- `title | ?<副：subtitle>`：题名缺失时输出副题名组；
- `?<甲 subtitle> | ?<乙 note>`：在两个组中选择；
- `title | <mark=EB => {网页默认处理}>`：题名缺失时使用条件分支。

=== 分隔符与空白

引擎依次处理内容、字面量和后续内容。token 为空时，两侧字面量会合并，并按国标标点层级取舍：

- *段间句点* `.` 分开「著录项」，其余（`，` `：` `//`、括号）在项*内部*绑定；
- 于是：空 token 两侧只要有*段间句点*，就留那个句点——它标的是两个*段*的边界，与消失的那个 token 无关；两侧都没有句点，就留*右边*那段（它是下一个 token 的前导，如页码前的 `：`）。

```typ
// date 为空时省略圆括号，保留题名与引用日期之间的句点。
"title<mark-medium>. <（date）>urldate."      // 输出：题名[EB/OL]. [2025-05-06].

// address 为空时省略冒号，保留著录项目之间的句点。
"edition. address：publisher，date"           // 输出：2 版. 社，2020

// 两侧都没有句点时，保留右侧标点。
"volume<（number）>：pages"                   // 输出：12：100-115
```

例外：下一段内容*自带段边界*时（析出符 `//` 开头，如 `//母体`），前面不再补任何分隔符——GB 的析出著录就是 `析出题名[M]//母体`，`//` 前面没有句点。

组内的*尾部*字面量保留为后缀，便于写出 `?<editor {, 编}>` 这类「editor 存在则补 `, 编`」的句式；尾部没有下一段可分隔，所以那里不做塌缩。

#callout(kind: "note", title: "空条件前的字面量：当前限制")[
  当前实现会丢失紧邻假条件之前的某些字面量，即使写成 `{[S]}` 也可能如此（#link("https://github.com/typst-omni-gb7714/omni-gb7714/issues/16")[issue \#16]）。需要标识时使用 `mark-medium`；固定文字与题名属于同一项时，可将其放在同一个非空条件组内，如 `<title {[S]}>`。这不能解释为所有花括号内容都会无条件保留。
]

#demo("固定标识随题名保留，出版项可省略")[```typ
#show: gb7714(custom-drivers: (
  standard: "number ,<title {[S]}> <publisher => .location :publisher ,year> .",
))
#bibliography(bytes("@standard{bare-standard, number={GB/T 16159-1996}, title={Test standard title}}"), full: true)
```]

=== 末尾句点

由 #arg-ref("gb7714", "show-end-period")[`show-end-period`] 控制：

- `auto`（默认）：单个著录项目后不添加句点，多个著录项目后添加句点；
- `true`：条目末尾不是句点时添加 `.`；
- `false`：不添加句点。

已有半角或全角句点时不重复添加。问号、叹号和中文句号视为字段内容，不替代条目末尾的结构句点。

=== 单项著录 <single-block-degenerate>

“单项”指条目仅含责任者、题名、版本、出版项、丛书、获取和访问路径或永久标识符中的一项，同组字段合计为一项。`mark` 和 `medium` 不另计。#arg-ref("gb7714", "show-end-period")[`show-end-period: auto`] 在单项著录后不添加句点；#arg-ref("gb7714", "show-mark")[`show-mark: auto`] 则省略单项著录的文献类型标识代码。两个参数相互独立。

例如，§7.3 的 `马寅初讲义[M]` 是单项著录，不加末尾句点；标准文献 `编号 名称[S]` 包含多个著录项目，保留末尾句点。`custom-drivers` 按模板实际输出的数据项数判断。

== 内置 token 速查 <template-built-in-tokens>

下表中「相关参数」列代表该 token 的输出会受到哪些 #arg-ref("gb7714", "show-mark")[`show-*`] 等参数的影响。所有 token 名禁止与 `custom-terms` 字段重名。

「字段取值顺序」表示 token 查找数据的先后次序，使用第一个非空字段。模板中直接写 token 名即可。若要改变顺序，可用 `|` 明确列出字段，例如 ```typ publisher|institution```。此时应写全所需的候选字段，以免与内置规则不一致。

#table(
  // 列宽写死比例：token 名列若用 auto，会被 `url / doi / cstr / …` 那一格的自然宽度
  //   撑到七成版心，把后两列挤成一指宽（CJK 被拉散、内容溢出框外）。
  columns: (28%, 42%, 30%),
  align: (left, left, left),
  table.header(repeat: true, [Token], [含义 / 字段取值顺序], [相关参数]),

  [`creator`], [责任者；按字段顺序选择，并处理佚名和责任者截断\ #text(size: 0.85em, fill: luma(90))[一般依次读取 `author`、`editor`、`translator`、`holder`、`editora`；\ 专利先读 `holder`；析出文献只读 `author`、`translator`、`holder`]], [`bib-et-al-min` / `bib-et-al-use-first` / `show-anon` / `show-et-al` / `bib-name-style`],
  [`author`], [单独的 author 字段（按责任者格式处理，但不使用其他字段替代，也不补佚名；这些规则只适用于 `creator`）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`author`]], [同 `creator`（除 `show-anon`）],
  [`editor-other`], [析出文献或专著的编者，仅在存在 author 时输出；学位论文不输出\ #text(size: 0.85em, fill: luma(90))[读取 `editor`]], [同上及 `dedup-author-editor`],
  [`translator`], [译者作「其他责任者」\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`translator`（学位论文 D 不输出）]], [同上],
  [`editor`], [仅 editor 字段（不带角色后缀）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`editor`]], [同上],
  [`bookauthor`], [仅 bookauthor 字段\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`bookauthor`。母体责任者*没有*单 token，模板里自己写 ```typ bookauthor|editor```]], [同上],

  [`titles`], [完整题名，由 `title`、`subtitle`、`titleaddon` 依次组成\ #text(size: 0.85em, fill: luma(90))[字段间用冒号连接]], [—],
  [`title`], [单独的 title 字段（不组合副题名或其他题名；组合形式见 `titles`）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`title`]], [—],
  [`subtitle`], [其他题名信息\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`subtitle`]], [—],
  [`titleaddon`], [其他题名信息\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`titleaddon`]], [—],
  [`title-block`], [专著的题名部分，包含题名、类型和载体标识，以及卷号或文献号\ #text(size: 0.85em, fill: luma(90))[使用 `title`、`mark-medium` 和卷号或文献号]], [`show-mark` / `show-medium` / `space-before-mark` / `titles-text-case` / `hyperlink-title`],
  [`component-part-title-block`], [析出文献的题名部分，包含题名、类型和载体标识\ #text(size: 0.85em, fill: luma(90))[使用析出文献的题名格式]], [同上],
  [`mark`], [文献类型标识，如 `[M]`、`[J]`、`[P]`，不含载体标识\ #text(size: 0.85em, fill: luma(90))[依次检查 note 兼容规则、`usera`、`entrytypeid`、`entrysubtype`、`mark`、`custom-marks`、版本默认值和内置类型表]], [`show-mark` / `space-before-mark`],
  [`mark-medium`], [文献类型和载体标识，如 `[M/OL]`、`[J]`\ #text(size: 0.85em, fill: luma(90))[类型标识同 `mark`；载体按显式数据、文献类型与访问数据判断，不看路径是否显示]], [`show-mark` / `show-medium` / `space-before-mark`],

  [`booktitles`], [完整的专著或论文集题名\ #text(size: 0.85em, fill: luma(90))[依次使用 `booktitle`、`booksubtitle`、`booktitleaddon`]], [—],
  [`booktitle`], [单独的 booktitle 字段（不组合副题名；组合形式见 `booktitles`）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`booktitle`]], [—],
  [`booksubtitle`], [专著 / 论文集副题名（原值）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`booksubtitle`]], [—],
  [`booktitleaddon`], [专著 / 论文集附加题名（原值）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`booktitleaddon`]], [—],
  [`journaltitles`], [完整刊名，包含副标题和附加标题\ #text(size: 0.85em, fill: luma(90))[优先读取 `journaltitle`，否则读取 `journal`；`short-journal: true` 时改用 `shortjournal`]], [`short-journal` / `emphasis`],
  [`journal`], [单独的 journal 字段（`journaltitle` 的 #BibLaTeX 别名）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`journal`]], [—],
  [`journaltitle`], [期刊主标题原值（不含 subtitle / addon）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`journaltitle`]], [—],
  [`shortjournal`], [期刊缩写形式原值\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`shortjournal`]], [`short-journal`],
  [`journalsubtitle`], [期刊副标题原值\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`journalsubtitle`]], [—],
  [`journaltitleaddon`], [期刊附加标题原值\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`journaltitleaddon`]], [—],
  [`series`], [丛书名原始字段\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`series`]], [—],
  [`series-block`], [`(丛书名)` 或 `(丛书名, 序号)`\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`series`（+ `number`，未被类型标识占用时）]], [—],
  [`serial-block`], [连续出版物「年, 卷(期)—年, 卷(期)」整段（区间起讫交叉排列；开区间表示仍在出版）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`date` / `volume` / `number`；仅连续出版物有值，其他类型返回空值]], [—],
  [`edition`], [版本项（`@report` 优先 `version` 字段）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`@report` 优先 `version`，否则 `edition`]], [—],
  [`version`], [版本号原值（与 `edition` 区分使用，常见于 `@report` / 软件 / 标准的版次）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`version`]], [—],
  [`volume`], [卷号；专著以 `第N卷` / `vol. N` 渲染，期刊 / 报纸 / 连续出版物出不加“卷”的卷号（与内置「年, 卷(期)」格式一致）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`volume`]], [—],
  [`number`], [number 字段原值\ #text(size: 0.85em, fill: luma(90))[此 token 不读取 `issue`；只有内置连续出版物格式会在缺少 `number` 时读取 `issue`]], [—],
  [`pages`], [引文页码\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`pages`]], [`page-range-separator`],

  [`year`], [出版年\ #text(size: 0.85em, fill: luma(90))[优先读取 `date`，否则读取 `year`，并只保留年份]], [—],
  [`date`], [日期：图书、期刊等取出版日期；2025 版网页、独立数据集和预印本取创建、发布或修改日期\ #text(size: 0.85em, fill: luma(90))[优先读取 `date`；资源日期缺失时可取真实声明的 `year`，不把推定出版年当成创建日期]], [—],
  [`month` / `day`], [出版月 / 日的原值（一般和 `date` 字段一起用）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`month`]], [—],
  [`urldate`], [`[YYYY-MM-DD]` 引用日期\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`urldate`]], [`show-urldate`],

  [`address` / `location`], [出版地\ #text(size: 0.85em, fill: luma(90))[优先读取 `location`，否则读取 `address`]], [—],
  [`publisher`], [出版者\ #text(size: 0.85em, fill: luma(90))[通常依次读取 `publisher`、`school`、`organization`、`institution`；连续出版物、档案和学位论文优先读取 `institution`]], [—],
  [`school` / `organization` / `institution`], [对应字段的原值（用于自定义模板里精确引用某一种"出版者"语义）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`school`]], [—],
  [`holder`], [专利申请者 / 所有者（人名格式与 `author` 一致）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`holder`]], [`bib-et-al-min` / `bib-et-al-use-first` / `bib-name-style`],
  [`imprint-block`], [完整出版项 `出版地: 出版者, 出版年`，含占位符与省略规则\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：出版地同 `address`、出版者同 `publisher`、出版年同 `date`；字段*真的没有*时才按 `show-sine-loco` / `show-sine-nomine` 补占位，你自己写进 `.bib` 的 `[S.l.]` 原样著录]], [`show-sine-loco` / `show-sine-nomine`],

  [`access`], [获取路径和永久标识符\ #text(size: 0.85em, fill: luma(90))[包含 `url` 以及启用的 DOI、CSTR、ISBN、ISSN、eprint 和 `custom-pids`]], [`show-url` / `show-pid` / `hyperlink`],
  [`url` / `doi` / `cstr` / `isbn` / `issn` / `eprint` / `eprinttype` / `archiveprefix` / `medium`], [对应字段原值，若需在自定义模板里以非默认顺序、标点拼接电子资源信息时使用\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`url`]], [—],
  [`type`], [type 字段原值（与 `mark` 不同：`mark` 是文献类型标识 `[M]/[J]`；`type` 是 .bib 里直接录入的字符串）\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`type` 字段原值]], [—],
  [`keywords`], [keywords 字段原值\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`keywords`]], [—],

  [`degree-annotation`], [学位级别注记，仅文献类型标识为 `D` 时输出\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`type`（`phdthesis` / `mathesis`）或 entry_type（`@phdthesis` / `@mastersthesis`）]], [`show-degree`],
  [`country`], [专利国；`show-patent-country: true` 或 `version: 2005` 时输出\ #text(size: 0.85em, fill: luma(90))[优先读取 `location`，否则读取 `address`]], [`show-patent-country`],
  [`note`], [note 字段原始值\ #text(size: 0.85em, fill: luma(90))[字段取值顺序：`note`]], [—],
)

本包已识别的 `.bib` 字段可直接在模板中使用，例如 `version`、`holder`、`journaltitle`、`school`、`url` 和 `keywords`。只有新增字段或需要为字段配置前后缀时，才使用 `custom-fields`。

== 自定义条目类型的配置步骤 <custom-type-section>

本包保留 `.bib` 中自定义条目类型的原名，如 `@dissertation`、`@mytype`。配置自定义类型时可按以下四步进行：

- *文献类型标识*：使用 #arg-ref("gb7714", "custom-marks")[`custom-marks`] 设置条目类型的默认标识代码，例如 ```typ custom-marks: (dissertation: "D", mytype: "XX")```。条目中的 `usera` 等字段优先于全局设置；未登记的类型使用 `[Z]`。已有类型名可用于覆盖内置标识。值也可使用条件表达式；例如，```typ custom-marks: (misc: "<url ? doi => EB>< => M>")``` 使包含 `url` 或 `doi` 的 `@misc` 使用 `[EB]`，其他 `@misc` 使用 `[M]`。
- *格式*：已知文献类型标识可采用相应的内置格式，例如 `D` 使用学位论文格式；也可用 `custom-drivers: (mytype: "..模板..")` 指定完整格式。
- *显示控制*：`show-mark`、`show-url` 和 `show-pid` 可按小写条目类型设置；登记后的大写文献类型标识代码也可作为键。
- *排序 / 引用*：与内置类型无差别，无需额外配置。

== 自定义标识、术语、字段和永久标识符 <custom-config-section>

`custom-marks` 用于设置文献类型标识。向模板添加内容时使用下列三个参数：

#table(
  columns: (auto, 1fr, 1fr),
  align: (left, left, left),
  table.header(repeat: true, [参数], [作用], [值形式]),
  [`custom-terms`], [按语言选择的固定文字], [字符串或 `(zh:.., en:..)`],
  [`custom-fields`], [在模板中使用自定义字段], [`auto` 或 `(field:.., prefix:.., suffix:..)`],
  [`custom-pids`], [永久标识符（著录于条目末尾）], [`(field:.., prefix:.., resolver:..)`],
)

三者的键均不得与内置 token 同名；完整 token 表见@template-built-in-tokens。`custom-terms` 和 `custom-pids` 还可使用各自允许覆盖的名称，其中内置术语的覆盖规则见@builtin-terms。

=== `custom-terms`：按语言设置文字

值可以是字符串（不区分语言）或多语言字典 `(zh:.., en:..)`。使用多语言字典时，先按条目语言取值；没有对应语言时，采用字典中的第一个值。模板中使用键名引用：

```typ
#let in-proc = (zh: "见", en: "In:", ja: "を見よ")

#show: gb7714(
  custom-drivers: (
    inproceedings: "author . component-part-title-block . in-proc booktitle . imprint-block",
  ),
  custom-terms: ("in-proc": in-proc),
)
#bibliography(read("refs.bib"))
```

如果键为 `et-al`、`editor`、`translator`、`anon`、`no-date`、`sine-loco`、`sine-nomine`、`sine-anno`、`ma-thesis`、`phd-thesis`、`edition`、`volume`、`ibid` 或 `footnote-number`，则覆盖*内置术语*，而不是注册新术语，详见@builtin-terms。

=== `custom-fields`：使用自定义字段

- `auto`：模板标识符与字段同名。例如，`(myarxiv: auto)` 使模板中的 `myarxiv` 输出同名字段的值。
- 字典 `(field: "xxx", prefix:.., suffix:..)`：读取 `xxx` 字段，并添加前缀、后缀。两者可使用字符串或多语言字典，后者按条目语言选择。字段缺失时，不输出该字段及其前后缀。

```typ
#show: gb7714(
  custom-drivers: (
    book: "author . title-block . imprint-block ?<(myarxiv)> ?<(curnote)>",
  ),
  custom-fields: (
    myarxiv: auto,                                  // 原样传递 myarxiv 字段原值
    curnote: (field: "curnote", prefix: (zh: "附注：", en: "Note: ")),
  ),
)
#bibliography(read("refs.bib"))
```

字段值与其他显示字段一样由 #LaTeX 转换为 Typst 内容。`field` 不能与本包已有字段名冲突，建议使用项目专属前缀，如 `mylab-` 或 `appx-`。

==== 读取已有 `howpublished` 字段 <custom-howpublished>

内置出版项尚不使用 `howpublished`，也不会把其文本自动拆成出版地和出版者。可将它注册为模板字段：

#demo("旧文献库的 howpublished 原样著录")[```typ
#show: gb7714(
  custom-fields: (how: (field: "howpublished")),
  custom-drivers: (misc: "<creator>. <title-block>. <how>, <year>"),
)
#bibliography(bytes("@misc{old-publication, author={万锦}, title={中国大学学报论文文摘}, howpublished={北京: 中国大百科全书出版社}, year={1996}}"), full: true)
```]

此例完整替换 `misc` 的格式，只适用于相应旧数据。普通数据优先使用独立的 `location`、`publisher` 字段；不能把 `howpublished` 中的“在线发布”“私人印行”等任意说明都当成结构化出版项。

=== `custom-pids`：自定义永久标识符

值为字典 `(field: "xxx", prefix: "标签", resolver: "https://.../{}")`。自定义永久标识符与 DOI、CSTR 一起著录于条目末尾的获取和访问路径中；模板通过内置 `access` 统一输出，不能单独引用其名称。

- `field` 指定数据字段，新增标识符时必须设置。
- `prefix` 指定标签；省略时使用大写的字段名。输出为“标签:值”，字段值中已有的同名标签不会重复添加。
- 字段值为 URL（`http`、`https` 或 `ftp`）时，链接指向该地址；否则使用 `resolver` 生成地址。`resolver` 中的 `{}` 替换为字段值；没有 `{}` 时，字段值添加在地址末尾。

```typ
#show: gb7714(
  custom-pids: (
    handle: (field: "handle", prefix: "HDL", resolver: "https://hdl.handle.net/"),
  ),
)
#bibliography(read("refs.bib"))
```

==== URN

GB/T 7714—2025 §3.10 的注中明确列出 DOI 和 URN。URN 没有统一的解析地址（`urn:isbn:`、`urn:issn:`、`urn:nbn:` 使用不同服务），因此通过 `custom-pids` 配置：

```typ
custom-pids: (urn: (field: "urn", prefix: "URN", resolver: "https://urn.fi/{}")),
```

`.bib` 中可填写完整值：```bib urn = {URN:ISBN:978-951-51-2090-8}```，输出仍为 `URN:ISBN:978-951-51-2090-8`。若 URL 已包含该标识符，#arg-ref("gb7714", "dedup-url-pid")[`dedup-url-pid`] 可避免重复著录。

ISBN 与采用 ISBN 命名空间的 URN 应分别填写：前者写入 `isbn`，后者写入此处定义的 `urn`。本包将单独著录 ISBN 作为扩展功能，默认不显示。

==== 预印本平台：`eprint` 的解析表

`eprint` 的标签取自 `archiveprefix` 或 `eprinttype`，如 `arXiv:2301.00001`、`bioRxiv:…`、`SSRN:…`。是否生成链接和获取路径取决于平台是否有已知的解析地址。内置平台如下：

#table(columns: 2,
  table.header(repeat: true, [平台], [`.bib` 里 `eprint` 的写法]),
  [arXiv], [`2301.00001`],
  [ChinaXiv], [`202301.00002`],
  [bioRxiv], [`10.1101/2023.01.15.523456v1`（DOI 形式，带版本号）],
  [Research Square], [`rs-2513222/v1`],
  [OSF（含 PsyArXiv / SocArXiv）], [`psyarxiv/n8dcy`],
)

未列入上表的平台仍会输出编号，但默认不生成链接，如 `SSRN:4321098` 和 `PMID:36123456`。可在 `eprint` 的 `resolver` 字典中补充对应的解析地址：

```typ
custom-pids: (eprint: (resolver: (
  medrxiv: "https://www.medrxiv.org/content/{}",
  ssrn:    "https://papers.ssrn.com/sol3/papers.cfm?abstract_id={}",
))),
```

键为 `archiveprefix` 的值，匹配时忽略大小写、空格和连字符（`Research Square`、`research-square` 和 `ResearchSquare` 均匹配同一项）。如果 `resolver` 为字符串，则该模板适用于所有平台；此兼容写法仍然可用。

如果键为 `doi`、`cstr`、`isbn`、`issn` 或 `eprint`，则覆盖相应的内置 PID。显示方式由 #arg-ref("gb7714", "show-pid")[`show-pid`]、#arg-ref("gb7714", "pid-priority")[`pid-priority`] 和 #arg-ref("gb7714", "dedup-url-pid")[`dedup-url-pid`] 控制。

=== 为单个文献表设置术语

```typ
#bibliography(read("refs.bib"),
  custom-terms: ("in-proc": (zh: "据", en: "Per:")),  // 仅本次列表
)
```

`bibliography` 和 `cite(note: "foot")` 均接受 `custom-terms`、`custom-fields`、`custom-pids` 和 `custom-drivers`。默认值 `auto` 表示沿用全局设置；传入字典时，仅对本次调用生效。

== 修改内置术语 <builtin-terms>

#arg-ref("gb7714", "custom-terms")[`custom-terms`] 有两种用途：在 @custom-config-section 中注册新 token，或用下表所列名称覆盖内置本地化术语，包括截断词、编者或译者标签、佚名、出版项缺失项和学位注记。

如需将英文“et al.”改为“et al”，或将中文“主编”改为“编”，可按下表设置对应术语。

=== 可覆盖的键

可覆盖的内置术语列于下表，请使用表中的名称。

著录所用术语始终采用条目的语言。正文标注和脚注标注默认也采用条目的语言，可通过 #arg-ref("gb7714", "cite-terms-lang")[`cite-terms-lang`] 修改。`cite-terms-lang` 选择语言，`custom-terms` 定义该语言下的术语，二者相互独立。Typst 目前不能为错误的键名发出警告；例如，`et-la` 会被视为未使用的新 token。请按照下表核对键名。

术语值有两种形式：普通文字使用字符串；需要插入版次、卷号或注号的文字使用前缀和后缀。后者的写法见本节示例。

#table(
  columns: (auto, auto, 1fr, 1fr),
  align: (left, left, left, left),
  table.header(repeat: true, [键], [形式], [含义], [内置默认（中 / 英）]),

  [`et-al`], [字符串], [责任者截断词], [等 / et al.],
  [`editor`], [字符串], [编者角色标签], [主编 / ed.],
  [`translator`], [字符串], [译者角色标签], [译 / trans.],
  [`anon`], [字符串], [无责任者占位（同 #arg-ref("gb7714", "show-anon")[`show-anon`]）], [佚名 / Anon],
  [`no-date`], [字符串], [无出版日期占位·*标签位*（著者-出版年制的「著者，年」，同 #arg-ref("gb7714", "show-no-date")[`show-no-date`]）], [无日期 / n.d.],
  [`sine-loco`], [字符串], [出版地不详占位（同 #arg-ref("gb7714", "show-sine-loco")[`show-sine-loco`]）], [出版地不详 / S.l.],
  [`sine-nomine`], [字符串], [出版者不详占位（同 #arg-ref("gb7714", "show-sine-nomine")[`show-sine-nomine`]）], [出版者不详 / s.n.],
  [`sine-anno`], [字符串], [无出版日期占位·*著录位*（出版项里的出版年位，同 #arg-ref("gb7714", "show-sine-anno")[`show-sine-anno`]）], [出版年不详 / s.a.],
  [`ma-thesis`], [字符串], [硕士学位注记], [硕士学位论文 / MA thesis],
  [`phd-thesis`], [字符串], [博士学位注记], [博士学位论文 / PhD thesis],
  [`ibid`], [字符串], [重复脚注「同上」], [同上 / Ibid.],
  [`edition`], [前后缀], [版次前后的文字], [`{}版` / `{}th ed`（西文缩写点随版本：2025 无、2015／2005 作 `{}th ed.`）],
  [`volume`], [前后缀], [卷号前后的文字], [`第{}卷` / `vol. {}`],
  [`pages`], [前后缀], [页码标签词（`p.`、`pp.` 等）], [*各语言均为空字符串*；GB 页码前不显示标签词，此键仅用于覆盖默认值],
  [`footnote-number`], [前后缀], [重复脚注“同③”：包住首注号，语言由 `cite-terms-lang` 控制], [`同{}` / `See note {}`],
)

=== 单复数：`p.` / `pp.`、`vol.` / `vols.`、`ed.` / `eds.`

需要按数量使用单数或复数形式时，在语言项内设置 ```typc (singular: .., plural: ..)```。这一写法适用于普通术语和带前后缀的术语：

```typ
custom-terms: (
  editor: (en: (singular: "ed.", plural: "eds.")),                          // 使用字符串
  volume: (en: (singular: (prefix: "vol. "), plural: (prefix: "vols. "))),  // 使用前缀
  pages:  (en: (singular: (prefix: "p. "),   plural: (prefix: "pp. "))),
)
```

复数形式由数据决定：页码根据区间和段数判断，卷次根据是否为多卷判断，编者则根据人数判断。例如，`12-18` 和 `42, 45` 使用 `pp.`，`e12345` 使用 `p.`。只设置单数或复数形式时，另一种情况沿用已设置的值。

单复数对也可以*不分语言*直接写在最外层（```typc (editor: (singular: "ed.", plural: "eds."))```，全语言通用）。

#demo("按页码数量切换 p. / pp.")[```typ
#show: gb7714(full: true, custom-terms: (
  pages: (en: (singular: (prefix: "p. "), plural: (prefix: "pp. ")))))
#bibliography(bytes("@article{plu-a, author={Doe, Jane}, title={Alpha}, journal={J}, year={2020}, volume={5}, pages={12--18}, langid={english}}
@article{plu-b, author={Roe, Rick}, title={Beta}, journal={J}, year={2021}, volume={6}, pages={42}, langid={english}}"))
```]

`pages` 用于设置页码标签词。GB 页码前不显示此类标签（`2020：12-25` 中的冒号是结构标点），因此各语言的默认值均为空字符串；未配置时不改变输出。正文引用页码（`@key[42]`）和注释制中的引文页码均不带标签词。

表中的 `{}` 表示数字的位置。实际值使用前后缀字典，如 ```typc (zh: (prefix: "第", suffix: "卷"))```。`ibid` 和 `footnote-number` 还接受 `supplement-separator`，用于设置引语与引文页码之间的分隔符。`ibid` 可写为 ```typc (text: "同前", supplement-separator: ",")```；`footnote-number` 可在前后缀字典中加入同名键。只设置 `supplement-separator` 时，其他默认值保持不变。单个标点字符会按照当前全角或半角样式调整，其他字符串按原样输出。

#callout(kind: "note", title: "重复脚注的文字与编号")[
  `custom-terms` 的 `footnote-number` 仅控制重复脚注中“同③”等文字的前后缀。脚注编号的字形由 `note-numbering-style` 或文档的 `footnote(numbering:)` 设置控制。
]

普通术语可写成字符串，也可按语言分别设置；未列出的语言使用内置值。带数值的术语使用前缀、后缀形式：

```typ
#show: gb7714(
  custom-terms: (
    "et-al":      (en: "et al"),      // 英文截断词去掉缩写点（内置键）
    editor:       (zh: "编"),          // 将中文编者标签“主编”改为“编”
    "phd-thesis": (zh: "博士论文"),     // 学位注记词（内置键）
    volume:       (zh: (prefix: "第", suffix: "册")),   // “第6卷”显示为“第6册”
    "footnote-number": (zh: (prefix: "见注", suffix: "")),  // 重复脚注显示为“见注③”
    see:          (zh: "见", en: "See"),  // 新增术语
  ),
)
#bibliography(read("refs.bib"))
```

覆盖对*参考文献表著录*与*著者-出版年制正文引用*同时生效（如行内「张三 等」的截断词也随之改变）。

=== 设置前缀和后缀

`edition`、`volume`、`pages` 和 `footnote-number` 使用 `prefix`、`suffix` 设置数字前后的文字。这些设置不改变数字本身的格式，如英文版次仍使用 `2nd`、`3rd` 等序数：

```typ
#show: gb7714(
  custom-terms: (
    volume:  (zh: (prefix: "卷", suffix: "")),       // “第6卷”显示为“卷6”
    edition: (en: (prefix: "", suffix: " edition")), // “2nd ed”显示为“2nd edition”
  ),
)
#bibliography(read("refs.bib"))
```

某种语言只设置 `prefix` 或 `suffix` 时，另一项按空字符串处理；未列出的语言使用内置默认值。覆盖时仅替换对应语言的前后缀。

新增术语应避开上表中的名称；例如，`editor` 专用于修改编者标签，不能作为新术语的名称。

== 完整示例 <custom-format-example>

以下示例将专利的国家和编号单独著录为一项，其他文献类型仍使用内置格式。

#demo("将专利的国家和编号单独著录")[```typ
#show: gb7714(
  show-patent-country: true,
  custom-drivers: (
    patent: "author . title ?<country, number> mark-medium . ?<date> ?<urldate> ?<access>",
  ),
)
@carr1992
#bibliography(bytes("@patent{carr1992, author={Carr, Robert D. and Kingdom, Fred R. T. and Quasius, James H.}, title={Bobbin closure for ring spinning frame}, number={5099641}, address={US}, date={1992-03-31}, langid={english}}"))
```]

= #LaTeX 命令支持 <latex-section>

omni-gb7714 会把 `.bib` 字段中的 #LaTeX 文本转换为 Typst 内容。常用命令可直接写在多种字段中，字段语义与 #BibLaTeX 保持一致。

== 支持的命令

#table(
  columns: (1fr, 1fr),
  table.header(repeat: true, [写法], [渲染为]),
  [`\quad`], [1em 空格（U+2003）],
  [`\qquad`], [2em 空格（U+2003 ×2）],
  [`\,`], [thin space（U+2009，1/6 em）],
  [`\;`], [四分之一 em 空格（U+2005）],
  [`~`], [non-breaking space（U+00A0）],
  [`\textbf{...}` / `\textbf x`], [*粗体*（紧贴括号、单 token 实参、`\textbf {x}` 空格皆可）],
  [`\textit{...}` / `\emph{...}`], [*斜体*],
  [`\textsc{...}` / `{\sc ...}`], [small caps],
  [`\textsuperscript{}` / `\textsubscript{}`], [上标 / 下标],
  [`{\bfseries ...}` / `{\bf ...}`], [粗体（旧式 group，作用域已正确限定在组内）],
  [`{\itshape ...}` / `{\it ...}` / `{\em ...}`], [斜体（旧式 group）],
  [字号 `\large` `\small` `\tiny` `\footnotesize` `\huge` 等], [识别后忽略字号声明，使用当前 Typst 字号],
  [等宽 `\texttt{}` / `\ttfamily` / `\tt` / `{\tt ...}`], [等宽字体（使用 Typst 行内 `raw`，继承全局 `#show raw:` 字体设置）],
  [sans `\textsf{}` / `\sffamily` / `\sf`], [保留内容，忽略无衬线字体切换；这是本包的转换范围],
  [`\underline{...}`], [下划线],
  [`\dag` `\ddag` `\P` `\S` `\copyright` `\pounds`], [† ‡ ¶ § © £（符号命令，吞尾随空白）],
  [`\texttrademark` `\textregistered` `\textbullet`], [™ ® •（及 `\textendash` – / `\textemdash` —）],
  [`\textdegree` `\textmu` `\texttimes` `\textpm`], [° µ × ±（及 `\textonehalf` ½ / `\textnumero` № / `\textcelsius` ℃ 等科技符号）],
  [`\textunderscore` / `\textdollar`], [字面 `_` / `$`（文本写法；未转义的 `_` 在严格模式下报错，未配对的 `$` 在任何模式下都报错）],
  [`\textperthousand` `\textlnot` `\textbardbl` `\textlangle` `\textrangle` `\textreferencemark` `\textleftarrow` 等], [‰ ¬ ‖ ⟨ ⟩ ※ ← 等（textcomp 符号，码位经真 textcomp 实测对齐）],
  [`\mkbibbold{}` `\mkbibemph{}` `\mkbibsuperscript{}`], [粗体 / 斜体 / 上标（#BibLaTeX 富文本宏）],
  [`\adddot` `\addcomma` `\addcolon` `\addsemicolon` `\addperiod` `\addspace` `\adddotspace` `\addslash` `\isdot` 等], [. , : ; . ␠ . ␠ / 与空串（#BibLaTeX 标点宏按字面展开；`\isdot` 等命令不输出内容。启用 `correct-punct` 后，宏生成的标点与字段中的标点按同一规则转换：中文条目中的 `\addcomma` 显示为“，”，`{}` 的保护作用不变。本包不实现 #BibLaTeX 的标点跟踪；例如 `Rev.\addperiod` 显示为 `Rev..`，而 #BibLaTeX 会避免重复句点）],
  [`\enspace` `\enskip` `\nobreakspace` `\newline`], [en 空格 / nbsp / 换行],
  [`\ldots` / `\dots`], […（尾随空白被忽略，`\ldots z` 输出 `…z`）],
  [`\MakeUppercase{}` / `\uppercase{}`（及 `\MakeLowercase` / `\lowercase`）], [大写 / 小写变换],
  [`\mkbibquote{...}` / `\url{...}`], [加弯引号 / 取URL 文本],
  [`\mbox{...}` / `\text{...}` 等盒子类], [原样传递内容（去包裹）],
  [`\hspace{1em}`], [对应长度的水平空白（支持 em / pt / cm / mm / in）],
  [`\textbraceleft` `\textbraceright`（或 `$\lbrace$` `$\rbrace$`）], [字面 `{` `}`（可靠写法；未转义的 `{` `}` 是分组符，`\{` `\}` 仅在配对时可靠，详见@latex-args-section）],
  [`$...$`], [数学公式（经 mitex 转换）],
)

上表只列常用项。本包还支持 `\textsl` / `\textup` / `\textnormal` 等字体声明，`\textless` `\textgreater` `\textbar` `\textquotedbl` 等文本符号，`\mkbibitalic` / `\bibellipsis` / `\hyphen` 等 #BibLaTeX 宏，以及 `\bigskip` / `\medskip` / `\smallskip` 等垂直间距命令（在行内不产生内容）。完整清单见 `src/parse/latex.typ` 中的 `_TEX-FONT-ARG`、`_TEX-DECL` 和 `_TEX-SYM` 等表。重音（`\'e`）和特殊字母（`\oe`、`\ss`）由 citegeist 解析；本包在解析前后处理 `\&`、`\%` 等转义字符。

上表所列命令在严格模式下也可使用，但本包并不实现全部 #LaTeX 命令。未收录命令无论是否为合法宏，都按 `latex-strict-command` 处理；缺少常用命令时可在 GitHub issue 提供示例。

=== HTML 富文本标记（Zotero 导出）

Zotero 等工具导出的 `.bib` 有时会保留 citeproc 使用的一部分 HTML 富文本标记。本包先将其转换为相应的 #LaTeX 命令：

#table(
  columns: (auto, auto, 1fr),
  table.header(repeat: true, [HTML 标记], [效果], [转换为]),
  [`<i>…</i>`], [斜体], [`\textit{…}`],
  [`<b>…</b>`], [粗体], [`\textbf{…}`],
  [`<sup>…</sup>`], [上标], [`\textsuperscript{…}`],
  [`<sub>…</sub>`], [下标], [`\textsubscript{…}`],
  [`<sc>…</sc>`], [小型大写], [`\textsc{…}`],
  [`<span class="nocase">…</span>`], [大小写保护], [`{…}`（花括号组）],
)

标签名不区分大小写。`nocase` 会转换为花括号组，其中的内容不参与 #arg-ref("gb7714", "titles-text-case")[`titles-text-case`] 的大小写转换。例如，`study of <span class="nocase">DNA</span> and rna` 使用 title case 后得到 `Study of DNA and Rna`。

Zotero 内置 #BibTeX 导出器可能把 `<`、`>` 写成 `\textless`、`\textgreater`。本包会先还原这些字符，再处理富文本标记，无需修改 `.bib`。

== 哪些字段允许 #LaTeX 命令

字段分类遵循 #BibLaTeX 数据模型（`blx-dm.def` 和 #BibLaTeX\-gb7714 的 `\DeclareDatamodelFields`）：标为 `verbatim` 或 `uri` 的字段不展开控制序列，其余 `literal` 和 `list` 字段按 #LaTeX 文本解析。

#table(
  columns: (auto, 1fr),
  table.header(repeat: true, [类别], [字段（节选）]),
  [*literal / 长文本*], [`title` / `subtitle` / `titleaddon` / `booktitle` / `booksubtitle` / `booktitleaddon` / `journal` / `journaltitle` / `journalsubtitle` / `journaltitleaddon` / `shortjournal` / `series` / `note` / `keywords` / `type` / `medium` / `scale` / `dimensions`],
  [*list（列表）*], [`publisher` / `location` / `address` / `school` / `organization` / `institution` / `holder`（人名列表）],
  [*literal 但短*], [`edition` / `version` / `volume` / `number` / `pages` / `isbn` / `issn` / `eprinttype` / `archiveprefix`],
  [*verbatim / uri（原样不展开控制序列）*], [`url` / `doi` / `eprint`（#BibLaTeX `verbatim` / `uri`）和 `cstr`（DOI 式永久标识，原样）],
  [*date / numeric*], [`year` / `month` / `day` / `date` / `urldate`],
)

在 #BibLaTeX 数据模型中标为 *verbatim* 或 *uri* 的 `url`、`doi`、`eprint`，以及 DOI 式标识 `cstr`，均保留原样，不作 #LaTeX 转换，以免误解 URL 或 DOI 中的 `\`、`_`、`~`。\
`isbn`、`issn`、`eprinttype` 和 `archiveprefix` 按 literal 字段展开命令；未转义的 `&` 或 `_` 在严格模式下会报错。日期优先按 EDTF 解析：`2024~` 表示约数，`2024?` 表示不确定，`2024%` 兼有两者，输出均加方括号；`1957/1990` 表示闭区间，`1957/..` 表示开放区间。区间和公元前年份应写入 `date`；`year` 的回退只处理末尾 `~`、`?`、`%` 等已有标记。

完整日期区间当前使用 `—` 连接，尚无 `date-range-separator` 参数，`page-range-separator` 只影响页码。`urldate` 当前取区间的起点（只有终点时取终点），不应把这一行为理解为完整引用日期区间输出。`date` 无法结构化时会尝试字面回退；这和结构化日期的格式化路径不同。

== 命令终止规则与实参形式 <latex-args-section>

本包使用 #TeX 词法规则解析命令，并按 #BibLaTeX\-gb7714（biber、Xe#LaTeX 和 ctex）的实际结果校验。主要规则如下：

- *字母命令*（`\quad` / `\textbf` 等）在第一个非字母字符处结束；命令名后的空白被忽略，例如 `\LaTeX  end` 输出 `LaTeXend`；
- *单 token 实参*：接收一个参数的字体命令无需花括号，也可作用于紧随的单个字符；`\textbf x` 等价于 `\textbf{x}`。命令与花括号之间可以有空格，如 `\textbf {x}`；
- *声明式命令*：`{\itshape ...}` / `{\bfseries ...}`（旧式分组）以及未带参数的 `\bfseries ...` 都作用到当前组的末尾，不会影响组外内容；
- *符号命令*（`\dag`、`\ldots` 等）也会忽略尾随空白；`\ldots z` 输出 `…z`。
- *花括号*：未转义的 `{` `}` 是 #LaTeX 分组符，渲染时不显示；例如，`\sc{English}` 输出小型大写的 “English”，`{abc}` 输出 “abc”。要输出字面花括号，宜使用 `\textbraceleft` / `\textbraceright`（文本）或 `$\lbrace$` / `$\rbrace$`（数学）。配对的 `\{` / `\}` 也受支持（`\{x\}` → `{x}`），但未配对时会破坏 biber 的花括号计数；严格模式（默认 #arg-ref("gb7714", "latex-strict-char")[`latex-strict-char`]）会报告错误。`latex-strict-char: false` 可容许这种输入。

#table(
  columns: (auto, 1fr),
  table.header(repeat: true, [命令后紧贴何种字符], [行为]),
  [数字 / 标点 / 反斜杠 / 字段末尾（catcode-other）], [正常断开命令],
  [Latin 字母（a-z A-Z）/ CJK（汉字 / 假名 / 谚文）], [并入命令名（Xe#LaTeX + ctex 将 CJK 字符视为字母）；未知命令按 `latex-strict-command` 处理，见@latex-strict-section],
)

`\quad中文` 会被视为一个完整命令名，因此默认报错；设置 `gb7714(latex-strict-command: false)` 后，未知命令会被忽略，详见@latex-strict-section。应使用空格或 `{}` 明确终止命令名。

== 嵌套命令与复合命令

`\textbf{...}` 与 `\quad` 等可任意嵌套混用：

```bib
title  = {Section \textbf{One}\quad{}---\quad Final}
note   = {Pages 1--3 in $\textbf{Vol.}\, 1$}
```

== 严格模式与宽松模式 <latex-strict-section>

`.bib` 字段中 #LaTeX 写法的检查方式由两个相互独立的参数控制：一个处理未定义命令，另一个处理未转义的特殊字符。两项默认均采用严格模式，也可分别改为宽松模式：

#table(columns: (32%, 38%, 30%),
  table.header(repeat: true, [参数], [`true`（默认，严格）], [`false`（宽松）]),
  [#arg-ref("gb7714", "latex-strict-command")[`latex-strict-command`]\ 检查未定义命令，如 `\foobar`、`\textbf中`],
    [报错（相当于 #BibLaTeX 的 `! Undefined control sequence.`）], [忽略命令并继续处理后文],
  [#arg-ref("gb7714", "latex-strict-char")[`latex-strict-char`]\ 检查未转义的 `&` `_` `#` `%` `^` 及未配对的 `\{`、`\}`],
    [报错（须写 `\&` `\_` … / 花括号未配对须改用 `\textbraceleft` `\textbraceright`）], [按字面输出 / 容忍未配对],
)

两项互不影响。例如，```typ gb7714(latex-strict-command: true, latex-strict-char: false)``` 仍会报告拼错的命令，但允许未转义的 `&` / `_`。反向组合也同样有效。

- *严格模式*可及早发现命令拼写错误和遗漏转义；未转义的 `&` / `_` 会报错，须改为 `\&` / `\_`；
- *宽松模式*：`latex-strict-command: false` 忽略未定义命令，`latex-strict-char: false` 原样输出未转义的特殊字符。该模式可用于暂时处理尚未清理的旧文献库。
- 两个参数均不影响已经转义的 `\&`、`\_` 等字符、数学公式 `$x_i$`，以及不进行 #LaTeX 转换的 `url`、`doi` 和 `eprint` 字段。

=== #LaTeX 特殊字符完整对照

#LaTeX 文本模式中需要转义的特殊字符如下。本包的处理结果已与 #BibLaTeX 和 Xe#LaTeX 核对：

#table(columns: (auto, 1fr, 38%),
  table.header(repeat: true, [字符], [字面写法], [本包如何处理]),
  [`&` `%` `#` `_` `^`], [`\&` `\%` `\#` `\_`；`^` 写作 `\textasciicircum`], [由 `latex-strict-char` 控制：严格模式报错，宽松模式保留原样],
  [`$`], [`\$`], [`$...$` 当数学公式；未配对 `$` 恒报错（≈ `! Missing $ inserted.`，不受 `latex-strict-char` 影响，无法渲染）],
  [`\`], [`\textbackslash`], [反斜杠后接字母时按命令解析；未定义命令由 `latex-strict-command` 决定是否报错],
  [`{` `}`], [`\textbraceleft` `\textbraceright` 或 `$\lbrace$` `$\rbrace$`（`\{` `\}` 仅在配对时可靠）], [未转义的 `{ }` 是不显示的分组符；输出字面括号时宜使用前两种写法，未配对的 `\{` / `\}` 会使 #BibLaTeX 报错],
)

下列字符无需转义，本包按原样输出：`@`、`~`（不换行空格）、`<`、`>`、`|`、`+`、`=` 等。例如 ```bib title = {mail@host a<b}``` 显示为 `mail@host a<b`，不必写 `\@`。`@` 只在 `.bib` 顶层表示条目起始符，在字段值中是普通字符。

本包不实现 `\href{url}{text}` 等命令：严格模式报错，宽松模式忽略命令并保留花括号中的内容。链接应填写在 `url` 或 `doi` 字段中，也可用 `custom-fields (field: ..)` 原样传递。自定义宏（如 `\mymacro`）应在写入 `.bib` 前展开。缺少常用 #LaTeX 命令时，可在 GitHub issue 中反馈。

= 常见问题

== 为什么没有参数补全？ <completion-section>

先检查是否使用了 `#show: gb7714.with(..)`。`.with` 能正常执行，但编辑器对部分应用函数的参数推断可能有限；直接调用 `gb7714(..)` 更便于读取签名。补全行为还取决于 Web App 或 Tinymist 版本，不能把所有补全故障都归因于这一写法。

推荐直接调用 `gb7714(..)`，让编辑器读取函数参数：

```typ
#show: gb7714(style: "author-date", version: 2025)   // 推荐：命名参数可直接补全
// #show: gb7714.with(style: "author-date")           // 不推荐：Web App 无法补全参数
```

这与输入 `@` 后的文献键补全不同；后者由 `cite-completion` 控制，见 @links-completion-section。

== 编辑器崩溃与编译失败如何区分？

先用同一版本的 `typst compile` 编译最小文档。命令行编译成功、编辑器语言服务退出，是不同于文档编译错误的问题。反馈时附上 Tinymist 版本、日志、操作系统和最小导入文档；仅有“PDF 编译成功”不能排除语言服务分析故障。已有循环分析栈溢出报告见 #link("https://github.com/typst-omni-gb7714/omni-gb7714/issues/25")[issue \#25]，其复现条件与平台、版本有关。

== 为什么长文档编译较慢？

本包会处理引用归属、计数器、状态和查询，实际耗时取决于文档布局与引用方式。已有与其他实现的性能差异报告（#link("https://github.com/typst-omni-gb7714/omni-gb7714/issues/26")[issue \#26]）；不能把某个模板的倍数当成所有文档的固定开销。

定位时分别测量纯正文、仅文献表和含正文引用的版本，并记录字体、包源码、编译器及缓存条件。首次下载依赖的时间应单独记录；修改配置后应同时核对输出，避免把少渲染内容误当成优化。`cite-completion: false` 不是通用性能开关，是否有收益需要实测。

== 文献表置于 grid 或多栏容器后，为何没有占满整行？

本包的 `#bibliography` 沿用 Typst 原生函数 `std.bibliography` 的接口和渲染结构：整张列表是一个 `block`，宽度随容器确定，不强制占满可用宽度。因此，原生函数的相关排版方法也适用于本包。

文献表位于 `grid` 或多栏容器中时，默认宽度可能按内容收缩，因而没有占满可用空间。

将该 `block` 设置为 `width: 100%` 即可：

```typ
#show std.bibliography: set block(width: 100%)      // Typst 0.15+
// 或全版本通用的作用域写法：
#[ #set block(width: 100%); #bibliography(read("refs.bib")) ]
```

也可设置其他宽度，例如 `set block(width: 80%)` 使文献表占容器宽度的 80%。

= 反馈与致谢

本包和 Typst 都在持续更新。如果手册未能解决问题，请通过邮件或项目的 issue 提供最小示例、Typst 版本和实际输出。

本包主要参考了胡振震的 #BibLaTeX\-gb7714-2015 宏包和李泽平的 #link("https://github.com/zepinglee/gbt7714-bibtex-style")[gbt7714-#BibTeX\-style]。李泽平维护的 GB/T 7714 #link("https://github.com/citation-style-language/styles")[CSL 样式]用于原生 Hayagriva 的性能对照；测试文献来自 #link("https://github.com/typst-doc-cn/bib-csl-dev-data")[Zotero 中文 CSL 开发组数据集]。#link("https://github.com/YDX-2147483647")[YDX-2147483647] 协助核对国标复刻，并提供了 #link("https://github.com/YDX-2147483647/gb7714-bench")[gb7714-bench] 的测试资料。

本包基于 #link("https://github.com/typst/typst")[Typst] 和 #link("https://github.com/typst/biblatex")[typst-biblatex]。`.bib` 解析使用 #link("https://typst.app/universe/package/citegeist")[`citegeist`] 的修改版；拼音排序、语言判别和数学公式分别使用 #link("https://typst.app/universe/package/auto-pinyin")[`auto-pinyin`]、#link("https://typst.app/universe/package/glotter")[`glotter`] 和 #link("https://typst.app/universe/package/mitex")[`mitex`]。

带圈数字、中文笔画排序和 URL 断行分别由 #link("https://typst.app/universe/package/quan")[`quan`]、#link("https://typst.app/universe/package/auto-bihua")[`auto-bihua`] 和 #link("https://typst.app/universe/package/jurlstify")[`jurlstify`] 提供。

感谢这些项目的作者、维护者和本包用户。
