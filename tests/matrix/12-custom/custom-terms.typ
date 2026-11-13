//! param: custom-terms
//! values: 注册新词（自创键）, 覆盖内置词（封闭集）, 字符串 / 多语言字典 / 单复数对
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-terms", controls: "自定义*本地化字面量* token —— 注册新词与覆盖内置词，二合一（键决定用途）。",
  expect: [值为字符串（语言无关）或多语言字典 `(zh: "见", en: "See")`——按*条目语言*取值，缺该语言时按字典*插入顺序*回退。
    - *注册新词*（键为自创名）：模板里写该键名即按条目语言渲染；
    - *覆盖内置词*（键 ∈ 封闭集 `et-al` / `editor` / `translator` / `anon` / `no-date` / `sine-loco` /
      `sine-nomine` / `ma-thesis` / `phd-thesis` / `edition` / `volume` / `pages` / `ibid` / `footnote-number`）：
      改的是内置词本身，*不需要模板*也生效。
    *单复数对*：值在语言键之下、词原值之上可以再插一层 ```typc (singular: .., plural: ..)```，
    一条规则通吃裸串词（`editor`）与前后缀对词（`volume` / `pages`）。数量由数据自己定——
    页码看区间与段数（判据照抄上游 hayagriva，见 `tests/unit/pages-plural.typ`）、卷次看是不是多卷、
    编者看人数。判据是「有没有那两个键」，与 `ibid` 的 `(text:, supplement-separator:)`、
    `edition` / `volume` 的 `(prefix:, suffix:)` 同一套。
    `pages` 是*为此新增的键*：GB 的页码前不出标签词，内置默认全语言空串，只为覆写而设——
    不配它，输出一字不变。
    带字段的 token 用 `custom-fields`，永久标识符用 `custom-pids`（放错篮子会 panic 引导过去）。
    ⚠️ Typst 没有 warning API：内置词键*拼错*（`et-la`）只会被当成「注册了个没人引用的死 token」*静默无效*。])
#let cs = (<bm-zh>, <bm-en>, <ic-zh>, <bm-noauthor>, <im-nopub>)
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let one(name, cfg) = case(name, cfg, cites: cs, bib: mixed, full: false)
#one("(:)（缺省）", gb7714.with(show-anon: true, show-sine-loco: true, show-sine-nomine: true))
#one("覆盖内置词 et-al：(en: \"et al\")（无点）", gb7714.with(custom-terms: (et-al: (en: "et al"))))
#one("覆盖内置词 editor / translator：(zh: \"编\") / (zh: \"译\")", gb7714.with(custom-terms: (editor: (zh: "编"), translator: (zh: "译"))))
#one("覆盖内置词 anon：(zh: \"无名氏\", en: \"Anonymous\")", gb7714.with(show-anon: true, custom-terms: (anon: (zh: "无名氏", en: "Anonymous"))))
#one("覆盖内置词 sine-loco / sine-nomine", gb7714.with(show-sine-loco: true, show-sine-nomine: true,
  custom-terms: (sine-loco: (zh: "〔出版地不详〕"), sine-nomine: (zh: "〔出版者不详〕"))))
#one("覆盖内置词 edition / volume（两槽 prefix / suffix）", gb7714.with(custom-terms: (edition: (zh: (prefix: "第", suffix: " 版")), volume: (zh: (prefix: "卷 ", suffix: "")))))
#one("覆盖内置词 ma-thesis / phd-thesis", gb7714.with(show-degree: true, custom-terms: (phd-thesis: (zh: "博士论文"), ma-thesis: (zh: "硕士论文"))))
#one("字符串值（语言无关，中西一视同仁）", gb7714.with(custom-terms: (et-al: "＆c.")))
#one("注册新词 + 模板引用：in-proc", gb7714.with(
  custom-terms: (in-proc: (zh: "见", en: "In:")),
  custom-drivers: (incollection: "creator . titles . in-proc booktitles . publisher , year")))
#one("注册新词 · 多语言按条目语言取（en 条目走 en 键）", gb7714.with(
  custom-terms: (see-tag: (zh: "【中】", en: "[EN]")),
  custom-drivers: (book: "see-tag creator . titles")))
#one("注册新词 · 缺该语言时按插入顺序回退（只给 ja）", gb7714.with(
  custom-terms: (see-tag: (ja: "【JA】")),
  custom-drivers: (book: "see-tag creator . titles")))
#one("拼错的内置词键静默无效：et-la（注意 et al. 没变）", gb7714.with(custom-terms: (et-la: (en: "WRONG"))))
// 单复数：芝加哥式 p./pp.、vol./vols.、ed./eds.（GB 侧不配就一字不变）
#let PL = bytes("@article{pl1, author={Doe, Jane}, title={T}, journal={J}, year={2020}, volume={5}, pages={12--18}, langid={english}}
@article{pl2, author={Roe, Rick}, title={U}, journal={J}, year={2021}, volume={6}, pages={42}, langid={english}}
@book{pl3, author={Ao, Al}, editor={Doe, Jane}, title={V}, publisher={P}, address={X}, year={2022}, langid={english}}
@book{pl4, author={Bo, Bill}, editor={Doe, Jane and Roe, Rick}, title={W}, publisher={P}, address={X}, year={2023}, volume={3-5}, langid={english}}
@book{pl5, author={张三}, editor={乙 and 丙}, title={题}, publisher={社}, address={京}, year={2024}, pages={12-25}, langid={chinese}}")
#let plural-case(name, cfg) = case(name, cfg, cites: (), bib: PL, full: true)
#plural-case("缺省（不配单复数对）：GB 输出一字不变，页码前无标签词", gb7714.with())
#plural-case("pages / volume / editor 三个词各配单复数对", gb7714.with(custom-terms: (
  pages: (en: (singular: (prefix: "p. "), plural: (prefix: "pp. "))),
  volume: (en: (singular: (prefix: "vol. "), plural: (prefix: "vols. "))),
  editor: (en: (singular: "ed.", plural: "eds.")))))
#plural-case("单复数对不分语言（值本身就是那一对，全语言通用）", gb7714.with(custom-terms: (
  editor: (singular: "ed.", plural: "eds."))))
#plural-case("只写一支：缺的那支回退到写了的那支", gb7714.with(custom-terms: (
  pages: (en: (plural: (prefix: "pp. "))))))
