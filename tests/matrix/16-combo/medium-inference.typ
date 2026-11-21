//! param: show-medium × version × show-url × show-pid
//! values: 三版访问字段推导、显式载体优先、引用日期与CSTR不触发、筛选与显示独立
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "medium-inference", controls: "载体按数据推导，online-only保留原筛选范围。",
  expect: [显式载体优先。2005按URL、2015／2025按URL／DOI／eprint推导OL；不要求引用日期。
    仅引用日期或CSTR不推导OL。隐藏URL／PID不删除载体，online-only不因自动OL而放宽。])
#let DATA = bytes(read("/tests/_fixture/medium.bib"))
#let sample(caption, config, key) = case(caption, config, bib: DATA, cites: (label(key),), full: false)
#for year in (2005, 2015, 2025) {
  let prefix = str(year) + " · "
  sample(prefix + "URL，无引用日期", gb7714.with(version: year), "medium-url")
  sample(prefix + "仅DOI", gb7714.with(version: year), "medium-doi")
  sample(prefix + "仅eprint", gb7714.with(version: year), "medium-eprint")
  sample(prefix + "仅引用日期", gb7714.with(version: year), "medium-date")
  sample(prefix + "显式CD与访问字段", gb7714.with(version: year), "medium-cd")
  sample(prefix + "标识中的显式OL，无路径", gb7714.with(version: year), "medium-explicit")
  sample(prefix + "medium优先于标识载体段", gb7714.with(version: year), "medium-priority")
  sample(prefix + "仅CSTR", gb7714.with(version: year), "medium-cstr")
  sample(prefix + "隐藏路径与PID配额", gb7714.with(version: year, show-url: false, show-pid: (rest: false, max: 0)), "medium-issue")
}
