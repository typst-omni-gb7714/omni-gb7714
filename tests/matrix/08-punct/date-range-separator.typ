//! param: date-range-separator
//! values: auto, string, dictionary, verbatim, empty string, bibliography override
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "date-range-separator", controls: "结构化日期区间两个端点之间的连接符。",
  expect: [默认 `auto` 保留 `—`；显式字符串和语言字典可覆盖。闭区间、开放起点和开放终点均使用同一设置，年月日内部连字符不变。
    内置格式、模板、完整引用和脚注共用规则。`urldate` 仍显示一个端点；出版年、页码和连续出版物年卷期块不受影响。])
#let bib = bytes(read("/tests/_fixture/date-ranges.bib"))
#let ranges = (<dr-day>, <dr-after>, <dr-before>, <dr-month>, <dr-year>, <dr-mixed>, <dr-single>, <dr-uncertain>)
#let one(name, value, ..args) = case(name, gb7714.with(date-range-separator: value), bib: bib, cites: ranges, full: false, ..args)
#one("auto · 保留默认破折号", auto)
#one("字符串 / · 开闭区间均替换", "/")
#one("字符串 至 · 端点内部仍为 YYYY-MM-DD", " 至 ")
#one("verbatim {/} · 不印花括号", "{/}")
#one("空字符串 · 显式不留连接符", "")
#case("单字符标点 · 随标点档转换", gb7714.with(date-range-separator: ",", bib-punct-style: "full"),
  bib: bib, cites: (<dr-day>,), full: false)
#case("verbatim {,} · 保留半角逗号", gb7714.with(date-range-separator: "{,}", bib-punct-style: "full"),
  bib: bib, cites: (<dr-day>,), full: false)
#case("连接符的 custom-punct 样式", gb7714.with(date-range-separator: "/", custom-punct: ("/": (text: "/", weight: "bold"))),
  bib: bib, cites: (<dr-day>,), full: false)
#case("语言字典 · 中文破折号／英文斜杠", gb7714.with(date-range-separator: (zh: "—", en: "/")),
  bib: bib, cites: (<dr-zh>, <dr-day>), full: false)
#case("语言字典 · 未列出的语言用预设", gb7714.with(date-range-separator: (zh: "/")),
  bib: bib, cites: (<dr-zh>, <dr-day>), full: false)
#case("语言字典 rest · 未列出的语言用指定值", gb7714.with(date-range-separator: (zh: "—", rest: "/")),
  bib: bib, cites: (<dr-zh>, <dr-day>), full: false)
#case("逐表覆盖 · 全局斜杠／本表破折号", gb7714.with(date-range-separator: "/"),
  bib: bib, cites: (<dr-day>, <dr-after>, <dr-before>), full: false, bib-args: (date-range-separator: "—"))
#case("逐表 auto · 继承全局斜杠", gb7714.with(date-range-separator: "/"),
  bib: bib, cites: (<dr-day>,), full: false, bib-args: (date-range-separator: auto))
#case("内置各日期位置", gb7714.with(date-range-separator: "/"), bib: bib,
  cites: (<dr-book>, <dr-article>, <dr-news>, <dr-patent>, <dr-archive>, <dr-report>, <dr-dataset>, <dr-preprint>), full: false)
#case("模板 date／imprint-block／内置回落", gb7714.with(date-range-separator: "/",
  custom-drivers: (online: "title { | } date { | } urldate", report: "title { | } imprint-block", newspaper: "built-in")),
  bib: bib, cites: (<dr-day>, <dr-after>, <dr-before>, <dr-report>, <dr-news>), full: false)
#case("旧版 2005 · 修改日期使用同一连接符", gb7714.with(version: 2005, date-range-separator: "/"),
  bib: bib, cites: (<dr-day>, <dr-news>), full: false)
#case("旧版 2015 · 修改日期使用同一连接符", gb7714.with(version: 2015, date-range-separator: "/"),
  bib: bib, cites: (<dr-day>, <dr-news>), full: false)
#case("不改变出版年／页码／整刊年卷期块", gb7714.with(date-range-separator: "/"),
  bib: bib, cites: (<dr-book>, <dr-serial>), full: false)
#case("不把推定年用作修改日期", gb7714.with(date-range-separator: "/", date-fallback: "urldate"),
  bib: bib, cites: (<dr-inferred>,), full: false)
#case("不改变字面日期回退", gb7714.with(date-range-separator: "/"),
  bib: bib, cites: (<dr-literal-report>,), full: false)
