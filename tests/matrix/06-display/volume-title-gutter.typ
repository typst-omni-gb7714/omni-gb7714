//! param: volume-title-gutter
//! values: auto, length, content
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "volume-title-gutter", controls: "多卷书（有 `maintitle`）里卷号与分卷名之间的间距。",
  expect: [「中国科学技术史：第 2 卷␣科学思想史」里「第 2 卷」与「科学思想史」之间的那个空隙。
    `auto`（缺省）：普通词间空格。传长度（`1em`）：固定横向间距。也接受原样传入的 content / 字符串。])
#let cs = (<ti-multivolume>,)
#case("auto（缺省，词间空格）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("2em", gb7714.with(volume-title-gutter: 2em), bib: EDGE, cites: cs, full: false)
#case("0pt（贴死）", gb7714.with(volume-title-gutter: 0pt), bib: EDGE, cites: cs, full: false)
#case(`"："`.text + "（字符串原样）", gb7714.with(volume-title-gutter: "："), bib: EDGE, cites: cs, full: false)
#case("version: 2005", gb7714.with(version: 2005), bib: EDGE, cites: cs, full: false)
