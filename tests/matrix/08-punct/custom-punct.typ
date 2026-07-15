//! param: custom-punct
//! values: dictionary（键 = 标点字符本身，值 = 字符串或 (text: .., 样式..)）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-punct", controls: "精确覆盖某个结构标点的字面量，优先级高于 `bib-punct-style`。",
  expect: [*作用对象是结构标点*——引擎产出的著录格式串符号（段间句点、页码冒号、著者间逗号、卷期括号等），
    *不触碰用户字段文本*。唯一例外：显式开 `correct-punct` 时，字段内*矫正*的目标字形跟随本表的 `text` 值
    （矫正是否发生由 `correct-punct` 决定，本表只定目标字形）。
    覆写值是*绝对*字面量，*不再做全 / 半角感知*。
    键 = 标点字符本身，九种结构标点 `, : ; . ? ! / ( )`，半角或全角都认（中文 IME 默认打全角）；
    也接住 Typst 原生的 `((sym.paren.l): "〔")`（计算键被归一成字符 `"("`）。
    值有两种写法：纯字符串；或字典（须含 `text`，其余键透传给 `text(..)`，如 `font` / `weight` / `fill`）。
    ⚠️ 字典里 `text` 之外的样式*只作用于引擎产出的符号*，`correct-punct` 矫正出的字段内标点只读 `text` 值。])
#let cs = (<bm-zh>, <aj-zh>, <bm-online>)
#case("(:)（缺省）", gb7714.with(), cites: cs, full: false)
#case(`(",": " ### ")`.text + "（逗号换成一串标记）", gb7714.with(custom-punct: (",": " ### ")), cites: cs, full: false)
#case(`("(": "〔", ")": "〕")`.text, gb7714.with(custom-punct: ("(": "〔", ")": "〕")), cites: cs, full: false)
#case(`(".": "。")`.text + "（句点强制全角——绕过「句点恒半角」）", gb7714.with(custom-punct: (".": "。")), cites: cs, full: false)
#case(`("/": "／")`.text + "（斜杠改全角——绕过「斜杠恒半角」）", gb7714.with(custom-punct: ("/": "／")), cites: (<bm-online>, <eb-zh>), full: false)
#case("全角键等价半角键 " + `("，": "|")`.text, gb7714.with(custom-punct: ("，": "|")), cites: cs, full: false)
#case("Typst 原生计算键 " + `((sym.paren.l): "〔")`.text, gb7714.with(custom-punct: ((sym.paren.l): "〔")), cites: cs, full: false)
#case("字典值：(text: 「，」, weight: bold)", gb7714.with(custom-punct: (",": (text: "，", weight: "bold"))), cites: cs, full: false)
#case("覆写优先于 bib-punct-style（half 档下逗号仍全角）", gb7714.with(bib-punct-style: "half", custom-punct: (",": "，")), cites: cs, full: false)
#case("+ correct-punct: true（字段内矫正的目标字形跟覆写值）", gb7714.with(correct-punct: true, bib-punct-style: "by-entry-with-space", custom-punct: (";": " ；； ")), bib: EDGE, cites: (<ti-punct>,), full: false)
