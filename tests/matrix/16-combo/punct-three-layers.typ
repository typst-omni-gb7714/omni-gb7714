//! combo: bib-punct-style × custom-punct × correct-punct（三档正交）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：标点的三档", controls: "三个参数管三件不同的事，正交。",
  expect: [- `bib-punct-style`：*结构标点*的全 / 半角与尾空格（引擎产出的分隔符）；
    - `custom-punct`：*精确覆写*某个结构标点的字面量，*优先级高于* `bib-punct-style`，且覆写值*绝对*、不再感知；
    - `correct-punct`：矫正*用户字段文本*里的标点，方向由 `bib-punct-style` 与*条目语言*决定。
    三者的分界：`bib-punct-style` 与 `custom-punct` *只动结构标点*，`correct-punct` *只动字段文本*。
    唯一的交叉点：`correct-punct` 矫正出的目标*字形*跟随 `custom-punct` 的 `text` 值
    （矫正*是否发生*由 `correct-punct` 决定，`custom-punct` 只定字形）。
    「结构跟文档、内容跟条目」：`by-doc-*` 只管结构分隔符；字段内矫正恒按条目语言。])
#let pn = bytes("@book{tri-zh, author={丁}, title={题名里有半角逗号, 分号; 问号? 叹号!}, address={北京}, publisher={社}, year={2020}, pages={1--9}, langid={chinese}}
@book{tri-en, author={Smith, John}, title={Title with, comma; semicolon? question!}, address={NY}, publisher={P}, year={2020}, pages={1--9}, langid={english}}")
#let one(name, cfg) = case(name, cfg, bib: pn, full: true)
#one("① 只有 punct-style（结构标点全角，字段文本不动）", gb7714.with(bib-punct-style: "full"))
#one("① punct-style: half（结构标点半角）", gb7714.with(bib-punct-style: "half"))
#one("② + custom-punct（覆写优先于 punct-style，且绝对不感知）", gb7714.with(bib-punct-style: "half", custom-punct: (",": "，", ":": "："))) 
#one("③ + correct-punct（字段文本随条目语言矫正）", gb7714.with(bib-punct-style: "by-entry-with-space", correct-punct: true))
#one("②③ 交叉点：矫正的目标字形跟 custom-punct 的 text 值", gb7714.with(bib-punct-style: "by-entry-with-space", correct-punct: true, custom-punct: (";": " ；； ")))
#one("correct-punct 单独开、punct-style 是 half（把全角拉回半角）", gb7714.with(bib-punct-style: "half", correct-punct: true))
#one("by-doc（结构跟文档=中文→全角；字段矫正跟条目→西文条目不动）", gb7714.with(bib-punct-style: "by-doc-with-space", correct-punct: true))
#one("同上，但在西文文档里（结构翻半角，字段矫正仍跟条目）", in-lang("en", gb7714.with(bib-punct-style: "by-doc-with-space", correct-punct: true)))
#one("custom-punct 破「恒半角」：句点与斜杠改全角", gb7714.with(custom-punct: (".": "。", "/": "／")))
