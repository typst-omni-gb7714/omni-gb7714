//! param: show-url × show-pid × show-medium × show-urldate
//! values: URL/PID独立、载体数据优先、去重、配额、内置与模板路径
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "access-independence", controls: "URL 筛选不抑制 PID，也不改变条目载体。",
  expect: [普通期刊只有 URL/DOI 不自动加 OL；显式 OL 在隐藏路径或 max:0 后仍保留。
    DOI true 不被 URL 筛选或去重抑制，但仍受 max 总额约束。auto 只与实际显示的 URL 去重。
    CD 文献不是联机；2005 §4.1.1 允许其著录已有引用日期，不因隐藏 URL 而删除。])
#let DATA = bytes(```bib
@article{hit-plain, author={Alpha, Alice}, title={Plain Link}, journaltitle={Journal},
  year={2020}, url={https://example.org/plain}, doi={10.1234/plain}}
@article{hit-online, author={Beta, Bob}, title={Online Version}, journaltitle={Journal},
  year={2021}, medium={OL}, url={https://example.org/online}, doi={10.1234/online}}
@article{hit-dup, author={Gamma, Grace}, title={DOI Link}, journaltitle={Journal},
  year={2022}, url={https://doi.org/10.1234/duplicate}, doi={10.1234/duplicate}}
@book{hit-cd, author={Delta, David}, title={Disc Edition}, medium={CD},
  publisher={Press}, year={2023}, urldate={2024-05-06}, url={https://example.org/disc}}
@article{hit-priority, author={Epsilon, Eva}, title={Identifier Priority}, journaltitle={Journal},
  medium={OL}, year={2024}, doi={10.1234/priority}, cstr={12345.67.priority}}
```.text)
#let sample(caption, config, key) = case(caption, config, bib: DATA, cites: (label(key),), full: false)
#sample("01 普通期刊：online-only 不抑制 DOI", gb7714.with(show-url: "online-only", show-pid: (doi: true)), "hit-plain")
#sample("02 普通期刊：false 同样保留 DOI", gb7714.with(show-url: false, show-pid: (doi: true)), "hit-plain")
#sample("03 普通期刊：true 显示链接，但不推导 OL", gb7714.with(show-url: true, show-pid: (doi: true)), "hit-plain")
#sample("04 显式 OL：关闭全部访问项仍保留载体", gb7714.with(show-url: false, show-pid: (rest: false)), "hit-online")
#sample("05 显式 OL：max:0 不改载体，也不被 doi:true 突破", gb7714.with(show-url: false, show-pid: (doi: true, max: 0)), "hit-online")
#sample("06 隐藏载体仍按联机属性筛选 URL", gb7714.with(show-medium: false, show-url: "online-only", show-pid: (rest: false)), "hit-online")
#sample("07 auto：显示 DOI URL 时去重", gb7714.with(show-url: true, show-pid: (doi: auto), dedup-url-pid: true), "hit-dup")
#sample("08 auto：隐藏 DOI URL 后不去重", gb7714.with(show-url: false, show-pid: (doi: auto), dedup-url-pid: true), "hit-dup")
#sample("09 true：URL 去重不抑制显式 DOI", gb7714.with(show-url: true, show-pid: (doi: true), dedup-url-pid: true), "hit-dup")
#sample("10 配额与优先级：两个 true 仍只输出 DOI", gb7714.with(show-url: false, show-pid: (doi: true, cstr: true, max: 1), pid-priority: ("doi", "cstr")), "hit-priority")
#sample("11 CD 引用日期与 URL 显示独立", gb7714.with(version: 2005, show-url: "online-only"), "hit-cd")
#sample("12 CD 日期可由自己的开关关闭", gb7714.with(version: 2005, show-url: "online-only", show-urldate: false), "hit-cd")
#sample("13 自定义模板共用载体与访问规则", gb7714.with(show-url: "online-only", show-pid: (doi: true), custom-drivers: (article: "<title><mark-medium>. <access>")), "hit-plain")
