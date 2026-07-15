//! param: cite-compress-min
//! values: 2, 3, 999
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-compress-min", controls: "顺序编码制下，连续编号压缩成区间的最小长度。",
  expect: [缺省 `2`：连续 2 个及以上压成 `[1-3]`。设 `3` 则 2 个连号不压（`[1,2]`）、3 个才压。
    设 `999` 等于关闭压缩，全部逐个列出。])
#let five = [正文 #cite(<bm-zh>)#cite(<bm-en>)#cite(<bm-noauthor>)#cite(<aj-zh>)。]
#cite-only("2（缺省）", gb7714.with(), body: five)
#cite-only("3", gb7714.with(cite-compress-min: 3), body: five)
#cite-only("999（关闭压缩）", gb7714.with(cite-compress-min: 999), body: five)
