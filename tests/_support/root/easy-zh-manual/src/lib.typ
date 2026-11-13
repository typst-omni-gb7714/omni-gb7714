#import "@preview/quan:0.2.2": quan, quan-footnote

// 输出目标检测：`typst compile --input target=html` 时为 "html"，否则视为 PDF。
#let _target = sys.inputs.at("target", default: "pdf")
#let is-html-target = _target == "html"

// ========================= 主题 =========================

#let theme = (
  accent:       rgb("#6A1B9A"),
  accent-light: rgb("#F4ECFA"),
  code-accent:  rgb("#9A6817"),
  code-bg:      rgb("#FCF8F0"),
  code-stripe:  rgb("#F5ECD9"),
  inline-code-bg: rgb("#ECEFF2"),
  result-accent: rgb("#426B49"),
  result-bg:     rgb("#F3F8F3"),
  result-stripe: rgb("#E9F2EA"),
  table-stripe: rgb("#FAF7FC"),
  // 第四章四步对照组专用色。四种颜色只用于这组卡片，不与代码、输出、表格或 callout 共用。
  format-accent:   rgb("#4E6572"),
  format-bg:       rgb("#F4F7F8"),
  format-stripe:   rgb("#E9EFF2"),
  fields-accent:   rgb("#8A603B"),
  fields-bg:       rgb("#FAF6F1"),
  fields-stripe:   rgb("#F2E8DC"),
  data-accent:     rgb("#7A536B"),
  data-bg:         rgb("#F8F3F6"),
  data-stripe:     rgb("#EFE4EA"),
  standard-accent: rgb("#3E7065"),
  standard-bg:     rgb("#F2F8F6"),
  standard-stripe: rgb("#E4F0EC"),
  note:         rgb("#356F9F"),
  question:     rgb("#555AA5"),
  tip:          rgb("#2B7A78"),
  warning:      rgb("#A64B45"),
  rule:         rgb("#C9BEDB"),
  link:         rgb("#0B4F9E"),
  muted:        rgb("#6B6878"),
)

// 正文之外的辅助内容共用字号；图表题注可在此基础上另行缩小。
#let auxiliary-size = 9pt
// 9 pt 字号配 12 pt 固定行高，斑马纹一行条纹对应一行文字。
#let auxiliary-row-height = 12pt
#let code-label-size = 10.125pt
#let output-label-size = 9.225pt
#let hanging-label-width = 33.75pt
#let hanging-label-dx = -44.25pt
#let nested-hanging-label-dx = -55.5pt

// 斑马纹环境里的行格。条纹是固定节距的平铺图案，文字行必须同样固定节距才能对上：
// 行距为零，行盒上下缘写死，使每行恰好一个 auxiliary-row-height，与字体度量、中西文混排无关。
// 9 pt 字号下行盒上缘 9.25 pt、下缘 -2.75 pt，字形大致居中在条纹里。
#let _row-top = 9.25pt
#let _row-bottom = _row-top - auxiliary-row-height
// 正文用 em 表示：上标缩小字号又抬高基线，按 em 算的上缘随之缩小，抬高后仍不超出行盒。
#let _row-top-edge = _row-top / auxiliary-size * 1em
#let _row-bottom-edge = _row-bottom / auxiliary-size * 1em

// 斑马纹环境的正文排版：配合 zebra-fill 使用，外层 block 的上下内边距须为零，
// 条纹从 block 顶端开始，与第一行重合。段间、块间都不留空，否则后续各行整体错位。
#let zebra-rows(body) = {
  set text(size: auxiliary-size, top-edge: _row-top-edge, bottom-edge: _row-bottom-edge)
  set par(first-line-indent: 0em, leading: 0pt, spacing: 0pt)
  set block(spacing: 0pt)
  // raw 默认缩到 0.8em，按 em 算行盒会变矮；代码改用绝对长度，整行仍是一个行高。
  show raw: set text(top-edge: _row-top, bottom-edge: _row-bottom)
  body
}

// 是否位于 zebra-rows 之内。上缘取值只有 zebra-rows 会设，据此判断，需在 context 中调用。
#let in-zebra-rows() = text.top-edge == _row-top-edge

// 非正文环境使用固定节距的横向斑马纹；每两行重复一次。
#let zebra-fill(light, dark, row-height: auxiliary-row-height) = tiling(
  // 横向尺寸大于版心，避免窄图块重复采样产生竖向接缝。
  size: (1000pt, row-height * 2),
  relative: "self",
)[
  #grid(
    columns: (1fr,),
    rows: (row-height, row-height),
    grid.cell(fill: light)[],
    grid.cell(fill: dark)[],
  )
]

// 表格、示例代码和示例输出共用的圆角。
#let panel-radius = 3pt

// 两列目录。一级标题显示页码，二级标题仅作链接；这样既保留检索信息，也避免大量页码形成
// 多轮布局依赖。
#let _chapter-toc() = context {
  let headings = query(heading).filter(h => h.level <= 2 and h.numbering != none)
  let midpoint = calc.ceil(headings.len() / 2)
  let entry(h) = {
    let number = numbering(h.numbering, ..counter(heading).at(h.location()))
    let page-number = if h.level == 1 { str(counter(page).at(h.location()).first()) } else { "" }
    link(h.location(), grid(
      columns: (2.7em, 1fr, 1.8em),
      column-gutter: 0.45em,
      align: (left, left, right),
      text(size: if h.level == 1 { 10.5pt } else { 8.8pt }, fill: theme.muted, number),
      text(size: if h.level == 1 { 10.5pt } else { 8.8pt }, weight: if h.level == 1 { "bold" } else { "regular" }, h.body),
      text(fill: theme.muted, str(page-number)),
    ))
  }
  let column(items) = items.map(entry).join(v(0.18em))
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.5em,
    align: top,
    column(headings.slice(0, midpoint)),
    column(headings.slice(midpoint)),
  )
}

// callout 内的代码、输出等环境把悬挂标签收进框内，避免压住左侧色条。
#let _callout-flag(body) = { set text(features: (COUT: 1)); body }
#let in-callout() = text.features.at("COUT", default: 0) != 0

// ========================= 内联组件 =========================

#let arg(name) = text(fill: theme.accent, weight: "bold", raw(name))

// 跳回某函数的具体参数；label 由 option(fn-name:) 在 API 参考区生成。
// 不带 body：显示"用法同 `fn` 的 `name`"。
// 带 body（如 `#arg-ref("gb7714", "show-url")[详见 URL 章节]`）：显示自定义内容。
// 整段渲染为超链接色调，提示可跳转。
#let arg-ref(fn, name, ..rest) = {
  let body = rest.pos().at(0, default: none)
  link(
    label(fn + "." + name),
    text(fill: theme.link, if body == none { [用法同 #raw(fn) 的 #raw(name)] } else { body }),
  )
}

#let url(addr, display: none) = link(
  addr,
  text(fill: theme.link, underline(if display != none { display } else { addr })),
)

#let kbd(key) = box(
  inset: (x: 4pt),
  outset: (y: 2pt),
  radius: 2pt,
  fill: luma(240),
  stroke: 0.5pt + luma(180),
  text(size: 0.9em, font: ("LXGW WenKai Mono"), raw(key)),
)

// ========================= 选项定义块 =========================
//
// 手册风格：
//   <紫色 name> = <值列表，default 值加粗>.   <右对齐 default is X>
//   <缩进描述段>

// API 名悬挂到左页边距，脱离正文流。
#let option-name-width = 3cm
#let option-name-gutter = 0.5em

#let option(
  name,
  values: (),
  default: none,
  type: none,
  fn-name: none,
  body,
) = {
  // HTML 输出：语义化 <section class="option"> + 内嵌 <dl>，
  // 名字（dt.option-name）由桌面 CSS 浮到左侧悬挂样式。PDF 仍走 place(top+left) 进左页边距。
  if is-html-target {
    return [
      // arg-ref 跳转用的 label（与 PDF 路径同名）
      #if fn-name != none [#metadata(fn-name + "." + name)#label(fn-name + "." + name)]
      // data-name 给 site.js 的"按字母排序"切换用——按 name 重排 DOM 时直接读取
      #html.elem("section", attrs: (class: "option", "data-name": name))[
        #html.elem("div", attrs: (class: "option-head"))[
          #html.elem("span", attrs: (class: "option-name"))[#raw(name)]
          #html.elem("span", attrs: (class: "option-sig"))[
            \= #if values.len() > 0 [
              #{
                let _default-str = if std.type(default) == str { default } else { none }
                values.map(v => if str(v) == _default-str {
                  html.elem("strong")[#raw(str(v))]
                } else { raw(str(v)) }).join(", ")
              }.
            ] else if type != none [
              #html.elem("em")[#raw(type)]
            ]
            #if default != none [
              #h(0.5em)#html.elem("span", attrs: (class: "option-default"))[default: #if std.type(default) == str { default } else { default }]
            ]
          ]
        ]
        #html.elem("div", attrs: (class: "option-body"))[#body]
      ]
    ]
  }
  block(breakable: true, above: 1em, below: 0.7em)[
  // 参数名和签名行必须同页，避免悬挂名与说明错位。
  #if fn-name != none [#metadata(fn-name + "." + name)#label(fn-name + "." + name)]
  #block(sticky: true, breakable: false)[
    #place(top + left, dx: -option-name-width - option-name-gutter, dy: 0pt)[
      #box(width: option-name-width)[
        #align(right, text(
          font: "Libertinus Serif",
          fill: theme.accent,
          weight: "bold",
          // 零宽空格只提供断行位置，不改变参数名的显示和复制结果。
          name.replace("-", "-\u{200b}"),
        ))
      ]
    ]
    #grid(
      columns: (1fr, auto),
      column-gutter: 1em,
      align: (left + top, right + top),
      {
        let _default-str = if std.type(default) == str { default } else { none }
        "= "
        h(0.25em)
        if values.len() > 0 {
          values
            .map(v => if str(v) == _default-str {
              text(font: "Libertinus Serif", weight: "bold", style: "italic", str(v))
            } else {
              text(font: "Libertinus Serif", style: "italic", str(v))
            })
            .join(", ")
          [.]
        } else if type != none {
          text(font: "Libertinus Serif", style: "italic", fill: theme.muted, type)
        }
      },
      if default != none {
        text(font: "Libertinus Serif", style: "italic", size: 0.9em, fill: theme.muted)[
          default: #if std.type(default) == str { raw(default) } else { default }
        ]
      } else { [] },
    )
    // 悬挂名超过一行时，为续行留出高度，避免压到说明正文。
    #if name.len() > 15 [#v((calc.ceil(name.len() / 15) - 1) * 0.9em)]
    #v(0.2em)
  ]
  #block({
    set par(first-line-indent: 0em)
    body
  })
  ]
}

// ========================= 示例代码块 =========================
//
// 上下两条横线，居中标题 "例 N. 标题"，中间是带斑马纹的代码。

#let example(title, body) = figure(
  kind: "ezm-example",
  supplement: [例],
  caption: title,
  align(left, body),
)

// ========================= 提示/FAQ 框 =========================

#let callout(
  title: none,
  kind: "note",
  body,
) = {
  if is-html-target {
    // HTML：用 <aside class="callout callout-<kind>">，标题用 <strong>，样式由 CSS 控制
    return html.elem("aside", attrs: (class: "callout callout-" + kind))[
      #if title != none [#html.elem("strong", attrs: (class: "callout-title"))[#title]]
      #body
    ]
  }
  let colors = (
    note:     theme.note,
    question: theme.question,
    tip:      theme.tip,
    warning:  theme.warning,
  )
  let c = colors.at(kind, default: theme.note)
  let fill-c = c.lighten(91%)
  block(
    width: 100%,
    stroke: (left: 3pt + c),
    inset: 0pt,
    above: 1em,
    below: 1em,
    radius: panel-radius,
    // 悬挂标志位于提示框外，不能裁切子内容。
    clip: false,
  )[
    #if title != none [
      #block(width: 100%, fill: fill-c, radius: (top: panel-radius), inset: (x: 1em, y: 0.42em), below: 0pt)[
        #set par(first-line-indent: 0em)
        #text(size: 11.25pt, fill: c, weight: "bold", title)
      ]
    ]
    #block(width: 100%, fill: zebra-fill(c.lighten(95%), fill-c), radius: (bottom: panel-radius), inset: (x: 1em, y: 0pt))[
      #zebra-rows(_callout-flag(body))
    ]
  ]
}

// ========================= 主模板 =========================

#let manual(
  title: "Manual",
  subtitle: none,
  description: none,
  authors: (),
  version: none,
  license: none,
  date: datetime.today(),
  abstract: none,
  show-toc: true,
  show-example-list: false,
  accent: none,
  body,
) = {
  let _accent = if accent != none { accent } else { theme.accent }
  let _authors = if type(authors) == str { (authors,) }
    else if authors == none { () }
    else { authors }

  // 允许 title / authors 是 content（便于写脚注等）；document() 元数据仅接受 str，过滤非 str 成员避免类型错。
  set document(
    title: if type(title) == str { title } else { none },
    author: _authors.filter(a => type(a) == str),
  )

  // --- 页面 ---
  set page(
    paper: "a4",
    margin: (left: 2.5cm, right: 2.5cm, top: 2.2cm, bottom: 2.4cm),
    // 页码本身是裸数字，`- -` 装饰只画在页脚：outline 的页码取自 page.numbering，
    //   若把装饰写进 numbering，目次里的页码也会跟着带上 `-8-`。
    numbering: "I",
    footer: context {
      set par(first-line-indent: 0em)
      align(center, [-] + counter(page).display() + [-])
    },
    header: context {
      let pg = counter(page).get().first()

      // 检查当前页本身是否有一级标题（说明是章节首页）
      let all-headings = query(heading.where(level: 1))
      let heading-on-this-page = all-headings.filter(h =>
        counter(page).at(h.location()).first() == pg
      )

      let current = if heading-on-this-page.len() > 0 {
        [] // 章节首页，留空
      } else {
        // 找当前页之前最近的一级标题
        let prev-headings = query(heading.where(level: 1).before(here()))
        if prev-headings.len() > 0 {
          let h = prev-headings.last()
          let num = counter(heading).at(h.location()).first()
          [#num\u{3000}#h.body] // 带章节编号
        } else {
          []
        }
      }

      if pg > 1 {
        set text(size: 11pt, style: "normal", fill: black, font: ("E-FZ", "FZHei-B01S"))
        set par(first-line-indent: 0em)
        grid(
          columns: (1fr, auto),
          align: (left, right),
          description, current
        )
        v(-0.5em)
        line(length: 100%, stroke: 0.75pt + theme.accent)
      }
    },
  )

  // --- 文字 ---
  set text(
    font: ("Founder-S10-BZ", "FZShuSong-Z01S"),
    lang: "zh",
    size: 11.25pt,
    top-edge: .663725em,
    fallback: false
  )
  show strong: set text(
    font: ((name: "E-HZ", covers: "latin-in-cjk"), "FZSongHei-B07"),
)
  show "、": it => text(font: "SimSun", it)
  show math.equation: set text(font: "TeX Gyre Termes Math")
  // HTML 模式下 Typst 默认丢弃公式（warning: equation was ignored during HTML export）
  // 用 html.frame 把每条公式转为内联 SVG 嵌入页面；
  // 行内公式 (it.block == false) 额外包一层 <span class="math-inline">，
  // 让段落不会在 SVG 处断行，并在 CSS 里走 inline-block + 深色取色
  show math.equation: it => if is-html-target {
    if it.block {
      html.frame(it)
    } else {
      html.elem("span", attrs: (class: "math-inline"))[#html.frame(it)]
    }
  } else { it }
  set par(justify: true, leading: 0.9em, spacing: 0.85em, first-line-indent: (amount: 2em, all: true))

  // 用 Word Joiner 粘在标点前面，解决禁则失效的问题
  show regex("[，、；：！？”’（）】》〉·]"): it => "\u{2060}" + it

  // --- 标题 ---
  // h1 / h2：思源黑体（不加粗），视觉上节级标识靠大小与颜色
  // h3：Fandol 楷体（加粗），产生明显的"骨骼变化"以区分层级
  set heading(numbering: "1.1")
  show heading.where(level: 1): it => {
    v(1em)
    block(sticky: true, breakable: false, below: 0.8em,
      text(
        font: ("FZHei-B01S"),
        size: 17pt,
        weight: "regular",
        fill: _accent,
        {
          show regex("[A-Za-z0-9]+"): t => text(font: "E-FZ", weight: "regular", t)
          // 手动渲染编号
          if it.numbering != none {
            counter(heading).display(it.numbering)
            [\u{3000}]
          }
          it.body
        },
      ))
  }
  show heading.where(level: 2): it => {
    block(sticky: true, breakable: false, below: 0.75em,
      text(
        font: ("FZHei-B01S"), // 方正黑体
        size: 12.5pt,
        weight: "regular",
        {
          show regex("[A-Za-z0-9]+"): t => text(font: "E-FZ", weight: "regular", t)
          if it.numbering != none {
            counter(heading).display(it.numbering)
            [\u{3000}]
          }
          it.body
        },
      ))
  }
  show heading.where(level: 3): it => {
    v(-0.3em)
    block(sticky: true, breakable: false, below: 0.65em,
      text(
        font: ("Libertinus Serif", "FZKai-Z03S"),
        size: 11pt,
        weight: "bold",
        {
          if it.numbering != none {
            counter(heading).display(it.numbering)
            [\u{3000}]
          }
          it.body
        }
      ))
  }

  // --- 链接 ---
  show link: it => if type(it.dest) == str and (
    it.dest.starts-with("http") or it.dest.starts-with("mailto:")
  ) { text(fill: theme.link, it) } else { it }

  // --- 交叉引用：中文标题用"第 N 章"/"N.M 节"格式 ---
  // 英文 @foo 默认渲染 "Section 2.1"（supplement 前置），中文需"2.1 节"/"第 1 章"，
  // 故对 heading 引用手动拼接；figure/example 保持 Typst 默认（supplement + 空格 + 编号），
  // 符合"图 1""例 3"的中文惯例。
  show ref: it => {
    let el = it.element
    if el == none { return text(fill: theme.link, it) }
    if el.func() == heading and el.numbering != none {
      text(fill: theme.link, link(el.location(), context {
        let num = numbering(el.numbering, ..counter(heading).at(el.location()))
        if el.level == 1 [第#(num)章] else [第 #(num) 节]
      }))
    } else { text(fill: theme.link, it) }
  }

  // --- 脚注：圆圈数字 ---
  //set footnote(numbering: n => quan(n))
  show: quan-footnote
  show footnote.entry: set text(size: 9pt)

  // 代码块：PDF 加斑马纹和语言标签；HTML 使用默认 raw 渲染。
  show raw.where(block: true): it => {
    if is-html-target { return it }
    show regex("[一-鿿　-〿＀-￯]+"): t => text(weight: "bold", t)
    context {
      let nested = in-callout()
      // 斑马纹环境里上下各留半行，合计一整行，代码块之后的文字仍落在条纹上。
      let gap = if in-zebra-rows() { auxiliary-row-height / 2 } else { 0.8em }
      // 代码行与其他斑马纹环境共用同一行格和平铺条纹。
      let code = block(
        width: 100%,
        fill: zebra-fill(theme.code-bg, theme.code-stripe),
        stroke: (top: 0.45pt + theme.code-accent),
        inset: (x: 0.6em, y: 0pt),
        radius: panel-radius,
        clip: true,
        zebra-rows(text(font: ("Latin Modern Mono", "FZFangSong-Z02S", "LXGW WenKai Mono"), it)),
      )
      block(width: 100%, above: gap, below: gap)[
        #place(top + left, dx: if nested { nested-hanging-label-dx } else { hanging-label-dx }, dy: -0.3em)[
          #box(width: hanging-label-width)[
            #align(right, text(fill: theme.code-accent, weight: "bold", size: code-label-size, font: "Libertinus Serif", if it.lang != none { "<" + it.lang + ">" } else { "</>" }))
          ]
        ]
        #code
      ]
    }
  }
  show raw.where(block: false): it => {
    show regex("[一-鿿　-〿＀-￯]+"): t => text(weight: "bold", t)
    let code = text(font: ("Latin Modern Mono", "FZFangSong-Z02S"), size: 1.2em, it)
    if is-html-target { code } else { context {
      // 按所在段落的汉字字框固定为一字号高，不随代码字体或字符变化。
      let han-height = text.size
      highlight(
        fill: theme.inline-code-bg,
        top-edge: han-height * 0.88,
        bottom-edge: -han-height * 0.12,
        extent: 1pt,
        code,
      )
    }
    }
  }

  // --- 题注字体（例 N / 图 N / 表 N）：CJK 用 Noto Sans CJK SC 不加粗，西文/数字走正文衬线字体并加粗 ---
  show figure.caption: it => {
    show regex("[A-Za-z0-9]+"): t => text(font: "E-FZ", weight: "regular", t)
    set text(font: "FZHei-B01S", size: 9pt)
    it
  }

  // --- 示例 figure 自定义显示 ---
  // 分隔线 + 左侧语言标签交给 `show raw.where(block: true)` 统一处理；这里只负责"例 N. 标题"标头
  show figure.where(kind: "ezm-example"): it => {
    if is-html-target {
      return html.elem("figure", attrs: (class: "example"))[
        #html.elem("figcaption")[
          例 #context it.counter.display(it.numbering)
          #h(0.8em)
          #it.caption.body
        ]
        #it.body
      ]
    }
    block(breakable: false, width: 100%, above: 0.8em, below: 0.8em)[
      #align(center, {
        show regex("[A-Za-z0-9]+"): t => text(font: "E-FZ", weight: "bold", t)
        set text(size: 9pt, font: "FZHei-B01S")
        [例 #context it.counter.display(it.numbering)#h(0.8em)#it.caption.body]
      })
      #v(-0.5em)
      #block(width: 100%, inset: (y: 0.1em), it.body)
    ]
  }

  // --- 非 example 图表的 caption 与图之间再收紧一点 ---
  set figure(gap: 0.4em)

  // --- 手册表格：浅色表头、细内线、紫色粗外框；真正的 table.header 可跨页重复。 ---
  // 外框由 block 绘制，因此首列左线和首行顶线留空，避免线条叠加。
  let _tbl-thin = 0.45pt + luma(155)
  let _tbl-thick = 1pt + theme.accent
  let _tbl-head-rule = 0.8pt + theme.accent.lighten(28%)
  set table(
    fill: (x, y) => if y == 0 {
      theme.accent-light
    } else if calc.odd(y) {
      theme.table-stripe
    } else {
      none
    },
    stroke: (x, y) => (
      left: if x == 0 { none } else { _tbl-thin },
      top: if y == 0 { none } else if y == 1 { _tbl-head-rule } else { _tbl-thin },
    ),
    inset: (x: 0.55em, top: 0.38em, bottom: 0.42em),
    align: (x, y) => left + if y == 0 { horizon } else { top },
  )
  // 所有表格都把首行声明为 table.header；这里统一表头的字重和底色。
  show table.cell.where(y: 0): set text(size: 11.25pt, weight: "bold")
  // 外框由 block 画，故 block 必须与表*同宽*：不写 width，让它收缩贴合表格实际宽度。
  //   写死 width: 100% 时，列宽全 auto、撑不满版心的表（如 API 区那几张语言代码表）
  //   会得到一个比表格宽出一截的空框。列里有 fr / 百分比的表照样铺满版心，不受影响。
  // 收缩后的外框在版心内居中；铺满版心的表不受影响。
  show table: it => {
    if is-html-target { return it }
    set align(center)
    block(
      stroke: _tbl-thick,
      radius: panel-radius,
      clip: true,
      inset: 0pt,
      breakable: true,
      above: 0.45em,
      below: 0.55em,
      {
        set text(size: auxiliary-size)
        set par(justify: false, first-line-indent: 0em)
        it
      },
    )
  }

  // ======== 标题页（HTML 下用语义化 header 简化）========
  if is-html-target {
    html.elem("header", attrs: (class: "manual-header"))[
      #html.elem("h1")[#title]
      #if subtitle != none [#html.elem("p", attrs: (class: "subtitle"))[#subtitle]]
      #if description != none [#html.elem("p", attrs: (class: "description"))[#description]]
      #if _authors.len() > 0 [#html.elem("p", attrs: (class: "authors"))[#_authors.join("  ·  ")]]
      #if version != none [#html.elem("p", attrs: (class: "meta"))[文档版本：#version]]
      #if date != none [#html.elem("p", attrs: (class: "meta"))[
        #if type(date) == datetime { date.display("[year]-[month]-[day]") } else { str(date) }
      ]]
      #if license != none [#html.elem("p", attrs: (class: "meta"))[许可证：#license]]
    ]
    if abstract != none {
      html.elem("section", attrs: (class: "abstract"))[#abstract]
    }
  } else {
    v(3cm)
    align(center)[
      #block(below: 1.6em,
        text(size: 28pt, weight: "bold", fill: _accent, title))
      #if subtitle != none {
        block(below: 0.8em, text(size: 14pt, fill: theme.muted, subtitle))
      }
      #if description != none {
        block(below: 1em, text(description))
      }
      #if version != none {
        block(below: 1em,
          text(size: 9pt)[文档版本：#version]
        )
      }
      #v(0.4em)
      #line(length: 35%, stroke: 1pt + _accent)
      #v(0em)
      #if _authors.len() > 0 {
        block(below: 1em, text(size: 10.5pt, _authors.join("  ·  ")))
      }
      #if date != none {
        block(below: 0.5em, text(size: 9pt,
          if type(date) == datetime { date.display("[year]-[month]-[day]") }
          else { str(date) }))
      }
      #if license != none {
        v(0.4em)
        block(text(size: 9pt, fill: theme.muted)[许可证：#license])
      }
    ]
    if abstract != none {
      v(2.5em)
      pad(left: 5%, right: 5%)[
        #set par(first-line-indent: (amount: 2em, all: true), justify: true)
        #text(size: 10.5pt, fill: luma(35), abstract)
      ]
    }
    pagebreak()
  }

  // ======== 目录（PDF：与封面连续；HTML：作为独立 nav）========
  if show-toc {
    if is-html-target {
      html.elem("nav", attrs: (class: "manual-toc"))[
        #html.elem("h2")[章节]
        #outline(title: none, indent: 1.5em, depth: 3)
        #if show-example-list [
          #html.elem("h2")[示例]
          #outline(title: none, target: figure.where(kind: "ezm-example"))
        ]
      ]
    } else {
      v(0.5em)
      align(center, text(size: 18pt, font: "FZHei-B01S")[目　　次])
      v(0.8em)
      // 章节较少，直接均分为两栏，避免自动分栏把短目录全部留在左栏。
      block(height: 20.5cm, breakable: false)[
        #set text(size: 10.5pt)
        #set par(leading: 0.62em, spacing: 0.28em, first-line-indent: 0em)
        #_chapter-toc()
      ]

      if show-example-list {
        v(2em)
        align(center, text(size: 14pt)[*示　　例*])
        v(.8em)
        columns(2, gutter: 1.5em)[
          #set text(size: 9.5pt)
          #outline(title: none, target: figure.where(kind: "ezm-example"))
        ]
      }
      pagebreak()
    }
  }

  // ======== 正文（PDF 翻到下一页，重置编码）========
  // set 规则块作用域：写在 if {} 里只对块内生效，块结束后页码恢复"I"，body 还是罗马数字。
  // 必须在 if 之外、body 之前调 set page(numbering: "1") 才能让正文走阿拉伯页码
  if not is-html-target {
    counter(page).update(1)
  }
  set page(numbering: "1")

  body
}

// ========================= 从源码自动提取选项 =========================
//
// 解析 lib.typ 这种 min-manual 风格的参数注释（`/// <- type` 尾随 + 多行 `///` 描述），
// 自动生成 option() 块。lib.typ 中的参数列表分隔注释 `// ── 分组名 ──`
// 被当作小节 heading 输出。

// API 参考只保留每项的概要。完整原理和示例放在正文专题中，避免同一内容重复两遍。
#let concise-option-description(description) = {
  let lines = description.split("\n").map(line => line.trim()).filter(line => line != "")
  if lines.len() == 0 { return "" }
  let first = lines.first()
  let kept = if first.starts-with("- ") or first.starts-with("+ ") {
    lines.slice(0, calc.min(2, lines.len()))
  } else {
    let prose = ()
    for line in lines {
      if line.starts-with("- ") or line.starts-with("+ ") or line.starts-with("#table") or line.starts-with("```") { break }
      prose.push(line)
      if line.ends-with("\\") { break }
    }
    prose
  }
  kept.map(line => if line.ends-with("\\") { line.slice(0, -1) } else { line }).join("\n")
}

#let concise-function-doc(description) = {
  let paragraphs = description.split(regex("\n\s*\n"))
  if paragraphs.len() == 0 { description } else { paragraphs.first().trim() }
}

#let parse-option-list(source, fn-name: "gb7714") = {
  // 定位 `#let <fn>(` 或缩进的 `  let <fn>(`
  let m = source.match(regex("(?:^|\n)\s*#?let\s+" + fn-name + "\\("))
  if m == none { return () }
  let tail = source.slice(m.end)

  // 找到参数列表结束位置：独占一行的 `) = ...`（允许内层函数的缩进）
  let end-m = tail.match(regex("\n\s*\\)\s*="))
  if end-m == none { return () }
  let params-src = tail.slice(0, end-m.start)

  let lines = params-src.split("\n")
  let items = ()
  let i = 0

  while i < lines.len() {
    let line = lines.at(i)

    // 分组分隔：  // ── 整体样式 ──
    let sm = line.match(regex("^\s*//\s*──\s*(.+?)\s*──\s*$"))
    if sm != none {
      items.push((kind: "section", title: sm.captures.at(0).trim()))
      i += 1
      continue
    }

    // 参数：  name[: default], /// <- type [<annotation>]
    let pm = line.match(
      regex("^\s+([a-zA-Z][a-zA-Z0-9_-]*)\s*(?::\s*(.+?))?\s*,\s*///\s*<-\s*(.+?)\s*$")
    )
    if pm != none {
      let name = pm.captures.at(0)
      let default-raw = pm.captures.at(1, default: none)
      let type-full = pm.captures.at(2)

      // 拆出 type 尾部的 <required> 之类标注
      let tm = type-full.match(regex("^(.+?)\s*<([^>]+)>\s*$"))
      let (typ, annot) = if tm != none {
        (tm.captures.at(0).trim(), tm.captures.at(1))
      } else {
        (type-full.trim(), none)
      }

      // 紧随其后的 /// 多行描述，`|` 为续行分隔符
      let desc-parts = ()
      let j = i + 1
      while j < lines.len() {
        let dm = lines.at(j).match(regex("^\s+///\s?(.*)$"))
        if dm == none { break }
        let piece = dm.captures.at(0)
        if piece.ends-with("|") { piece = piece.slice(0, -1) }
        desc-parts.push(piece.trim(at: end))
        j += 1
      }

      items.push((
        kind: "option",
        name: name,
        default: if default-raw != none { default-raw.trim() } else { none },
        type: typ,
        annotation: annot,
        // 换行 join：保留行首 `+`/`-` 列表语义，以及 `\` 硬换行
        description: concise-option-description(desc-parts.join("\n")),
      ))
      i = j
      continue
    }

    i += 1
  }

  // 内部参数 / 非公共参数不进手册：
  // - print-bib 的 bib-file / number-offset 由薄壳 `bibliography(..)` 内部传入，公共 API 不可达；
  // - show-series / prefix-last 只能在全局 `gb7714(..)` 中设置，公共 `bibliography(..)` 不接受，因此不在此显示；
  // - gb7714 的首位置参数 `path` 是旧 factory 形态的 bib 源；公共 native API（`#show: gb7714(..)`）
  //   不接收 bib 源（由 `#bibliography(read(..))` 后置传入），故隐藏。
  let _internal-params = ("print-bib": ("bib-file", "number-offset", "native-bib-index", "show-series", "prefix-last"), "gb7714": ("path",))
  let hidden = _internal-params.at(fn-name, default: ())
  let items = items.filter(it => it.kind != "option" or it.name not in hidden)

  // 说明来自实现文件，公开参数及默认值以包入口为准。
  let public-name = if fn-name == "print-bib" { "bibliography" } else { fn-name }
  let public-source = read("../../lib.typ")
  let public-start = public-source.match(regex("#let " + public-name + "\\("))
  if public-start != none {
    let public-tail = public-source.slice(public-start.end)
    let public-end = public-tail.match(regex("\n\\)\\s*="))
    if public-end != none {
      let defaults = (:)
      for line in public-tail.slice(0, public-end.start).split("\n") {
        let param = line.match(regex("^  ([a-z][a-z0-9-]*):\\s*(.+),\\s*(?://.*)?$"))
        if param != none { defaults.insert(param.captures.at(0), param.captures.at(1).trim()) }
      }
      items = items.filter(item => item.kind != "option" or item.annotation == "required" or item.name in defaults)
      items = items.map(item => {
        if item.kind == "option" and item.name in defaults {
          item.default = defaults.at(item.name)
          if item.default == "auto" and not item.type.contains("auto") { item.type = "`auto` | " + item.type }
        }
        item
      })
    }
  }

  let topics = (
    "bib-filter-section": ("full", "filter", "keys", "keyword", "mark", "entry-type"),
    "missing-data-section": ("show-anon", "show-no-date", "show-sine-loco", "show-sine-nomine", "show-sine-anno", "date-fallback"),
    "links-completion-section": ("back-ref", "hyperlink", "hyperlink-title", "cite-completion"),
    "name-style-section": ("bib-name-style", "cite-name-style", "name-style", "prefix-last", "name-suffix-separator", "et-al-translator-separator", "bib-name-date-separator", "cite-name-date-separator"),
    "sort-section": ("bib-sort-by", "cite-sort-by", "sort-by", "sort-keys", "bib-sort-zh-by", "cite-sort-zh-by", "sort-zh-by", "sort-use-prefix", "creator-idem"),
    "note-section": ("note", "note-repeat-style", "note-ibid", "note-repeat-reset", "note-numbering-style", "footnote-related-indent", "footnote-punct-style", "footnote-custom-punct", "footnote-url-break-every"),
    "display-control": ("show-mark", "show-medium", "show-url", "show-pid", "pid-priority", "dedup-url-pid"),
    "text-case-section": ("titles-text-case",),
    "custom-config-section": ("custom-marks", "custom-terms", "custom-fields", "custom-pids"),
    "custom-format": ("custom-drivers",),
    "cite-form-section": ("cite-form", "form"),
    "cite-supp-section": ("supplement", "cite-supplement-style", "supplement-style"),
    "page-range-style-section": ("page-range-style",),
    "lang-section": ("custom-languages", "entry-lang-detect", "entry-lang-order", "entry-localized-glyphs", "cite-terms-lang", "terms-lang"),
    "errors-section": ("warn-missing-title",),
  )
  items = items.map(item => {
    if item.kind == "option" {
      for (section, names) in topics {
        if item.name in names {
          item.description += " 详见 @" + section + "。"
          break
        }
      }
    }
    item
  })

  // 保留源码顺序：lib.typ 中参数已按"高频 + 依赖"手工排好；
  // 网页版可通过 `site.js` 的 sort-toggle 在 DOM 层切换为字母序，PDF 始终走源码顺序。
  items
}

#let options-from-source(
  source,
  fn-name: "gb7714",
  heading-level: 2,
) = {
  let items = parse-option-list(source, fn-name: fn-name)
  if is-html-target {
    // HTML 模式：把每个 section 标题 + 其下属 option 包到一个 <section class="api-section">
    // 容器里，便于 site.js 的"按字母排序"切换只在 section 边界内重排 DOM。
    let groups = ()
    let current = (title: none, opts: ())
    for item in items {
      if item.kind == "section" {
        if current.title != none or current.opts.len() > 0 {
          groups.push(current)
        }
        current = (title: item.title, opts: ())
      } else {
        current = (title: current.title, opts: current.opts + (item,))
      }
    }
    if current.title != none or current.opts.len() > 0 {
      groups.push(current)
    }
    for group in groups {
      html.elem("section", attrs: (class: "api-section", "data-fn": fn-name))[
        #if group.title != none {
          heading(level: heading-level, group.title)
        }
        #for opt in group.opts {
          option(opt.name, type: opt.type, default: opt.default, fn-name: fn-name,
            eval(opt.description, mode: "markup"))
        }
      ]
    }
  } else {
    for item in items {
      if item.kind == "section" {
        heading(level: heading-level, item.title)
      } else {
        option(
          item.name,
          type: item.type,
          default: item.default,
          eval(item.description, mode: "markup"),
        )
      }
    }
  }
}

// 提取 `/** ... **/` 块注释作为函数说明。
// 算法：定位 `let <fn>(` 位置，在其前方找最近的 `**/`，再向前找最近的 `/**`，
// 取二者之间的内容。这样可以避免跨块注释误匹配。
#let extract-function-doc(source, fn-name) = {
  let let-m = source.match(regex("(?:^|\n)\s*#?let\s+" + fn-name + "\\("))
  if let-m == none { return none }
  let prefix = source.slice(0, let-m.start)

  let closes = prefix.matches(regex("\*\*/"))
  if closes.len() == 0 { return none }
  let close = closes.last()

  // 仅当 `**/` 与 `let` 之间只有空白，才视为文档块紧邻函数
  if prefix.slice(close.end).trim() != "" { return none }

  let before-close = prefix.slice(0, close.start)
  let opens = before-close.matches(regex("/\*\*"))
  if opens.len() == 0 { return none }
  let open = opens.last()

  let content = prefix.slice(open.end, close.start)
  // 去掉每行统一的 2 空格缩进（代码块相对缩进保留）
  let lines = content.split("\n")
  let cleaned = lines.map(l => if l.starts-with("  ") { l.slice(2) } else { l })
  cleaned.join("\n").trim()
}

// 渲染单个函数的完整文档：块注释（拆出首行 `= ...` 作为函数标题）+ 参数列表。
//
// 层级策略：
//   • 函数标题：heading-level
//   • 块注释内部的 `=` 子节（如"快速开始"、".bib 特殊字段"）：heading-level + 1
//   • 参数列表中的 `// ── 分组 ──` 小节：heading-level + 1
#let function-from-source(
  source,
  fn-name,
  heading-level: 2,
  doc-scope: (:),
) = {
  let doc-text = extract-function-doc(source, fn-name)
  if doc-text != none and doc-text.trim() != "" {
    // 拆出第一条非空 `= ...` 作为显式函数标题
    let lines = doc-text.split("\n")
    let first-idx = 0
    while first-idx < lines.len() and lines.at(first-idx).trim() == "" {
      first-idx += 1
    }
    let head-m = if first-idx < lines.len() {
      lines.at(first-idx).match(regex("^=\s+(.+?)\s*$"))
    } else { none }

    if head-m != none {
      let head-text = head-m.captures.at(0)
      let body-text = concise-function-doc(lines.slice(first-idx + 1).join("\n"))
      // 若首行尾部带 `<label>`，剥离出来，渲染 heading 后用 #label(...) 附着，
      // 这样 `@label` 才能正确指向整个 heading（而不是 body 里的 text 元素）。
      let lbl-m = head-text.match(regex("\s*<([^<>\s]+)>\s*$"))
      let (head-body, lbl-name) = if lbl-m != none {
        (head-text.slice(0, lbl-m.start).trim(at: end), lbl-m.captures.at(0))
      } else {
        (head-text, none)
      }
      if lbl-name != none {
        [#heading(level: heading-level, eval(head-body, mode: "markup"))#label(lbl-name)]
      } else {
        heading(level: heading-level, eval(head-body, mode: "markup"))
      }
      [
        #set heading(offset: heading-level)
        #eval(body-text, mode: "markup")
      ]
    } else {
      heading(level: heading-level, raw(fn-name))
      [
        #set heading(offset: heading-level)
        #eval(doc-text, mode: "markup")
      ]
    }
  } else {
    heading(level: heading-level, raw(fn-name))
  }

  let opts = parse-option-list(source, fn-name: fn-name)
  // 若函数只有单个 required 位置参数、没有任何具名选项，参数表与 docstring 重复，跳过渲染
  let only-required = opts.filter(it => it.kind == "option").all(it => it.annotation == "required")
  let has-sections = opts.any(it => it.kind == "section")
  let render-opts = opts.len() > 0 and (has-sections or not only-required)
  if render-opts {
    parbreak()
    if is-html-target {
      // HTML：每个 section（含未命名首组）包到 <section class="api-section" data-fn="...">，
      // site.js 据此知道排序边界
      let groups = ()
      let cur = (title: none, opts: ())
      for item in opts {
        if item.kind == "section" {
          if cur.title != none or cur.opts.len() > 0 { groups.push(cur) }
          cur = (title: item.title, opts: ())
        } else {
          cur = (title: cur.title, opts: cur.opts + (item,))
        }
      }
      if cur.title != none or cur.opts.len() > 0 { groups.push(cur) }
      for group in groups {
        html.elem("section", attrs: (class: "api-section", "data-fn": fn-name))[
          #if group.title != none {
            heading(level: heading-level + 1, group.title)
          }
          #for opt in group.opts {
            option(opt.name, type: opt.type, default: opt.default, fn-name: fn-name,
              eval(opt.description, mode: "markup", scope: (arg-ref: arg-ref) + doc-scope))
          }
        ]
      }
    } else {
      for item in opts {
        if item.kind == "section" {
          heading(level: heading-level + 1, item.title)
        } else {
          option(
            item.name,
            type: item.type,
            default: item.default,
            fn-name: fn-name,
            eval(item.description, mode: "markup", scope: (arg-ref: arg-ref) + doc-scope),
          )
        }
      }
    }
  }
}

// 一次性渲染所有公开 API。
#let api-from-source(
  source,
  fn-names,
  heading-level: 2,
  doc-scope: (:),
) = {
  for name in fn-names {
    function-from-source(source, name, heading-level: heading-level, doc-scope: doc-scope)
  }
}
