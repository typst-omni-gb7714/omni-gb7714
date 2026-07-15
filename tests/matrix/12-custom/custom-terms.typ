//! param: custom-terms
//! values: 注册新词（自创键）, 覆盖内置词（封闭集）, 字符串 / 多语言字典
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-terms", controls: "自定义*本地化字面量* token —— 注册新词与覆盖内置词，二合一（键决定用途）。",
  expect: [值为字符串（语言无关）或多语言字典 `(zh: "见", en: "See")`——按*条目语言*取值，缺该语言时按字典*插入顺序*回退。
    - *注册新词*（键为自创名）：模板里写该键名即按条目语言渲染；
    - *覆盖内置词*（键 ∈ 封闭集 `et-al` / `editor` / `translator` / `anon` / `no-date` / `sine-loco` /
      `sine-nomine` / `ma-thesis` / `phd-thesis` / `edition` / `volume` / `ibid` / `footnote-number`）：
      改的是内置词本身，*不需要模板*也生效。
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
  custom-drivers: (incollection: "author . title . in-proc booktitle . publisher , year")))
#one("注册新词 · 多语言按条目语言取（en 条目走 en 键）", gb7714.with(
  custom-terms: (see-tag: (zh: "【中】", en: "[EN]")),
  custom-drivers: (book: "see-tag author . title")))
#one("注册新词 · 缺该语言时按插入顺序回退（只给 ja）", gb7714.with(
  custom-terms: (see-tag: (ja: "【JA】")),
  custom-drivers: (book: "see-tag author . title")))
#one("拼错的内置词键静默无效：et-la（注意 et al. 没变）", gb7714.with(custom-terms: (et-la: (en: "WRONG"))))
