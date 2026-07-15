//! param: show-mark
//! values: true, false, dictionary（entry_type > 码 > rest）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-mark", controls: "文献类型标识（`[M]` `[J]` `[S]` …）的显示。",
  expect: [`true`（缺省）全出，`false` 全不出。字典按条目控制，键 = 小写 entry_type（`.bib` 的类型名）
    或大写标识码（附录 A，按*版本中性语义类*匹配——`PP` 在 2015 同样命中预印本），`rest` 兜底；
    优先级 *entry_type > 码 > `rest`*。表 8 脚注 a「标准的文献类型标识为可选项」→
    `(rest: true, S: false)` 省去标准的 `[S]`、其余照出。值只收布尔（*没有* `"online-only"` 档——
    标识不是获取途径，联机判据对它无语义）。载体码由 `show-medium` 单独管。])
#let cs = (<bm-zh>, <aj-zh>, <st-zh>, <dt-zh>, <eb-zh>)
#case("true（缺省）", gb7714.with(), cites: cs, full: false)
#case("false", gb7714.with(show-mark: false), cites: cs, full: false)
#case(`(rest: true, S: false)`.text + "（省标准的 [S]）", gb7714.with(show-mark: (rest: true, S: false)), cites: cs, full: false)
#case(`(rest: false, J: true)`.text + "（只留期刊）", gb7714.with(show-mark: (rest: false, J: true)), cites: cs, full: false)
#case(`(book: false)`.text + "（按 entry_type 关）", gb7714.with(show-mark: (book: false)), cites: cs, full: false)
#case("优先级：entry_type 胜过码 " + `(book: true, M: false)`.text, gb7714.with(show-mark: (book: true, M: false)), cites: cs, full: false)
#case("show-mark: false + show-medium: true（只剩载体位）", gb7714.with(show-mark: false), cites: (<bm-online>, <eb-zh>), full: false)
