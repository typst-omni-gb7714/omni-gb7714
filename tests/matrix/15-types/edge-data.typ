//! param: 边角数据（edge.bib 全表）
//! values: 姓名 / 题名 / 出版项 / 卷期页 / 日期 / 结构 / PID / 取码链
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "边角数据全表", controls: "`edge.bib` 整表——每条都是一个边角。",
  expect: [七组边角：
    *姓名*（前缀 van der / 世系后缀 Jr. / 连字名 / `and others` / 机构 / 只有编者 / 译者 /
    扩展人名格式 / 同责任者同年 / 同姓不同人 / 同责任者无年）；
    *题名*（多卷书 / 丛书 / 其他题名信息 / 无题名 / 题名内含标点）；
    *出版项*（缺出版者 / 缺出版地 / 用户手写占位符）；
    *卷期页*（无期号 / 无卷号 / 网络首发 / 文章编号 / 期号是字符串 / 页码范围）；
    *日期*（EDTF / 日期区间）；
    *结构*（`@set` 成员与主条目 / 双语关联 / 关键词 / 注释）；
    *PID*（DOI+CSTR+URL 齐备 / eprint / ISBN）；
    *取码链*（`usera` / `entrytypeid` / `mark` / `entrysubtype` / 无线索）。
    取码链的优先级：note 劫持 > `usera` > `entrytypeid` > `entrysubtype` > `mark` 字段 >
    `custom-marks` > 版本化默认 > auto-table。])
#case("2025 · 顺序编码制（缺省）", gb7714.with(), bib: EDGE, full: true)
#case("2025 · 著者-出版年制", gb7714.with(style: "author-date"), bib: EDGE, full: true)
#case("2015 · 顺序编码制", gb7714.with(version: 2015), bib: EDGE, full: true)
#case("2025 · 严格著录（占位符全开 + 全部 PID + 学位注记 + 丛书）", gb7714.with(
  show-anon: true, show-no-date: true, show-sine-loco: true, show-sine-nomine: true,
  show-pid: (rest: true, doi: true), show-degree: true, show-series: true, show-patent-country: true), bib: EDGE, full: true)
