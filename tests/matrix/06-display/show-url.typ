//! param: show-url
//! values: true, false, "online-only", dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-url", controls: "获取和访问路径（URL）的显示，并连带管住联机载体判定。",
  expect: [`true`（缺省）：著录 URL，条目自动标 OL 载体。
    `false`：隐藏 URL，*并禁用 OL 自动载体判定*（不是单纯藏字段）。
    `"online-only"`：只有*网络文献*才著录——非联机条目的 URL、永久标识符、引用日期*整组*不出，
    载体码同步（纸质书带 `url` 字段不再冒出 `[M/OL]`）。联机判据五级：显式 `medium` → 显式标识含载体段
    （`usera = {M/OL}`）→ `@online` → 数字原生类型（webpage/software/dataset/database/preprint）且有获取途径 → 默认非联机。
    字典的键与 `show-mark` 同一套（entry_type > 码 > `rest`），值 = 布尔或 `"online-only"`。])
#let cs = (<bm-online>, <eb-zh>, <ds-zh>, <sw-zh>, <bm-zh>)
#case("true（缺省）", gb7714.with(), cites: cs, full: false)
#case("false（连 OL 自动判定一起关）", gb7714.with(show-url: false), cites: cs, full: false)
#case(`"online-only"`.text + "（纸质书的 url 整组不出）", gb7714.with(show-url: "online-only"), cites: cs, full: false)
#case(`(rest: false, online: true)`.text, gb7714.with(show-url: (rest: false, online: true)), cites: cs, full: false)
#case(`(rest: "online-only", M: false)`.text, gb7714.with(show-url: (rest: "online-only", M: false)), cites: cs, full: false)
#case("show-url: false + 条目写 medium = {OL}（强制载体）", gb7714.with(show-url: false), bib: bytes("@article{force, author={Кочетков, А. Я.}, title={Молибден}, journaltitle={Отечественная геология}, volume={1993}, number={7}, pages={50--58}, medium={OL}, url={https://e.com}, year={1993}}"), full: true)
