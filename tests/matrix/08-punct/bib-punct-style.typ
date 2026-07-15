//! param: bib-punct-style
//! values: auto, "half-with-space", "half", "full", "by-doc-no-space", "by-doc-with-space", "by-entry-no-space", "by-entry-with-space"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-punct-style", controls: "文献表著录标点的全 / 半角风格（正文标注的 `cite-punct-style` 是它的超集）。",
  expect: [`auto`（缺省）随 `version`——2015 取 `"half-with-space"`、2025 取 `"full"`。
    *绝对*三档：`"half-with-space"`（分隔符带尾空格 `, ` `. ` `: `）/ `"half"`（无尾空格）/ `"full"`（一律全角）。
    *随文档语言*：`"by-doc-no-space"` / `"by-doc-with-space"`（中日文档全角、西文文档半角）。
    *随条目语言*：`"by-entry-no-space"` / `"by-entry-with-space"`（各条目按自身语言）。
    受控符号：`,` `:` `(` `)` `;` `?` `!`。
    *句点 `.` 例外，恒取半角*：`"half-with-space"` 与 `"full"` 档为 `. `、`"half"` 档为 `.`，末尾去尾空格。
    *恒半角*：句点 `.`、斜杠 `/`（护 `//` 与 `/OL`）、方括号 `[]`。要改它们得用 `custom-punct`。
    「结构跟文档、内容跟条目」：`by-doc-*` 只管分隔符；`correct-punct` 矫正的*字段内*标点恒按条目语言。
    本文件的*文档语言是中文*（probe 缺省），`by-doc-*` 因此走全角；末两块用 `in-lang("en", ..)`
    把同一配置裹进*西文文档*作对照——同样的档位翻成半角。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>, <aj-en>, <bm-online>)
#case("auto · 2025（→ full）", gb7714.with(), cites: cs, full: false)
#case("auto · 2015（→ half-with-space）", gb7714.with(version: 2015), cites: cs, full: false)
#case(`"half-with-space"`.text, gb7714.with(bib-punct-style: "half-with-space"), cites: cs, full: false)
#case(`"half"`.text + "（无尾空格）", gb7714.with(bib-punct-style: "half"), cites: cs, full: false)
#case(`"full"`.text, gb7714.with(bib-punct-style: "full"), cites: cs, full: false)
#case(`"by-doc-no-space"`.text + "（中文文档 → 全角）", gb7714.with(bib-punct-style: "by-doc-no-space"), cites: cs, full: false)
#case(`"by-doc-with-space"`.text, gb7714.with(bib-punct-style: "by-doc-with-space"), cites: cs, full: false)
#case(`"by-entry-no-space"`.text + "（中文条目全角、西文条目半角）", gb7714.with(bib-punct-style: "by-entry-no-space"), cites: cs, full: false)
#case(`"by-entry-with-space"`.text, gb7714.with(bib-punct-style: "by-entry-with-space"), cites: cs, full: false)
#case("著者-出版年制 · full（人名↔年份的句点也恒半角）", gb7714.with(style: "author-date", bib-punct-style: "full"), cites: cs, full: false)
#case(`"by-doc-no-space"`.text + " · 西文文档（→ 半角）", in-lang("en", gb7714.with(bib-punct-style: "by-doc-no-space")), cites: cs, full: false)
#case(`"by-entry-no-space"`.text + " · 西文文档（不随文档 → 中文条目仍全角）", in-lang("en", gb7714.with(bib-punct-style: "by-entry-no-space")), cites: cs, full: false)
