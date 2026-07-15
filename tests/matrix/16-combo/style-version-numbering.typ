//! combo: style（四轴）× version × numbering-style × disambiguate
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：style × version × numbering-style", controls: "样式轴与版本轴怎样一起决定标注与著录。",
  expect: [`style` 是四轴的合成：`cite`（标注形态）× `bib`（著录格式）；字典形收严要求*双轴都给*。
    `version` 决定：标点缺省档（2015 半角带空格 / 2025 全角）、`prefix-last` 缺省、
    预印本码（2025 PP / 2015 A / 2005 Z）、CSTR 默认开关、AY 文献表句点。
    `numbering-style` 只在顺序编码制下有意义，且*文献表与行内标注同源*。
    `disambiguate` 的 `given-name` / `names` 两档在 `auto` 下跟*标注形态轴*——
    混合制（`(cite: "numeric", bib: "author-date")`）想要表侧效果得显式 `true`。])
#let cs = (<bm-zh>, <bm-en>, <aj-zh>)
#case("numeric × 2025（缺省）", gb7714.with(), cites: cs, full: false)
#case("numeric × 2015", gb7714.with(version: 2015), cites: cs, full: false)
#case("author-date × 2025", gb7714.with(style: "author-date"), cites: cs, full: false)
#case("author-date × 2015", gb7714.with(style: "author-date", version: 2015), cites: cs, full: false)
#case("author-date × 2005（AY 文献表句点）", gb7714.with(style: "author-date", version: 2005), cites: cs, full: false)
#case("混合制 (cite: numeric, bib: author-date)", gb7714.with(style: (cite: "numeric", bib: "author-date")), cites: cs, full: false)
#case("混合制 + disambiguate: true（表侧才有消歧）", gb7714.with(style: (cite: "numeric", bib: "author-date"), disambiguate: true), bib: EDGE, cites: (<nm-same-a>, <nm-same-b>), full: false)
#case("混合制 (cite: author-date, bib: numeric)", gb7714.with(style: (cite: "author-date", bib: "numeric")), cites: cs, full: false)
#case("numbering-style 同源：文献表 (1) → 行内也 (1)", gb7714.with(numbering-style: "paren"), cites: cs, full: false)
#case("numbering-style: none + 顺序编码制（无号可标）", gb7714.with(numbering-style: none), cites: cs, full: false)
