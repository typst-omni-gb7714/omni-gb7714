//! param: .bib 条目类型 → 驱动路由
//! values: 八大类型 × 中/英 × 边角（缺年 / 缺责任者 / 有 URL）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: ".bib 条目类型 × 驱动", controls: "主语料全表：八大类型 × 中英 × 有无年 / 责任者 / 获取路径。",
  expect: [`main.bib` 是矩阵绝大多数用例的共享底本，本文件把它*整表*渲出来当基准像：
    专著 / 期刊 / 析出 / 会议 / 学位 / 报告 / 标准 / 专利 / 报纸 / 网页 / 数据集 / 计算机程序，
    每类都有中文条目，专著与期刊另有英文对照，另有缺责任者、缺出版年、带获取路径三条边角。
    两制 × 三版本各出一遍——*任何格式串的改动都会在这张表上留下痕迹*。])
#case("2025 · 顺序编码制（缺省）", gb7714.with(), full: true)
#case("2025 · 著者-出版年制", gb7714.with(style: "author-date"), full: true)
#case("2015 · 顺序编码制", gb7714.with(version: 2015), full: true)
#case("2015 · 著者-出版年制", gb7714.with(version: 2015, style: "author-date"), full: true)
#case("2005 · 顺序编码制", gb7714.with(version: 2005), full: true)
#case("2005 · 著者-出版年制", gb7714.with(version: 2005, style: "author-date"), full: true)
