//! param: url-break-hyphen-at-delimiters
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "url-break-hyphen-at-delimiters", controls: "显连字符时，软连字符是否也出现在 URL *分隔符*的断点处。",
  expect: [与 `url-break-hyphen` 正交：`true`（缺省）分隔符断点（`: / ? # [ ] @ ! $ & ' ( ) * + , ; =`）也显 `-`；
    `false` 分隔符断点不显 `-`，只有 `url-break-every` 插入的*长串救济断点*显 `-`。
    三项正交：`url-break-every` 定在哪里断、`url-break-hyphen` 定断处是否显 `-`、本项定分隔符断点是否计入。
    `url-break-hyphen: false` 时本项*无影响*（下方第三块与第一块的对照）。])
#let long = bytes("@online{u-d, author={甲}, title={分隔符密集的长 URL}, url={https://example.com/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z/end}, urldate={2024-01-01}, year={2023}, langid={chinese}}")
#case("true（缺省）+ url-break-hyphen: true", gb7714.with(url-break-hyphen: true), bib: long, full: true)
#case("false + url-break-hyphen: true（分隔符处不显 -）", gb7714.with(url-break-hyphen: true, url-break-hyphen-at-delimiters: false), bib: long, full: true)
#case("false + url-break-hyphen: false（本项无影响）", gb7714.with(url-break-hyphen-at-delimiters: false), bib: long, full: true)
