//! param: 文献类型标识码（附录 A 全表）
//! values: M J N C D R S P EB A CM DS CP DB PP G Z × 三个版本
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "文献类型标识码 × 版本", controls: "每个标识码各一条，逐版本看著录格式串。",
  expect: [GB/T 7714 附录 A 的标识码全表。同一条数据在 2025 / 2015 / 2005 三个版本下的*码*与*格式串*
    都可能不同——版本差异集中在这里：
    - *2005*：全部永久标识符关闭；专利不出专利国；档案 / 数据集 / 地图 / 预印本一律 `[Z]` 兜底、其余 `[M]`；
    - *2015*：预印本落 `[A]`（无 PP 码）；CSTR 默认关；
    - *2025*：新增 `PP`（预印本）；CSTR 默认开。
    这张表是「码即身份」的证据：拿到码就按码路由进对应的内置驱动。])
#case("version: 2025（缺省）", gb7714.with(), bib: TYPES, full: true)
#case("version: 2015", gb7714.with(version: 2015), bib: TYPES, full: true)
#case("version: 2005", gb7714.with(version: 2005), bib: TYPES, full: true)
#case("2025 · 著者-出版年制", gb7714.with(style: "author-date"), bib: TYPES, full: true)
#case("2025 · 全部 PID 打开（show-pid: (rest: true)）", gb7714.with(show-pid: (rest: true, doi: true)), bib: TYPES, full: true)
