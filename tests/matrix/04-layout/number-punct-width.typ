//! param: number-punct-width
//! values: full(默认), native, 半角样式两档无差别, 逐表覆写
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "number-punct-width", controls: "文献表编号里全角标点（［］〔〕（））的占宽。",
  expect: [`"full"`（默认）：挡掉 Typst 对行首全角开标点、行尾全角闭标点各压半个字宽的挤压——`［` 的字框
    从版心左缘起、编号列宽按全宽测量，对齐 Word 默认（「允许行首标点压缩」不勾）与 xeCJK 全角式。
    `"native"`：不干预，交还 Typst（12pt 下 `［` 墨迹紧贴版心、列宽窄一个字宽；上游无开关，typst\#7643 未决）。
    半角 `[1]`、`(1)`、`1.` 不含全角标点，两档零差别。挡法是编号两侧各垫零宽弱间距：不占宽、
    不进提取文本（所以两档的 golden *文本*可能一致，几何差异由 contract/typography 的 SVG 对比把关）。
    `number-placement: "margin"` 的负缩进按同一份 `measure` 走，两头一致后编号右缘到正文的间隙恢复为
    `number-gutter` 整格（修前左压被负缩进挡住、右压照发，间隙被吃掉 6pt）。])
#case("full（默认）· fullwidth-bracket", gb7714.with(bib-numbering-style: "fullwidth-bracket"), cites: (<bm-zh>,), full: false)
#case("native · fullwidth-bracket（放行 Typst 行首行尾挤压）", gb7714.with(bib-numbering-style: "fullwidth-bracket", number-punct-width: "native"), cites: (<bm-zh>,), full: false)
#case("native · 半角 bracket：无全角标点，两档无差别", gb7714.with(number-punct-width: "native"), cites: (<bm-zh>,), full: false)
#case("full · margin 版式（编号挂版心外，间隙恢复 number-gutter 整格）", gb7714.with(bib-numbering-style: "fullwidth-bracket", number-placement: "margin"), cites: (<bm-zh>,), full: false)
#case("逐表覆写 bibliography(number-punct-width: \"native\")", gb7714.with(bib-numbering-style: "fullwidth-bracket"), cites: (<bm-zh>,), full: false, bib-args: (number-punct-width: "native"))
