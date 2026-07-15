//! param: correct-punct
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "correct-punct", controls: "是否矫正*用户字段文本*里的标点。",
  expect: [`false`（缺省）：不矫正，字段文本原样。
    `true`：对长文本字段（`title` / `subtitle` / `titleaddon` / `maintitle` / `book*` / `journal*` /
    `eventtitle` / `series` / `note`，以及 `custom-terms.bib-field` 透传字段）做*单字符替换*：
    `,`↔`，`、`;`↔`；`、`!`↔`！`、`?`↔`？`，*方向由 `bib-punct-style` 与条目语言决定*。
    句点与冒号*不在矫正表里*（句点是缩写点与句末点的歧义源）。
    *花括号保护*：`{…}` 包裹的子串整段跳过矫正（花括号本身被剥离）。
    矫正在初始化解析 `.bib` 前一次性完成——*不支持* `cite()` / `bibliography()` 单次覆盖，
    要切换得换一个 `gb7714(..)` 实例。])
#let pn = bytes("@book{cp-zh2, author={丁}, title={题名里有半角逗号, 分号; 问号? 叹号!}, address={北京}, publisher={社}, year={2020}, langid={chinese}}
@book{cp-en, author={Smith, John}, title={Title with, comma; semicolon? question!}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{cp-brace, author={戊}, title={外面;{内部;不矫正}外面;}, address={北京}, publisher={社}, year={2020}, langid={chinese}}")
#case("false（缺省，原样）", gb7714.with(bib-punct-style: "by-entry-with-space"), bib: pn, full: true)
#case("true + by-entry-with-space（中文条目→全角，西文条目不动）", gb7714.with(correct-punct: true, bib-punct-style: "by-entry-with-space"), bib: pn, full: true)
#case("true + half（一律半角：全角标点被拉回半角）", gb7714.with(correct-punct: true, bib-punct-style: "half"), bib: pn, full: true)
#case("true + full（一律全角）", gb7714.with(correct-punct: true, bib-punct-style: "full"), bib: pn, full: true)
#case("true + by-doc-with-space · 中文文档（结构标点跟文档 → 全角；字段内矫正跟*条目* → 西文条目不动）", gb7714.with(correct-punct: true, bib-punct-style: "by-doc-with-space"), bib: pn, full: true)
#case("true + by-doc-with-space · 西文文档（结构标点翻半角；字段内矫正仍跟条目 → 中文条目照样全角）", in-lang("en", gb7714.with(correct-punct: true, bib-punct-style: "by-doc-with-space")), bib: pn, full: true)
