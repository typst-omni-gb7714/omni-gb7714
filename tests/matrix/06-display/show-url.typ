//! param: show-url
//! values: true, false, "online-only", dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-url", controls: "只控制获取和访问路径（URL）的显示。",
  expect: [`true`（缺省）：显示已有 URL，不据此改动载体。
    `false`：隐藏 URL，不抑制 PID、引用日期或已判定的 OL。
    `"online-only"`：仅网络文献显示 URL；其他条目的 PID、引用日期仍各按其规则处理。
    联机判据五级：显式 `medium` → 显式标识含载体段
    （`usera = {M/OL}`）→ `@online` → 数字原生类型（webpage/software/dataset/database/preprint）且有获取途径 → 默认非联机。
    字典的键与 `show-mark` 同一套（entry_type > 码 > `rest`），值 = 布尔或 `"online-only"`。])
#let cs = (<bm-online>, <eb-zh>, <ds-zh>, <sw-zh>, <bm-zh>)
#case("true（缺省）", gb7714.with(), cites: cs, full: false)
#case("false（只隐藏 URL）", gb7714.with(show-url: false), cites: cs, full: false)
#case(`"online-only"`.text + "（非联机条目只隐藏 URL）", gb7714.with(show-url: "online-only"), cites: cs, full: false)
#case(`(rest: false, online: true)`.text, gb7714.with(show-url: (rest: false, online: true)), cites: cs, full: false)
#case(`(rest: "online-only", M: false)`.text, gb7714.with(show-url: (rest: "online-only", M: false)), cites: cs, full: false)
#case("show-url: false + 条目写 medium = {OL}（强制载体）", gb7714.with(show-url: false), bib: bytes("@article{force, author={Кочетков, А. Я.}, title={Молибден}, journaltitle={Отечественная геология}, volume={1993}, number={7}, pages={50--58}, medium={OL}, url={https://e.com}, year={1993}}"), full: true)
