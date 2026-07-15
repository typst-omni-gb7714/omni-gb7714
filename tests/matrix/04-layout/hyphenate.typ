//! param: hyphenate
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "hyphenate", controls: "文献表内西文是否允许连字断词。",
  expect: [`true`（缺省）：长西文词可断行并补连字符。`false`：不断词（长词整体挪行，行右可能留大空档）。
    只管*词内*断行；URL 的断行是另一套（`url-break-every` / `url-break-hyphen`）。])
#let narrow = (
  entry-hanging-indent: 0pt,
)
#case("true（缺省）", gb7714.with(), cites: (<aj-en>, <bm-en>), full: false)
#case("false", gb7714.with(hyphenate: false), cites: (<aj-en>, <bm-en>), full: false)
