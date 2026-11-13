//! param: mark-medium-bracket-style
//! values: half, full
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "mark-medium-bracket-style", controls: "文献类型标识的方括号半 / 全角。",
  expect: [`half`（缺省）：`[M]`、`[EB/OL]`——GB 各版标准。`full`：`［M］`、`［EB/OL］`——全角方括号，
    与 CJK 正文视觉统一时用。块内斜杠 `/`（`[EB/OL]` 那个）恒半角，不随此参数切换。
    只作用于 `mark-medium` 这个封装 token；`custom-drivers` 里的裸 `mark` / `medium` token 不受它管。
    改成全角是偏离 GB 标准的排版选择。])
#let cs = (<bm-zh>, <bm-en>, <eb-zh>)
#case("half（缺省）", gb7714.with(), cites: cs, full: false)
#case("full", gb7714.with(mark-medium-bracket-style: "full"), cites: cs, full: false)
#case("full + 裸 mark token 的自定义驱动（不受它管）", gb7714.with(mark-medium-bracket-style: "full",
  custom-drivers: (book: "<creator>. <titles>[<mark>]. <publisher>, <year>")), cites: (<bm-zh>,), full: false)
#case("full + mark-medium token 的自定义驱动（受它管）", gb7714.with(mark-medium-bracket-style: "full",
  custom-drivers: (book: "<creator>. <titles><mark-medium>. <publisher>, <year>")), cites: (<bm-zh>,), full: false)
