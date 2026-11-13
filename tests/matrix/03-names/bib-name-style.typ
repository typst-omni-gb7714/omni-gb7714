//! param: bib-name-style
//! values: auto, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-name-style", controls: "文献表里西文姓名的格式（八维字典）。",
  expect: [`auto` 缺省：GB 形态——姓全著、首字母大写，名缩写为首字母且不加缩写点（§7.1）。
    八维可逐维覆盖，语义同 `cite-name-style`。条目级 `nameformat` 字段优先于本参数（混合语料逐条标）。])
#let cs = (<nm-prefix>, <nm-suffix>, <nm-hyphen>, <nm-nameformat>)
#case("auto（缺省）", gb7714.with(bib-et-al-min: 999), bib: EDGE, cites: cs, full: false)
#case("given-form: full", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "full")), bib: EDGE, cites: cs, full: false)
#case("given-form: none（只姓）", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: none)), bib: EDGE, cites: cs, full: false)
#case("order: given-ahead", gb7714.with(bib-et-al-min: 999, bib-name-style: (order: "given-ahead", given-form: "full")), bib: EDGE, cites: cs, full: false)
#case("order 字典 (first:, rest:)", gb7714.with(bib-et-al-min: 999, bib-name-style: (order: (first: "family-ahead", rest: "given-ahead"), given-form: "full")), bib: EDGE, cites: cs, full: false)
#case("family-case: uppercase / lowercase / none", gb7714.with(bib-et-al-min: 999, bib-name-style: (family-case: "lowercase")), bib: EDGE, cites: cs, full: false)
#case("given-initial-separator: 「.」", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "initials", given-initial-separator: ".")), bib: EDGE, cites: cs, full: false)
#case("given-separator + given-case", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "full", given-separator: "-", given-case: "capitalize-first")), bib: EDGE, cites: cs, full: false)
#case("family-given-separator + given-family-separator", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "full", family-given-separator: "、", given-family-separator: "‧")), bib: EDGE, cites: cs, full: false)

// given-form 拼音感知（§7.1.1「拉丁化中文名保留全拼」）：仅 2025 默认检测，2015/2005 不变。
#let PY = bytes("@book{py1, author={Li, Jiangning}, title={T}, publisher={P}, location={L}, date={2020}, langid={american}}
@book{py2, author={Smith, John Paul}, title={T}, publisher={P}, location={L}, date={2020}, langid={american}}
@book{py3, author={Wang, Ming and Smith, John}, title={T}, publisher={P}, location={L}, date={2020}, langid={american}}
@book{py4, author={Ouyang, Xiu and Sima, Qian}, title={T}, publisher={P}, location={L}, date={2020}, langid={american}}")
#case("拼音感知 2025 缺省：拼音名全拼(Li Jiangning)、西文缩(Smith J P)、逐名分(Wang Ming／Smith J)", gb7714.with(bib-et-al-min: 999), bib: PY, cites: (<py1>, <py2>, <py3>), full: true)
#case("2015：拼音名逐音节缩(Li J N)、西文缩首字母(Wang M)——对齐李泽平 initializepinyin 默认", gb7714.with(version: 2015, bib-et-al-min: 999), bib: PY, cites: (<py1>, <py3>), full: true)
#case("显式 given-form: initials(2025)——关掉检测，拼音名也缩(Li J)", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: "initials")), bib: PY, cites: (<py1>,), full: true)
#case("显式字典 (pinyin: initials, rest: full)——反着来:拼音缩、西文全拼", gb7714.with(bib-et-al-min: 999, bib-name-style: (given-form: (pinyin: "initials", rest: "full"))), bib: PY, cites: (<py1>, <py2>), full: true)
#case("复姓(2025)：欧阳修 Ouyang Xiu / 司马迁 Sima Qian 全拼(复姓静态表,非单音节)", gb7714.with(bib-et-al-min: 999), bib: PY, cites: (<py4>,), full: true)
