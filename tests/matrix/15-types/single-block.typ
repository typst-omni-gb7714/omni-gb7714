//! param: 单块退化（判据 = 条目提供的数据元素组数；show-end-period 默认 auto 去点、show-mark 默认 true 留码）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "单块退化", controls: "当一条著录只提供*一组*著录数据元素时的收敛：`show-end-period: auto`（默认）不补末尾句点；`show-mark` 默认 `true`（单块仍留类型码，对齐 §7.3），显式 `show-mark: auto` 才在单块时去码。判据落在*条目提供的数据元素组数*（责任者 / 题名 / 版本 / 出版 / 丛书 / 获取 / 标识），*不是渲染出的块数*——标准（§8.9.2）格式精简成一块但数据多组，不误退化。",
  expect: [语料取自 GB/T 7714—2025 §7 各著录元素的单元素演示片段 + §8.9 标准（`gb7714-bench`）。

    - *默认*（`show-end-period: auto` + `show-mark: true`）：`李时珍`（仅责任者一组，无末点）、`《西游记》…[M]`（仅题名一组，无末点、留 \[M\]）、`新 1 版`（仅版本组）——单块退化。
    - *标准*（§8.9.2，`国家能源局` + `NB/T 10386—2020` + 题名 + 日期）：格式精简只渲染 `编号 名称[S]` 一块，但*提供*了责任者、题名、出版三组数据（`m ≥ 2`）→ *不退化* → `…[S].` *有末点*，对齐国标 §8.9.2 原文（区别于 §7.3 只有名称、无编号的演示片段 `马寅初讲义[M]` 无末点）。
    - *多块*：责任者+题名+出版（`m ≥ 2`）→ 出 \[M\] 与末点。
    - *`show-mark: auto`*：单块时题名块也去码。
    - *`show-end-period: true`*：单块也补末点。两参数正交。])

#let eb = bytes("@book{a1, author={{李时珍}}, langid={pinyin}}
@book{a2, langid={pinyin}, title={《西游记》词汇对《汉语大词典》书证研究}}
@book{a5, edition={新1版}, langid={pinyin}}
@standard{std, author={{国家能源局}}, date={2020-10-23}, langid={chinese}, number={NB/T 10386---2020}, title={水电工程水温实时监测系统技术规范}, type={行业标准}}
@book{demo, langid={pinyin}, title={马寅初讲义}}
@book{multi, author={张三}, title={完整多块著录}, location={北京}, publisher={某社}, date={2020}, langid={chinese}}")

#case("默认：单元素片段无末点、标准(数据多组)有末点、多块有码有点", gb7714.with(version: 2025), bib: eb, cites: (<a1>, <a2>, <a5>, <std>, <demo>, <multi>), full: true)
#case("show-mark: auto：单块题名块去码", gb7714.with(version: 2025, show-mark: auto), bib: eb, cites: (<a2>, <demo>, <multi>), full: true)
#case("show-end-period: true：单块也补末点", gb7714.with(version: 2025, show-end-period: true), bib: eb, cites: (<a1>, <a2>, <multi>), full: true)
