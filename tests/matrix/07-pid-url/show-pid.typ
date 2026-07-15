//! param: show-pid
//! values: dictionary（逐标识符 true/false/"online-only"/auto + 元键 max/rest + 条目词汇键）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-pid", controls: "永久标识符（DOI / CSTR / ISBN / ISSN / eprint 及自定义 PID）的显示。",
  expect: [逐标识符取值：`true` 强制显示（即使 URL 已含同串、即使被 CSTR / DOI 互斥压制）；`false` 隐藏；
    `"online-only"` 仅网络文献显示（联机判据见 `show-url`；*不含*强制直通豁免，URL 去重仍生效）；
    缺省 / `auto` 自动（URL 含同串或同类型标记则隐藏）。
    *默认显示*：DOI 恒显示；CSTR 仅 `version: 2025` 默认显示；eprint 默认显示；ISBN / ISSN 默认*不*显示（国标列为任选项）。
    *元键*：`max` = 著录数量上限（`max: 1` 对齐 2025「只须著录一个标识符」，取 `pid-priority` 下首个有值者；
    `dedup-url-pid` 开启时 URL 已承载的标识符*计入配额*）；`rest` = 未点名标识符的兜底档。
    *条目词汇键*（与 `show-mark` 同一套：entry_type > 码 > `rest`）按条目关停全部标识符；标识符名键优先于条目词汇键。
    *CSTR / DOI 互斥*：cstr 命中时抑制 doi；在 `show-pid` 里显式给 `doi` 任一值后互斥失效。])
#let cs = (<pid-all>, <pid-eprint>, <pid-isbn>)
#case("(:)（缺省：DOI 显示、CSTR 2025 显示且压住 DOI、ISBN 不显示）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("version: 2015（CSTR 默认关，DOI 出场）", gb7714.with(version: 2015), bib: EDGE, cites: cs, full: false)
#case(`(isbn: true)`.text, gb7714.with(show-pid: (isbn: true)), bib: EDGE, cites: cs, full: false)
#case(`(doi: true)`.text + "（显式给 doi 值 → CSTR 互斥失效，两个都出）", gb7714.with(show-pid: (doi: true)), bib: EDGE, cites: cs, full: false)
#case(`(rest: false, doi: true)`.text + "（只留 DOI）", gb7714.with(show-pid: (rest: false, doi: true)), bib: EDGE, cites: cs, full: false)
#case(`(rest: true)`.text + "（全出，含默认不显的 ISBN）", gb7714.with(show-pid: (rest: true)), bib: EDGE, cites: cs, full: false)
#case(`(max: 1)`.text + "（至多一个，取 pid-priority 首个有值者）", gb7714.with(show-pid: (rest: true, max: 1)), bib: EDGE, cites: cs, full: false)
#case(`(rest: "online-only")`.text, gb7714.with(show-pid: (rest: "online-only")), bib: EDGE, cites: cs, full: false)
#case(`(article: false)`.text + "（条目词汇键：按 entry_type 全关）", gb7714.with(show-pid: (article: false)), bib: EDGE, cites: cs, full: false)
#case("标识符名键优先于条目词汇键 " + `(article: false, doi: true)`.text, gb7714.with(show-pid: (article: false, doi: true)), bib: EDGE, cites: cs, full: false)
#case(`(eprint: false)`.text, gb7714.with(show-pid: (eprint: false)), bib: EDGE, cites: cs, full: false)
