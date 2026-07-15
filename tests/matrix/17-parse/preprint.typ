//! param: 预印本判据（@preprint · entrysubtype · pubstate · eprint 链）
//! values: 三种写法 × 三个版本
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "预印本", controls: "「这条算预印本吗」的判据，与各版本的码。",
  expect: [*判据*（任一命中即预印本）：`@preprint` 类型本身；`@article` 写 `entrysubtype = preprint`（正名写法）
    或带 arXiv 系字段（便捷写法）；`pubstate = prepublished`（biblatex 的「预先出版、未正式发表」标记，
    *任何* entry 类型都算——对齐标准 8.15 示例的 `[PP/OL]`）。
    *版本化默认码*：2025 `PP` / 2015 `A` / 2005 `Z`。它落在取码链的「版本化类型默认」层，
    因此 `custom-marks` 与条目字段都压得动它（曾经硬给码、绕过整条链）。
    *eprint 标签*按 `archiveprefix` / `eprinttype` 派生（arXiv / ChinaXiv / PubMed…），缺省回退 `eprint:`。
    2025 且出版平台已由 `eprinttype` 著录时抑制 eprint 标签，并*合成*获取路径。])
#let pp = bytes(read("/tests/_fixture/parse.bib") + read("/tests/_fixture/types.bib"))
#let ks = (keys: [@pa-pubstate@pa-eprint-no-type@ty-preprint@ty-PP])
#case("2025（PP）", gb7714.with(), bib: pp, full: true, bib-args: ks)
#case("2015（A）", gb7714.with(version: 2015), bib: pp, full: true, bib-args: ks)
#case("2005（Z）", gb7714.with(version: 2005), bib: pp, full: true, bib-args: ks)
#case("custom-marks 压得动版本化默认码：(preprint: \"YY\")", gb7714.with(custom-marks: (preprint: "YY")), bib: pp, full: true, bib-args: ks)
#case("show-pid: (eprint: false)（eprint 不出）", gb7714.with(show-pid: (eprint: false)), bib: pp, full: true, bib-args: ks)
