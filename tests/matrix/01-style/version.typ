//! param: version
//! values: 2005, 2015, 2025
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "version", controls: "GB/T 7714 的版本。",
  expect: [三个版本各有著录差异：2025 标点部分全角、报告编号入题名槽、专利有引文页码、预印本码 PP；
    2015 无 PP（预印本归 A）、专利无页码；2005 全部 PID 关闭、专利著国别、多类型兜底 [Z]。
    非法值回落缺省 2025（既有宽容语义）。])
#case("2005", gb7714.with(version: 2005), bib: TYPES)
#case("2015", gb7714.with(version: 2015), bib: TYPES)
#case("2025（缺省）", gb7714.with(version: 2025), bib: TYPES)
#case("非法值 2016 → 回落 2025", gb7714.with(version: 2016), bib: TYPES)
