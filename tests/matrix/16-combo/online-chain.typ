//! combo: show-url × show-medium × show-pid × dedup-url-pid × 联机判据
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：联机判据链", controls: "「这条目算不算网络文献」牵动载体码、URL、引用日期、永久标识符四处。",
  expect: [*联机判据五级*（`show-url` 的 doc）：显式 `medium` 字段 → 显式标识含载体段（`usera = {M/OL}`）→
    `@online` 类型 → 数字原生类型（webpage / software / dataset / database / preprint）且有获取途径 → 默认非联机。
    判据一变，四处跟着变：*载体码* `/OL`、*URL*、*引用日期*、*永久标识符*。
    `show-url: false` 不只是藏 URL——它*连 OL 自动判定一起关*。
    `show-url: "online-only"` 让非联机条目的 URL / PID / 引用日期*整组*不出。
    `dedup-url-pid` 与 `show-pid.max` 联手：URL 已承载的标识符*计入配额*（见 BUGS #3 的裁决点）。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let cs = (<bm-online>, <eb-zh>, <ds-zh>, <sw-zh>, <bm-zh>, <mk-usera>, <pid-all>)
#let one(name, cfg) = case(name, cfg, cites: cs, bib: mixed, full: false)
#one("缺省", gb7714.with())
#one("show-url: false（连 OL 判定一起关）", gb7714.with(show-url: false))
#one("show-url: \"online-only\"", gb7714.with(show-url: "online-only"))
#one("show-medium: false（只剩类型码，URL 照出）", gb7714.with(show-medium: false))
#one("show-url: false + show-pid: (rest: true)（PID 仍出）", gb7714.with(show-url: false, show-pid: (rest: true, doi: true)))
#one("dedup-url-pid: false（URL 与 DOI 都出）", gb7714.with(dedup-url-pid: false, show-pid: (rest: true, doi: true)))
#one("show-pid: (max: 1) + dedup（URL 承载的计入配额）", gb7714.with(show-pid: (rest: true, doi: true, max: 1)))
#one("show-pid: (max: 1) + dedup-url-pid: false", gb7714.with(show-pid: (rest: true, doi: true, max: 1), dedup-url-pid: false))
#one("show-urldate: false（引用日期不出，URL 照出）", gb7714.with(show-urldate: false))
#one("三者全关", gb7714.with(show-url: false, show-medium: false, show-urldate: false, show-pid: (rest: false)))
