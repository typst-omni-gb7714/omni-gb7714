//! param: url-break-every
//! values: 1, none, int
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "url-break-every", controls: "长 URL 里每 N 个连续不可断字符后插入一个断点机会。",
  expect: [分隔符（`.` `/` `-` `_` `:` `;` `,` `?` `&` `=` `#` `+`）是 URL 的天然断点，本参数只作用于*其间的连续字母数字串*。
    `1`（缺省）：每个非分隔符字符后都插入断点，URL 任意位置可断行。
    `none`：不插入额外断点（长片段整体挪行，右边可能留大空档）。
    `<int>`：每 N 个字符一个断点机会。
    作用于 URL / DOI / CSTR / 自定义 PID（短号 ISBN / ISSN / eprint *不处理*）。
    ⚠️ 断点是零宽字符（`url-break-hyphen: false` 时为 U+200B），pdftotext 抽出来*看得见*
    ——golden 里 URL 字符之间那些不可见分隔就是断点。])
#let long = bytes("@online{u-long, author={甲}, title={长 URL}, url={https://example.com/a/very-long-endpoint-name-for-testing/resource?query=abcdefghijklmnopqrstuvwxyz&page=1}, urldate={2024-01-01}, year={2023}, langid={chinese}}")
#case("1（缺省）", gb7714.with(), bib: long, full: true)
#case("none（不插断点）", gb7714.with(url-break-every: none), bib: long, full: true)
#case("8（每 8 字符一个断点）", gb7714.with(url-break-every: 8), bib: long, full: true)
#case("1 · 作用于 DOI / CSTR", gb7714.with(show-pid: (rest: true, doi: true)), bib: EDGE, cites: (<pid-all>, <pid-isbn>), full: false)
#case("none · DOI / CSTR 也不断", gb7714.with(show-pid: (rest: true, doi: true), url-break-every: none), bib: EDGE, cites: (<pid-all>, <pid-isbn>), full: false)
