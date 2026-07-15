//! param: dedup-url-pid
//! values: auto, true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "dedup-url-pid", controls: "标识符已被 URL 承载时，是否不重复著录（GB/T 7714—2025 允许）。",
  expect: [`true`（= `auto` 缺省）：双重检测，命中任一即抑制该标识符——
    ①*值匹配*：URL 子串含该标识符的字面值（`https://doi.org/10.1234/abc` 含 `10.1234/abc`）；
    ②*类型标记匹配*（小写）：URL 含该标识符的形态特征（`doi.org/`、`cstr.cn/`、`arxiv.org/`、`isbn:`、`issn:`；
    自定义标识符按 `<prefix 或 bib-field>:` 派生）。
    `false`：关闭去重，标识符不论 URL 内容一律独立输出。
    `show-pid` 里显式置 `true` 的标识符*总是强制显示*，本参数只影响 `auto` 状态者。
    语料 `pid-all` 的 URL 正是 `https://doi.org/10.1234/example`——值与类型标记*双双命中*。])
#let cs = (<pid-all>, <bm-online>)
#let m = bytes(read("/tests/_fixture/main.bib")) + bytes(read("/tests/_fixture/edge.bib"))
#case("auto（缺省 → true，DOI 被 URL 承载 → 不重复著录）", gb7714.with(show-pid: (doi: auto)), bib: m, cites: cs, full: false)
#case("false（关闭去重，DOI 独立输出）", gb7714.with(show-pid: (doi: auto), dedup-url-pid: false), bib: m, cites: cs, full: false)
#case("true + show-pid: (doi: true)（显式 true 强制直通，去重不生效）", gb7714.with(show-pid: (doi: true)), bib: m, cites: cs, full: false)
#case("false + max: 1（去重关 → URL 承载的标识符不再计入配额）", gb7714.with(show-pid: (rest: true, doi: true, max: 1), dedup-url-pid: false), bib: m, cites: cs, full: false)
