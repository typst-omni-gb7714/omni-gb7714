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
    2025 且出版平台已由 `eprinttype` 著录时抑制 eprint 标签，并*合成*获取路径。

    *类型推断*（vanilla 导出遇 biblatex 无预印本类型时退成 `@misc`，丢 entrysubtype / pubstate）：`@misc` 若
    `publisher` 是已知预印本平台、或 `eprint` / `number` 带平台 label 前缀（`arXiv:…`）、或 `pubstate=prepublished`，
    还原成预印本。平台集复用 `pids` 的内置表（去 PubMed）+ 用户 `custom-pids` 注册的，不另立清单；`publisher=PubMed`
    的普通 `@misc` 不误判。])
#let pp = bytes(read("/tests/_fixture/parse.bib") + read("/tests/_fixture/types.bib"))
#let ks = (keys: [@pa-pubstate@pa-eprint-no-type@ty-preprint@ty-PP])
// vanilla 导出退成 @misc 的预印本：publisher 平台 / number 带 arXiv 前缀 / pubstate；PubMed 对照不误判
#let ppv = bytes("@misc{v-arxiv, author={{甲}}, title={arXiv vanilla}, date={2012-03-18}, publisher={arXiv}, number={arXiv:1112.6136}, url={https://doi.org/10.48550/arXiv.1112.6136}, urldate={2020-06-24}, langid={chinese}}
@misc{v-biorxiv, author={{乙}}, title={bioRxiv 平台}, date={2015-10-28}, publisher={bioRxiv}, url={https://doi.org/10.1101/029983}, urldate={2018-07-12}, langid={chinese}}
@misc{v-pubstate, author={{丙}}, title={pubstate 预印本}, date={2020}, pubstate={prepublished}, langid={chinese}}
@misc{v-pubmed, author={{丁}}, title={PubMed 非预印本}, date={2020}, publisher={PubMed}, langid={chinese}}")
#case("类型推断（@misc → 预印本）：publisher 平台 / number 前缀 / pubstate；PubMed 不误判", gb7714.with(), bib: ppv, cites: (<v-arxiv>, <v-biorxiv>, <v-pubstate>, <v-pubmed>), full: true)
#case("2025（PP）", gb7714.with(), bib: pp, full: true, bib-args: ks)
#case("2015（A）", gb7714.with(version: 2015), bib: pp, full: true, bib-args: ks)
#case("2005（Z）", gb7714.with(version: 2005), bib: pp, full: true, bib-args: ks)
#case("custom-marks 压得动版本化默认码：(preprint: \"YY\")", gb7714.with(custom-marks: (preprint: "YY")), bib: pp, full: true, bib-args: ks)
#case("show-pid: (eprint: false)（eprint 不出）", gb7714.with(show-pid: (eprint: false)), bib: pp, full: true, bib-args: ks)
