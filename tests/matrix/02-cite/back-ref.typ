//! param: back-ref
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "back-ref", controls: "文献表条目末尾是否回链到正文引用处（反向引用）。",
  expect: [`true`：条目编号变成链接，点击跳回正文首次引用处；没被引用过的条目编号仍是纯文本。`false`（缺省）：编号纯文本。
    编号先裹 `box` 再交给 `link`：宿主常见的 `show link: it => { h(..); it; h(..) }`（补回 text run 末尾丢掉的
    tracking）会把间距插到编号前面，全角 `［` 不再是行首第一个字符、Typst 的行首开括号挤压失效，被引用的
    条目编号比未引用的右移半个字宽（实测 12pt 下 6.2pt，编号甚至被挤到下一行）。裹了盒子后间距落在盒外，
    最后一例里被引用的 ［1］ 与未引用的 ［2］ 必须同列对齐、同在一行。])
// 宿主式的链接间距规则（中文模板普遍有），不影响前两例（无 link 元素）。
#show link: it => { h(0.4543pt, weak: true); it; h(0.4543pt, weak: true) }
#case("false（缺省）", gb7714.with(), cites: (<bm-zh>, <bm-en>), full: false)
#case("true", gb7714.with(back-ref: true), cites: (<bm-zh>, <bm-en>), full: false)
#let BR = bytes("@book{br-cited, author={Zhang, San}, title={Alpha}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{br-uncited, author={Li, Si}, title={Beta}, publisher={P}, address={X}, date={2021}, langid={english}}")
#case("true + fullwidth-bracket + 宿主 show link 补间距：被引用 ［1］ 与未引用 ［2］ 编号同列不错位", gb7714.with(back-ref: true, bib-numbering-style: "fullwidth-bracket"), cites: (<br-cited>,), bib: BR, full: true)
