//! combo: show-url × show-medium × show-pid × dedup-url-pid × 联机判据
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：联机判据链", controls: "载体和 online-only 共用联机属性，URL、PID、引用日期分别控制显示。",
  expect: [*联机判据五级*（`show-url` 的 doc）：显式 `medium` 字段 → 显式标识含载体段（`usera = {M/OL}`）→
    `@online` 类型 → 数字原生类型（webpage / software / dataset / database / preprint）且有获取途径 → 默认非联机。
    联机属性不受显示开关影响；URL 的 online-only 不抑制 PID 或引用日期。
    普通图书、期刊只有 URL/DOI 不自动添加 OL。去重仅比较实际输出的 URL，
    max 只统计实际著录的 PID，不计 URL 或被 URL 去重的标识符。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let cs = (<bm-online>, <eb-zh>, <ds-zh>, <sw-zh>, <bm-zh>, <mk-usera>, <pid-all>)
#let one(name, cfg) = case(name, cfg, cites: cs, bib: mixed, full: false)
#one("缺省", gb7714.with())
#one("show-url: false（只隐藏 URL）", gb7714.with(show-url: false))
#one("show-url: \"online-only\"", gb7714.with(show-url: "online-only"))
#one("show-medium: false（只剩类型码，URL 照出）", gb7714.with(show-medium: false))
#one("show-url: false + show-pid: (rest: true)（PID 仍出）", gb7714.with(show-url: false, show-pid: (rest: true, doi: true)))
#one("dedup-url-pid: false（URL 与 DOI 都出）", gb7714.with(dedup-url-pid: false, show-pid: (rest: true, doi: true)))
#one("show-pid: (max: 1) + dedup（只统计实际著录的 PID）", gb7714.with(show-pid: (rest: true, doi: true, max: 1)))
#one("show-pid: (max: 1) + dedup-url-pid: false", gb7714.with(show-pid: (rest: true, doi: true, max: 1), dedup-url-pid: false))
#one("show-urldate: false（引用日期不出，URL 照出）", gb7714.with(show-urldate: false))
#one("三者全关", gb7714.with(show-url: false, show-medium: false, show-urldate: false, show-pid: (rest: false)))
