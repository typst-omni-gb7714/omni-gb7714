// 缩进与编号版式的手玩场。**不是矩阵用例**，不进 golden、不被任何闸检查——
// 放在 tests/_playground/ 就是为了避开 matrix 的两道闸（必须有 `//! param:` 头、必须有 golden）。
//
// 用法：
//   typst compile --root . tests/_playground/layout.typ /tmp/p.pdf && open /tmp/p.pdf
//
// 页面故意做窄（8cm）、题名故意做长——不折行就看不出悬挂。
#import "/lib.typ": *

#set page(width: 8cm, height: auto, margin: 6mm)
#set text(lang: "zh", size: 9pt)

#let one = bytes(
  "@book{a, author={孙一}, title={条目的题名故意写得足够长，好让它折行，这样才看得出余行落在哪里}, address={北京}, publisher={母体出版社}, year={2018}, pages={50-60}, langid={chinese}}\n"
  + "@book{b, author={钱二}, title={第二条也够长，用来看条目间距与首行缩进是不是一致}, address={上海}, publisher={某社}, year={2020}, langid={chinese}}"
)
// 120 条：编号涨到 [120]，编号列宽跟着涨——用来看「与编号列宽解耦」
#let many = bytes(range(1, 121).map(i =>
  "@book{k" + str(i) + ", author={甲}, title={条目的题名故意写得足够长，好让它折行，这样才看得出余行落在哪里}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"
).join("\n"))

#let 试(标题, 配置, 语料: one) = {
  block(above: 10pt, below: 4pt, text(weight: "bold", fill: rgb("#166534"), 标题))
  block(stroke: (left: 1pt + luma(200)), inset: (left: 4pt))[
    #show: 配置
    #bibliography(语料, title: none, full: true)
  ]
}

= 余行缩进 entry-hanging-indent

#试([column（缺省）· auto → 0pt：余行贴正文列（这个 flush 是*编号列*给的，不是本参数给的）], gb7714.with())
#试([column · hanging 3em：正文列基础上再缩 3em], gb7714.with(entry-hanging-indent: 3em))
#试([inline · 缺省：余行顶格 —— *要顶格就用这一档*，不是把 hanging 设成 0], gb7714.with(number-placement: "inline"))
#试([inline · hanging 3em], gb7714.with(number-placement: "inline", entry-hanging-indent: 3em))
#试([margin · 编号挂到版心外], gb7714.with(number-placement: "margin"))
#试([著者-出版年制（无编号）· auto → 1.5em], gb7714.with(style: "author-date"))

= 首行缩进 entry-first-line-indent

#试([column · first-line 2em], gb7714.with(entry-first-line-indent: 2em))
#试([两量同时生效：hanging 3em + first-line 2em], gb7714.with(entry-hanging-indent: 3em, entry-first-line-indent: 2em))
#试([国标原文式：inline + first-line 2em（首行缩进、余行顶格）], gb7714.with(number-placement: "inline", entry-first-line-indent: 2em))

= 与编号列宽解耦（BUGS #8 里否掉「绝对量」方案的那条理由）

#试([120 条 · 同一个 hanging 3em。编号涨到 \[120\]、编号列变宽，余行跟着正文列一起平移
    ——*绝不会*倒插到首行文字左边。若语义是「距版心左缘的绝对值」，这里就崩了。],
  gb7714.with(entry-hanging-indent: 3em), 语料: many)
