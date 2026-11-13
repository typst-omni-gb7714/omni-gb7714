//! combo: bib-name-style 八维 × prefix-last × name-suffix-separator × version 默认 × nameformat 字段
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：西文姓名的成形", controls: "一个西文姓名要过八维字典、前缀档、后缀接缝、版本默认四关。",
  expect: [`bib-name-style` 八维：`order`（可拆 `(first:, rest:)` 双键）/ `family-case` / `given-form` /
    `given-initial-separator` / `given-separator` / `given-case` / `family-given-separator` / `given-family-separator`。
    `prefix-last` 与它*正交*：管前缀（van der）全拼前置还是全拼后置（biblatex useprefix 的显示半）；不随版本，缺省 `false`（前置）。
    `name-suffix-separator` 管世系后缀（Jr. / II）的接缝。
    条目级 `nameformat` 字段*优先于*本参数（混合语料逐条标）。
    大小写仍由 `name-style` 决定：`family-case: "uppercase"` 前置前缀也大写（`VAN DER BERG J`），后置前缀（`true` 档）保原小写。])
#let cs = (<nm-prefix>, <nm-suffix>, <nm-hyphen>, <nm-nameformat>, <nm-corp>)
#let one(name, cfg) = case(name, cfg, bib: EDGE, cites: cs, full: false)
#one("2025 缺省（前缀前置 · 姓原样）", gb7714.with(bib-et-al-min: 999, version: 2025))
#one("2015 缺省（前缀前置 · 姓大写）", gb7714.with(bib-et-al-min: 999, version: 2015))
#one("+ family-case: uppercase（前缀首字母也大写）", gb7714.with(bib-et-al-min: 999, bib-name-style: (family-case: "uppercase")))
#one("+ given-form: full（名全拼）", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "full")))
#one("+ given-initial-separator: 「.」（缩写点）", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-initial-separator: ".")))
#one("+ order: given-ahead（名在前）", gb7714.with(bib-et-al-min: 999, bib-name-style: (order: "given-ahead", given-form: "full")))
#one("+ order 双键 (first: family-ahead, rest: given-ahead)", gb7714.with(bib-et-al-min: 999, bib-name-style: (order: (first: "family-ahead", rest: "given-ahead"), given-form: "full")))
#one("+ name-suffix-separator: 「, 」", gb7714.with(bib-et-al-min: 999, name-suffix-separator: ", "))
#one("八维全给 + prefix-last: false", gb7714.with(bib-et-al-min: 999, prefix-last: false, bib-name-style: (
  order: "family-ahead", family-case: "uppercase", given-form: "initials", given-initial-separator: ".",
  given-separator: " ", given-case: "uppercase", family-given-separator: ", ", given-family-separator: " ")))
#one("条目级 nameformat 压全局", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: none)))
