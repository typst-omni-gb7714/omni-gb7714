//! param: pid-colon-style
//! values: auto | "half" | "half-with-space" | "full" | "by-doc-*" | "by-entry-*"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "pid-colon-style", controls: "永久标识符（DOI / CSTR / eprint 及自定义 PID）标签与值之间那*一个*冒号的全 / 半角风格，独立于结构冒号（出版项 `出版地：出版者`、页码定位 `年：页`）。取值同 `bib-punct-style`。",
  expect: [只作用于 PID 标签后那个冒号，其余冒号（出版项、年:页）不动：

    - `auto`（默认）：跟随 `bib-punct-style`——2025 中文条目部分全角 → 全角 `DOI：`（恒不带尾空格），并尊重 `custom-punct` 对 `colon` 的覆写。即历史行为。
    - `"half"`：半角无空格 `DOI:10.1234/example`。
    - `"half-with-space"`：半角加空格 `DOI: 10.1234/example`。
    - `"full"`：全角 `DOI：10.1234/example`。
    - 非 `auto` 时*绕过* `custom-punct` 的 `colon` 覆写（专用旋钮更具体、优先）；结构冒号仍随 `custom-punct` / `bib-punct-style`。
    - `by-doc-*` 按文档语言、`by-entry-*` 按条目语言定全 / 半角（此处中文条目→全角）。])

#let cs = (<pid-all>,)
#let show-both = (rest: true, doi: true, cstr: true)
#case("auto（默认，2025 中文条目 → 全角 DOI：/CSTR：）", gb7714.with(version: 2025, show-pid: show-both), bib: EDGE, cites: cs, full: false)
#case("\"half\"：DOI:10… / CSTR:32003…（结构冒号仍全角）", gb7714.with(version: 2025, show-pid: show-both, pid-colon-style: "half"), bib: EDGE, cites: cs, full: false)
#case("\"half-with-space\"：DOI: 10…", gb7714.with(version: 2025, show-pid: show-both, pid-colon-style: "half-with-space"), bib: EDGE, cites: cs, full: false)
#case("\"full\"：强制全角（半角文档档下仍全角）", gb7714.with(version: 2015, show-pid: show-both, pid-colon-style: "full"), bib: EDGE, cites: cs, full: false)
#case("2015 半角文档 + auto（跟随 → 半角）对照 \"half\" 顶替 custom-punct 全角冒号", gb7714.with(version: 2015, show-pid: show-both), bib: EDGE, cites: cs, full: false)
#case("custom-punct 全角冒号 + pid-colon-style: \"half\"（PID 冒号半角、出版项冒号仍全角）", gb7714.with(version: 2015, show-pid: show-both, custom-punct: (":": "："), pid-colon-style: "half"), bib: EDGE, cites: cs, full: false)
