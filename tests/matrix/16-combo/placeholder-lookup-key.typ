//! combo: show-anon × show-no-date × disambiguate × 排序 × cite-terms-lang
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：占位词是查找键", controls: "佚名 / 无日期两个占位词牵动标注、著录、排序、消歧四处。",
  expect: [占位词是*查找键*——读者拿标签「(责任者, 年份)」在*按责任者字顺排*的表里定位。因此：
    *两侧必须同源*（行内 `佚名` / 表里 `Anon` 会让读者找不到）；
    *排序键 = 责任者位实际显示的内容*（`show-anon: true` → 按占位词排；`false` → 顺延题名）；
    *消歧后缀*：有年 `2020a` 直接贴；无年 `无日期-a` 用*连字符*（官方 GB CSL 里显式的 `<group delimiter="-">`）；
    *末句点去重*：`n.d.` 的缩写点兼作责任者元素后的句点，不叠成 `n.d..`。
    `show-anon` / `show-no-date` 的 `auto` = 著者-出版年制出、顺序编码制留空。
    `cite-terms-lang` 只动*正文标注*那一侧的取词语言，著录侧硬性跟条目语言——
    它是逃生舱，*默认两侧同源*（345 个国标 CSL 里让两侧不一致的：0 个）。])
#let mixed = bytes(read("/tests/_fixture/lang.bib") + read("/tests/_fixture/edge.bib"))
#let cs = (<lg-noauthor-zh>, <lg-noauthor-en>, <lg-noyear-zh>, <lg-noyear-en>, <nm-noyear-a>, <nm-noyear-b>)
#let one(name, cfg) = case(name, cfg, cites: cs, bib: mixed, full: false)
#one("auto × 顺序编码制（两个占位词都不出）", gb7714.with())
#one("auto × 著者-出版年制（两个占位词都出）", gb7714.with(style: "author-date"))
#one("show-anon: true × 顺序编码制（只出佚名）", gb7714.with(show-anon: true))
#one("show-anon: false × 著者-出版年制（排序顺延题名）", gb7714.with(style: "author-date", show-anon: false))
#one("show-no-date: false × 著者-出版年制", gb7714.with(style: "author-date", show-no-date: false))
#one("消歧后缀：无年用连字符（无日期-a / n.d.-a）", gb7714.with(style: "author-date", disambiguate: true))
#one("disambiguate: false（撞车不管）", gb7714.with(style: "author-date", disambiguate: false))
#one("custom-terms 改占位词（两侧同步改）", gb7714.with(style: "author-date", custom-terms: (anon: (zh: "无名氏", en: "Anonymous"), no-date: (zh: "无出版年", en: "no date"))))
#one("cite-terms-lang: \"zh\"（只动标注侧，著录侧不动）", gb7714.with(style: "author-date", cite-terms-lang: "zh"))
#one("cite-terms-lang: (anon: \"en\")（逐词指定）", gb7714.with(style: "author-date", cite-terms-lang: (anon: "en")))
