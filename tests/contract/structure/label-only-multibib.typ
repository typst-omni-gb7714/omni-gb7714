// 回归：只用 `cite(bib-label:)` + `bibliography(label:)`、全篇*不调* `set-bib-label`，
//   命名列表的逐 cite 归属过滤仍须生效——每张表只打属于自己的条目。
//   曾 bug：`cited-keys` 的 `named-lists` 判据只认 `set-bib-label`（它才登记 `gb7714-list-ids`），
//   此路径下判为假 → 过滤短路 → 每张命名表打出*全部*条目。矩阵测不到：probe 的 `case`
//   每次内部都调 `set-bib-label(tag)`，全局点亮 `named-lists`，恰好把此路径的 bug 掩盖。
//   断言（run.sh）：作者名各出现*一次*（各在自己表）；bug 时出现*两次*（两表都打）。
#import "/lib.typ": *
#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
#set page(width: 340pt, height: auto, margin: 12pt)
#let DATA = bytes("@book{qxaa,author={Qxaa},title={Taa},publisher={P},year={2020}}
@book{qxbb,author={Qxbb},title={Tbb},publisher={P},year={2020}}
@book{qxzz,author={Qxzz},title={Tzz},publisher={Q},year={2021}}")
#show: gb7714.with(full: false)
甲区 #cite(<qxaa>, bib-label: "la") #cite(<qxbb>, bib-label: "la")
乙区 #cite(<qxzz>, bib-label: "lb")
#bibliography(DATA, title: [列表A], label: "la")
#bibliography(DATA, title: [列表B], label: "lb")
