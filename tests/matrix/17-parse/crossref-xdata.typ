//! param: crossref / xdata 继承
//! values: crossref 继承出版项 · xdata 条目不进表
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "crossref / xdata", controls: "条目之间的字段继承。",
  expect: [`crossref = {母体键}`：本条缺的字段从母体继承（出版地 / 出版者 / 年 / 母体题名）。
    `xdata = {共享块键}`：从 `@xdata` 条目继承字段；**`@xdata` 条目本身不进文献表**
    （它不是文献，是一块共享字段）——`full: true` 也不出。
    ⚠️ 继承表只认*真名* `location`，不认别名 `address`——载入期的别名归一就是为了让
    `@proceedings{.., address={北京}}` 也能被继承到（否则会渲成「出版地不详」）。])
#case("crossref：会议论文从母体论文集继承出版项", gb7714.with(), bib: PARSE, full: true,
  bib-args: (keys: [@pa-crossref@pa-proc]))
#case("crossref + show-sine-loco: true（继承成功则不出占位）", gb7714.with(show-sine-loco: true, show-sine-nomine: true),
  bib: PARSE, full: true, bib-args: (keys: [@pa-crossref]))
#case("xdata：继承者出全，@xdata 条目本身不进表（full: true 也不出）", gb7714.with(), bib: PARSE, full: true,
  bib-args: (keys: [@pa-xdata-user], entry-type: ("book", "xdata")))
#case("xdata 继承 + 严格著录", gb7714.with(show-sine-loco: true, show-sine-nomine: true), bib: PARSE, full: true,
  bib-args: (keys: [@pa-xdata-user]))
