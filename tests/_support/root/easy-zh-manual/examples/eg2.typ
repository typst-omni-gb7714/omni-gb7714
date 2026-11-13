// 示例 2：著者-出版年制（author-date）——与 eg1 顺序编码制对照，同一段正文、同一份 refs.bib。
#set page(height: auto, margin: 5pt)
#set text(lang: "zh", font: "Noto Serif CJK SC")
#set par(justify: true)
#import "/lib.typ": *
#show: gb7714(style: "author-date")
……改变社会规范也可能存在类似的“二阶囚徒困境”问题：尽管改变旧的规范对所有人都好，但个人理性选择使得没有人愿意率先违反旧的规范@Sunstein1996。……古希腊对轴心时代思想真正的贡献不是来自对民主的赞扬，而是来自对民主制度的批评，苏格拉底、柏拉图和亚里士多德3位贤圣都是民主制度的坚决反对者@Morris2010[260]。……一切后世的思想都是一系列为柏拉图思想所作的脚注@Rogers2011。……佛教受到极大的打击@Morris2010[326-329]。……陈登原先生的考证是非常精确的@陈登原2000。

#bibliography(read("/refs.bib"))
