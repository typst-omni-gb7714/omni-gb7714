//! param: CSL JSON 输入（Zotero / Better BibTeX / Pandoc 导出）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "CSL JSON 输入", controls: "除 biblatex `.bib` 外,`bibliography()` 也收 CSL JSON（顶层 `[` / `{` 自动识别）。CSL JSON 经 `src/parse/csl-json.typ` 适配器转成与 citegeist 同构的 entry dict,再走同一套渲染层——`.bib` 与 JSON 输出一致。名字数组、date-parts 在 Typst 层直接构造 `parsed_names` / `parsed_dates`,不经 citegeist WASM。",
  expect: [CSL JSON 各能力映射到 GB 著录:

    - *类型*:`article-journal`→`[J]`、`book`→`[M]`、`chapter`→`[M]//` 析出、`webpage`→`[EB/OL]`;有 `DOI`/`URL` 的期刊出 `[J/OL]`。
    - *名字*:`family`/`given` 直接搬,`non-dropping-particle`→前缀(`van der`),`literal`→机构 / 整体名(`中国科学院`)。
    - *日期*:`issued.date-parts` → 出版年;`circa: true` → 估计年置「[]」;只有 `literal`(非 EDTF)时原样著录(`1705（康熙四十四年）`——biblatex date 承受自由文本)。
    - *富文本*:`<i>`→斜体、`<span class="nocase">` 保护大小写;字面 `&` / `_` 等特殊字符按字面著录(不被 LaTeX 词法器误伤)。
    - *容器*:`container-title` 按类型分派——期刊入 journaltitle、析出入 booktitle(母体)。
    - *地图*:`type: map`→`[CM]`,`scale`→题名后比例尺、`dimensions`→出版年后尺寸(2025 §8.13);标准 biblatex 无这两个字段,CSL JSON 却有,经此注入。
    - *预印本推断*:CSL 里预印本是 `type: article` + `publisher=平台`(arXiv…)+ `pubstate: prepublished`,无专门类型。据此还原成预印本 → `[PP/OL]. 平台(创建日期)[引用日期]`。预印本平台 id(`number`,article 类型本会映成 `eid`)*不*当引文页码著录——§8.15.2 平台式无引文页码槽。])

#let json = bytes("[
  {\"id\": \"smith2020\", \"type\": \"article-journal\",
   \"title\": \"A Study of <i>DNA</i> and <span class=\\\"nocase\\\">rna</span>\",
   \"author\": [{\"family\": \"Smith\", \"given\": \"John\"}, {\"family\": \"Berg\", \"given\": \"P.\", \"non-dropping-particle\": \"van der\"}],
   \"container-title\": \"Nature & Science\", \"volume\": \"5\", \"issue\": \"2\", \"page\": \"10-20\",
   \"issued\": {\"date-parts\": [[2020, 3, 15]]}, \"DOI\": \"10.1/x_y\", \"language\": \"en\"},
  {\"id\": \"guji\", \"type\": \"book\", \"title\": \"康熙刻本\",
   \"author\": [{\"literal\": \"中国科学院\"}], \"publisher\": \"书局\", \"publisher-place\": \"京\",
   \"issued\": {\"literal\": \"1705（康熙四十四年）\"}, \"language\": \"zh-CN\"},
  {\"id\": \"chapter\", \"type\": \"chapter\", \"title\": \"析出题名\",
   \"author\": [{\"family\": \"王\", \"given\": \"五\"}], \"editor\": [{\"family\": \"李\", \"given\": \"四\"}],
   \"container-title\": \"母体文集\", \"publisher\": \"出版社\", \"publisher-place\": \"北京\",
   \"page\": \"100-120\", \"issued\": {\"date-parts\": [[2019]]}, \"language\": \"zh-CN\"},
  {\"id\": \"web\", \"type\": \"webpage\", \"title\": \"网页标题\",
   \"author\": [{\"literal\": \"某机构\"}], \"URL\": \"https://example.org/a_b\",
   \"issued\": {\"date-parts\": [[2021, 6]], \"circa\": true},
   \"accessed\": {\"date-parts\": [[2023, 1, 5]]}, \"language\": \"zh-CN\"},
  {\"id\": \"seamap\", \"type\": \"map\", \"title\": \"中国南部海域海底地形图\",
   \"author\": [{\"literal\": \"吴自银\"}, {\"literal\": \"温珍河\"}],
   \"publisher\": \"科学出版社\", \"publisher-place\": \"北京\",
   \"issued\": {\"date-parts\": [[2019]]}, \"scale\": \"1:3000000\", \"dimensions\": \"100cm×70cm\", \"language\": \"zh-CN\"},
  {\"id\": \"preprint\", \"type\": \"article\", \"title\": \"arXiv 预印本\",
   \"author\": [{\"literal\": \"钱\"}], \"publisher\": \"arXiv\", \"pubstate\": \"prepublished\",
   \"number\": \"arXiv:1112.6136\",
   \"issued\": {\"date-parts\": [[2012, 3, 18]]}, \"URL\": \"https://doi.org/10.48550/arXiv.1112.6136\",
   \"accessed\": {\"date-parts\": [[2020, 6, 24]]}, \"language\": \"zh-CN\"},
  {\"id\": \"archive\", \"type\": \"personal_communication\", \"title\": \"奏请上海道库洋务外销要款事\",
   \"author\": [{\"literal\": \"李鸿章\"}], \"archive_location\": \"04-01-35-0399-039\",
   \"archive\": \"中国第一历史档案馆\", \"archive-place\": \"北京\",
   \"issued\": {\"literal\": \"1887（光绪十三年三月十三日）\"}, \"language\": \"zh-CN\"},
  {\"id\": \"archinf\", \"type\": \"pamphlet\", \"title\": \"检发布告\",
   \"author\": [{\"literal\": \"湖北省建设厅\"}], \"archive_location\": \"LS031-001-0001-001\",
   \"archive\": \"湖北省档案馆\", \"archive-place\": \"武汉\", \"URL\": \"https://x.cn/a.PDF\",
   \"issued\": {\"date-parts\": [[\"1931\", 11, 7]]}, \"language\": \"zh-CN\"},
  {\"id\": \"arccol\", \"type\": \"collection\", \"title\": \"某档案全宗\",
   \"author\": [{\"literal\": \"某机关\"}], \"archive\": \"某档案馆\", \"archive-place\": \"北京\",
   \"issued\": {\"date-parts\": [[\"1950\"]]}, \"language\": \"zh-CN\"},
  {\"id\": \"dash\", \"type\": \"paper-conference\", \"title\": \"Information Technology--Telecommunications Study\",
   \"author\": [{\"family\": \"Smith\", \"given\": \"J\"}], \"container-title\": \"Some Proceedings\",
   \"issued\": {\"date-parts\": [[2020]]}, \"language\": \"en\"},
  {\"id\": \"mvbook\", \"type\": \"book\", \"title\": \"中国科学技术史\", \"volume\": \"第二卷\", \"volume-title\": \"科学思想史\",
   \"author\": [{\"literal\": \"李约瑟\"}], \"publisher\": \"科学出版社\", \"publisher-place\": \"北京\",
   \"issued\": {\"date-parts\": [[1990]]}, \"language\": \"zh-CN\"},
  {\"id\": \"manu\", \"type\": \"manuscript\", \"title\": \"某某档案卷宗\", \"number\": \"JC10-1-001\",
   \"author\": [{\"literal\": \"辽宁省政府\"}], \"archive\": \"辽宁省档案馆\", \"archive-place\": \"沈阳\",
   \"issued\": {\"date-parts\": [[\"1931\", 11, 7]]}, \"language\": \"zh-CN\"}
]")

#case("著者-出版年制", gb7714.with(version: 2025), bib: json, cites: (<smith2020>, <guji>, <chapter>, <web>, <seamap>, <preprint>), full: true)
#case("顺序编码制 · 2025", gb7714.with(version: 2025, style: "numeric"), bib: json, cites: (<smith2020>, <guji>, <chapter>, <web>, <seamap>, <preprint>), full: true)
// 档案（§8.12.3）：archive→收藏者(institution)、archive-place→收藏者所在地(location)、archive_location→档号
//   (biblatex number，题名后「题名: 档号[A]」)、issued literal→形成日期。dash 条测 CSL 文本 `--`→en-dash。
#case("CSL 档案 archive/archive-place/archive_location 三字段 · 文本 `--`→en-dash", gb7714.with(version: 2025), bib: json, cites: (<archive>, <dash>), full: true)
// 档案类型推断：type=pamphlet 但带档号(archive_location)→ 还原成档案 [A/OL]（§8.12.3:2）。
#case("档案类型推断：pamphlet + 档号 → [A/OL]", gb7714.with(version: 2025, style: "numeric"), bib: json, cites: (<archinf>,), full: true)
// CSL collection（档案全宗，官方 GB CSL 恒判 [A]）→ 档案。
#case("CSL collection → 档案 [A]（对齐官方 GB CSL）", gb7714.with(version: 2025, style: "numeric"), bib: json, cites: (<arccol>,), full: true)
// CSL `volume-title`（分卷书名）：CSL 与 biblatex 的 title 语义相反，有 volume-title 时 CSL title=整套→maintitle、
//   volume-title=分卷→title，渲染「中国科学技术史:第二卷 科学思想史」（§7.3 示例 5）。
#case("CSL volume-title→分卷书名（多卷书「整套:卷次 分卷」）", gb7714.with(version: 2025), bib: json, cites: (<mvbook>,), full: true)
// CSL `manuscript`→biblatex archive（[A] 档案，§8.12.3）：CSL `archive`（收藏者）→institution、
//   `archive-place`（收藏者所在地）→location，date=形成日期全著录「收藏者所在地:收藏者, 形成日期」。
#case("CSL manuscript→档案[A]（archive→收藏者·archive-place→所在地·形成日期）", gb7714.with(version: 2025, style: "numeric"), bib: json, cites: (<manu>,), full: true)
#case("空数组 `[]`：空文献表，不报错", gb7714.with(), bib: "[]", full: true)
