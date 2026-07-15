//! param: pid-priority
//! values: array（残缺名次表）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "pid-priority", controls: "永久标识符的渲染优先级（残缺名次表）。",
  expect: [数组内的标识符按数组顺序优先渲染；未列出者按 `show-pid` 插入顺序、内置默认顺序
    （doi / cstr / isbn / issn / eprint）、`custom-terms` 插入顺序补齐。
    与 `show-pid.max` 配合：`max: 1` 时「第一个」= 本次序下*首个能著录*的标识符——被 URL 去重压下的不算，
    获取和访问路径（§7.8 的著录项目）也不占 PID 的配额。
    *缺省就是完整的链* `("cstr", "doi", "eprint", "isbn", "issn")`——你看到的就是全部次序，没有藏在
    别处的补齐规则；它同时是*残缺名次表*的补齐序（写 `("issn",)` 只是把 ISSN 提到最前，其余仍按缺省链跟上）。
    所以 `()`（不点名任何）与缺省*等价*。
    *次序只看本参数*：`show-pid` 是开关，它的书写顺序不影响次序。
    不必随版本变：2015 版的 CSTR 由 `show-pid` 默认关掉，排在次序里也不会印。
    *国标没有规定 PID 之间的次序*——§7.9 全文只有两条（7.9.1 路径含 PID 时可不重复著录、7.9.2 不含时
    可按原文如实著录），既无数量上限也无优先级，缺省值是本包的取舍。])
#let cs = (<pid-all>, <pid-isbn>)
#let all = (rest: true, doi: true)
#case("缺省 (\"cstr\", \"doi\")（CSTR 先——它是国家标准的永久标识符）", gb7714.with(show-pid: all), bib: EDGE, cites: cs, full: false)
#case("`()`（不点名任何标识符 → 全部按缺省链补齐，与缺省等价）", gb7714.with(show-pid: all, pid-priority: ()), bib: EDGE, cites: cs, full: false)
#case(`("cstr", "doi")`.text + "（CSTR 恒先于 DOI）", gb7714.with(show-pid: all, pid-priority: ("cstr", "doi")), bib: EDGE, cites: cs, full: false)
#case(`("isbn",)`.text + "（ISBN 提到最前，其余按内置序补齐）", gb7714.with(show-pid: all, pid-priority: ("isbn",)), bib: EDGE, cites: cs, full: false)
#case(`("cstr", "doi")`.text + " + max: 1（首个有值者 = CSTR）", gb7714.with(show-pid: (rest: true, doi: true, max: 1), pid-priority: ("cstr", "doi")), bib: EDGE, cites: cs, full: false)
#case(`("doi", "cstr")`.text + " + max: 1（首个有值者 = DOI）", gb7714.with(show-pid: (rest: true, doi: true, max: 1), pid-priority: ("doi", "cstr")), bib: EDGE, cites: cs, full: false)
