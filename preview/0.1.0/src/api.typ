#import "/citegeist/lib.typ": load-bibliography

#import "errors.typ"
#import "@preview/quan:0.2.1": quan as _quan
#import "sentinel.typ": *
#import "elements/mark-medium/built-in.typ" as mark-medium
#import "elements/mark-medium/custom.typ" as mark-custom
#import "parse/lang-detect.typ" as language
#import "terms/built-in.typ" as terms
#import "punct/built-in.typ" as punct
#import "punct/custom.typ" as punct-custom
#import "category.typ"
#import "parse/field.typ"
#import "bibliography/sort.typ"
#import "elements/pages.typ"
#import "citation/author-date.typ" as author-date-cite
#import "citation/numeric.typ" as numeric-cite

#import "citation/footnote.typ" as footnote-cite

#import "drivers/dispatch.typ"
#import "terms/custom.typ": validate-terms
#import "fields/custom.typ": validate-fields
#import "elements/pids/custom.typ": validate-pids
#import "bibliography/render.typ" as bib
#import "citation/omni-aux.typ" as omni-aux

#import "citation/native-aux.typ": *
#import "parse/latex.typ"
#import "parse/entryset.typ"
#import "elements/imprint/date.typ" as publication-date
#import "elements/creator.typ" as creators
#import "elements/title.typ" as titles

#let _coerce-version(v) = {
  if v == auto { auto }
  else if std.type(v) == str and v in ("2005", "2015", "2025") { int(v) }
  else if v == 2015 { 2015 }
  else if v == 2005 { 2005 }
  else { 2025 }
}

#let _preprint-mark(version) = if version == 2025 { "PP" } else if version == 2005 { "Z" } else { "A" }

#let _has-arxiv-fields(e) = {
  let eprint = e.fields.at("eprint", default: none)
  let eprint-type = e.fields.at("eprinttype", default: none)
  if eprint-type == none { eprint-type = e.fields.at("archiveprefix", default: none) }
  let journal = e.fields.at("journaltitle", default: none)
  if journal == none { journal = e.fields.at("journal", default: none) }
  let by-eprint = (eprint != none) and (eprint-type != none) and lower(str(eprint-type)).starts-with("arxiv")
  let by-journal = (journal != none) and lower(str(journal)).starts-with("arxiv")
  by-eprint or by-journal
}
#let _is-preprint-routed(e) = {
  if e.entry_type == "preprint" { return true }
  if e.entry_type != "article" { return false }
  let subtype = e.fields.at("entrysubtype", default: none)
  if subtype != none and lower(str(subtype)) == "preprint" { return true }
  _has-arxiv-fields(e)
}

#let _version-mark(base, rawtype, version, is-preprint: false) = {

  if is-preprint or rawtype == "preprint" { return _preprint-mark(version) }
  if version == 2005 {

    if base in ("A", "DS", "CM") { "Z" } else if base == "Z" { "M" } else { base }
  } else if version == 2025 {
    if rawtype == "unpublished" { "A" } else { base }
  } else { base }
}

#let BIB-ENTRY-RE = regex("@(\\w+)\\s*\\{\\s*([^,\\s]+)")
#let bib-keys(s) = str(s).matches(BIB-ENTRY-RE).map(m => m.captures.at(1))

#let _get-related-key(entry) = {
  let related = entry.fields.at("related", default: none)
  let related-type = entry.fields.at("relatedtype", default: none)
  if related != none and related-type != none and lower(str(related-type)) == "lanversion" { str(related) } else { none }
}

#let _author-date-prefix(author, entry, suffix-table, suffix-key, punct-style: "half-with-space", custom-punct: (:), version: 2015, name-date-separator: auto, show-no-date: false, no-date-lang: none, custom-terms: (:)) = {
  let year = publication-date.year(entry)
  let disambiguation-suffix = if suffix-key != none { suffix-table.at(suffix-key, default: "") } else { "" }

  if year != none { year = publication-date.with-suffix(year, disambiguation-suffix) }
  else if show-no-date {
    let word = terms.no-date-for(if no-date-lang != none { no-date-lang } else { language.get(entry) }, custom-terms: custom-terms)
    year = if disambiguation-suffix != "" { word + "-" + disambiguation-suffix } else { word }
  }

  let _name-date-default = if version == 2005 { punct.get("period", entry, punct-style, custom-punct) }
    else { punct.get("comma", entry, punct-style, custom-punct) }
  let _name-date-delim = if name-date-separator != auto {

    punct.resolve-separator(name-date-separator, entry, punct-style, custom-punct, _name-date-default)
  } else { _name-date-default }

  if author != none and year != none and punct.ends-with-period(author) and type(_name-date-delim) == str and _name-date-delim.trim(at: start).starts-with(".") {
    _name-date-delim = _name-date-delim.trim(".", at: start, repeat: false)
  }
  if author != none and year != none { author + _name-date-delim + year }
  else if author != none { author }
  else if year != none { year }
  else { "" }
}

#let _author-date-join(author-date, rest, period-after, entry, punct-style, custom-punct) = {
  if not period-after { return [#author-date #rest] }

  if punct.ends-with-period(author-date) { return [#author-date #rest] }
  [#author-date#punct.get("period", entry, punct-style, custom-punct)#rest]
}

#let apply-footnote-numbering(footnote-numbering-use-quan, body) = {
  if footnote-numbering-use-quan {
    set footnote(numbering: n => _quan(n))
    body
  } else {
    set footnote(numbering: n => bib.circled-number(n))
    body
  }
}

#let _api-pick(override, fallback) = if override != auto { override } else { fallback }

/**
= `gb7714` — 全局配置与初始化 <gb7714-fn>

以 `show` 规则在任何引用之前生效，写入全局配置并注册引用渲染逻辑：

```typ
#show: gb7714                          // 全默认
#show: gb7714(style: "author-date")    // 带配置（推荐形态，编辑器可补全全部参数）
```

下方列出的全部配置项即此处可传的命名参数。需要单列表 / 单引用粒度的覆盖时，
`bibliography(..)` 与 `cite(..)` 接受多数同名参数（`auto` 继承全局）。

```typ @key``` 与 ```typ #cite(..)``` 的等价关系见 概述 章节。
**/
#let gb7714(
  path,                          /// <- `string` | `array` | `dictionary` <`required`>
    /// `read()` 读取的 .bib 内容，三种形式：\
    /// - 单个内容：`gb7714(read("refs.bib"))`；
    /// - 数组：`gb7714((read("ref/a.bib"), read("ref/b.bib")))`；
    /// - 带标签字典：`gb7714(("label-a": read("a.bib"), "label-b": read("b.bib")))`，标签为内部文件标签。命名参考文献表用 `bibliography(label: ..)` 即可，无需关心此标签。|

  style:  (cite: "numeric", bib: "numeric"), /// <- `string` | `dictionary`
    /// 引用样式。两根轴*正交*：\
    /// - `"numeric"`：顺序编码制，如 #super[[1]]；
    /// - `"author-date"`：著者-出版年制，如 (张三, 2020)；\
    /// 标量是「两轴同值」的简写；要分别指定就写逐轴字典 ```typc (cite: .., bib: ..)```：\
    /// - `cite`：*①正文标注形态*——`[1]` 还是 `(张三, 2020)`。编号、排序、消歧后缀、`cite-punct-style` 的制感知都跟这根轴；
    /// - `bib`：*②著录格式*——参考文献表条目里出版日期的位置（`"numeric"` 在末尾、`"author-date"` 提到责任者之后）；未写时跟 `cite`。\
    /// 于是「著者-出版年制标注 + 编号表」写 ```typc style: "author-date", numbering-style: "bracket"```；
    /// 「顺序编码制标注 + 著者-出版年制著录」写 ```typc style: (cite: "numeric", bib: "author-date")```。\
    /// 也收国标 CSL 全名（`"gb-7714-{2005,2015,2025}-{numeric,author-date,note}"`），它同时锁 `version`，只能写成标量。|
  version:             2025,      /// <- `integer`
    /// GB/T 7714 版本，取 2025 / 2015 / 2005（或对应字符串），非法值回落 2025。\
    /// 默认 2025 为现行国标；旧版仅著录格式的少数细节不同，字段语义与引用写法一致：\
    /// - 2015 与 2025 的差异集中于标准、会议录、报告、网站、档案、地图、数据集、预印本八类的著录格式；
    /// - 2005 除上述外，尚：不著录永久标识符（仅著录获取和访问路径）；专利著录专利国；档案、数据集、地图、预印本一律作为「其他」著录（文献类型标识为 Z）；著者-出版年制文献表中主要责任者与出版年之间以句点分隔。\
    /// 用 `#bibliography(version: ..)` 可为单个文献表锁定版本（也兼容国标 CSL 全名如 `"gb-7714-2005-author-date"`）。|
  full:                false,     /// <- `boolean`
    /// - `false`（默认）：参考文献表仅著录已引用的条目；
    /// - `true`：著录全部条目，未引用者追加在已引用者之后：
    ///   - 顺序编码制：其余条目按 `.bib` 文件顺序追加；\
    ///   - 著者-出版年制：按著者姓名拼音排序。|

  cite-form:           auto,      /// <- `auto` | `string`
    /// 正文引用的标注形态。可选值：\
    /// - `auto`（默认）：顺序编码制取 `"super"`，著者-出版年制取 `"normal"`；
    /// - `"super"`：上标——顺序编码制 #super[\[1\]]，著者-出版年制整段上标 `#super[(A, 2020)]`（此形态建议配 `cite-punct-style: "half"` 用半角括号）；
    /// - `"inline"`：正文（不上标）——顺序编码制 \[1\]，著者-出版年制同 `"normal"`；
    /// - `"normal"`：该样式默认形态——顺序编码制上标 #super[\[1\]]，著者-出版年制圆括号 (Author, year)；
    /// - `"prose"`：叙述式——著者-出版年制作 `Stieg (1981)` / `张三（2020）`、顺序编码制作 `Author [1]`。括号前间隙随标点方向感知（与括号同源）：全角档紧贴（CJK 行文惯例，全角括号自带视觉空隙）、半角档空格；
    /// - `"author"`：仅著者（含「等 / et al」截断）；
    /// - `"year"`：*裸出版年*（无括号无著者），带 a/b/c 消歧后缀——对齐原生 `cite(form: "year")`。「正文已提及责任者姓名，()内只著录出版年」（GB §10.2）的场景：括号随正文自己写，或直接用 `"prose"` 让包整体渲染；
    /// - `none`：不出标注（条目仍计入参考文献表）。\
    /// 多键引用（如 `@a@b@c`）：`"prose"` 回落 `"inline"` / `"normal"`；`"author"` / `"year"` 各键以分号连列，如 张三；李四 / 2020；2019。\
    /// 单次可用 #arg-ref("cite", "form")[ ```typ #cite()``` 的 `form` 参数]覆盖。|
  cite-merge:          true,      /// <- `boolean`
    /// 相邻引用是否合并为一组标注。\
    /// - `true`（默认）：```typ @a@b#cite[@c]``` 合并为 ```typ [1-3]``` / ```typ (A, 2020; B, 2021; C, 2022)```；
    /// - `false`：各引用独立成组，作 ```typ [1][2][3]``` / ```typ (A, 2020)(B, 2021)(C, 2022)```。\
    /// 脚注制下同理：相邻的 ```typ @a@b``` 与相邻的两次 ```typ #cite()``` 都合成*一个*脚注（注内条目分号接排、整注一枚句点，对齐官方 note CSL 的 citation delimiter）。\
    /// 合并组内的条目次序由 #arg-ref("gb7714", "cite-sort-by")[`cite-sort-by`] 决定（缺省：顺序编码制编号升序，著者-出版年制按版本派生）。\
    /// 单次可用 #arg-ref("cite", "merge")[ ```typ #cite()``` 的 `merge` 参数]覆盖，语义为「完全孤立」：设 `merge: false` 的引用只拆开自身、不与相邻引用合并，其外的引用照常合并。如 ```typ #cite(merge: false)[@a] @b@c``` → ```typ [1][2-3]```。|
  cite-collapse-date:  true,      /// <- `boolean`
    /// 著者-出版年制合并组内的*年份折叠*：组内排序后，相邻且著者标签相同的条目并入一组，著者只出一次、年份连列。\
    /// - `true`（默认，官方 2015 / 2025 CSL 均开启，即 CSL 的 `collapse="year"`）：```typ @zhang2020@zhang2021@li2021``` 得 `（张三，2020，2021；李四，2021）`，同著者同年经消歧后缀连列（`（张三，2020a，2020b）`）；
    /// - `false`：逐条完整著者，`（张三，2020；张三，2021；李四，2021）`。\
    /// 判据是*消歧后的著者标签串*（含「等 / et al」截断与姓名消歧升级），标签不同不折叠；带引文页码（supplement）的条目不参与折叠（页码要贴住它所属的那条）。年份间分隔符沿用 #arg-ref("gb7714", "cite-name-date-separator")[`cite-name-date-separator`] 的有效值。\
    /// 仅作用于行内著者-出版年制标注（顺序编码制有自己的区间压缩，脚注制著录完整条目，均不适用）。单次可用 #arg-ref("cite", "collapse-date")[ ```typ #cite(collapse-date: ..)``` ]覆盖。|
  cite-supplement-style:    auto,      /// <- `auto` | `string`
    /// 带 supplement 的引用显示格式。可选值：\
    /// - `auto`（默认）：顺序编码制 为 `"split"`；著者-出版年制 为 `"compact"`；
    /// - `"compact"`：标号内附 supplement，如 `[1:p3, 2, 3:Tab2]` 或 `(A, 2020: p3; B, 2021)`；
    /// - `"split"`（`auto` 下两制的默认）：每个标号独立成对方括号 / 圆括号，引文页码以*上标*紧跟其后，如 `[1]p3, [2], [3]Tab2` 或 `(A, 2020)p3; (B, 2021)`。|
  cite-punct-style:    "by-doc-and-style", /// <- "by-doc-and-style" | "by-doc-no-space" | "by-doc-with-space" | "by-entry-and-style" | "by-entry-no-space" | "by-entry-with-space" | "half" | "half-with-space" | "full" | `dictionary`
    /// 正文引用标注内部标点的全 / 半角风格。受控符号：逗号、冒号、分号、圆括号；连号 `-` 与方括号 `[` `]` 不切换（后者由 #arg-ref("gb7714", "numbering-style")[`numbering-style`] 管）。\
    /// *派生*风格——`by-doc-*` 由文档语言触发全角，`by-entry-*` 由被引条目语言触发；顺序编码制恒紧凑半角。间距后缀 `-and-style` 制感知（顺序编码制紧凑、著者-出版年制带空格）、`-no-space` 全紧、`-with-space` 全松：\
    /// - `"by-doc-and-style"`（默认）：顺序编码制 `[1,2]`；著者-出版年制随文档语言，中日全角、其余半角带空格 `(Smith, 2020)`；
    /// - `"by-doc-no-space"`：顺序编码制 `[1,2]`；著者-出版年制中日全角、其余半角无空格 `(Smith,2020)`；
    /// - `"by-doc-with-space"`：顺序编码制 `[1, 2]`；著者-出版年制中日全角、其余半角带空格；
    /// - `"by-entry-and-style"`：随被引条目语言，条目中日全角，其余顺序编码制半角、著者-出版年制半角带空格；
    /// - `"by-entry-no-space"` / `"by-entry-with-space"`：同上而全紧 / 全松（后者与参考文献表 `bib-punct-style` 同名同义）；
    /// *绝对*风格（无视语言与样式）：\
    /// - `"half"`（= `"half-no-space"`）：半角无尾空格，`[1,2]` / `(A,2020)`；
    /// - `"half-with-space"`：半角带尾空格，`[1, 2]` / `(A, 2020)`；
    /// - `"full"`：全角，`[1，2]` / `（A，2020）`；\
    /// *字典* ```typc (numeric: .., "author-date": ..)```：按当前引用的样式分派，未列出者回落 `"by-doc-and-style"`，如 ```typc cite-punct-style: (numeric: "half-with-space", "author-date": "full")```。\
    /// `auto` 等价于默认字符串。多组括号之间的分隔符恒按文档语言派生（`by-entry-*` 亦然）。本项只控制正文引用标注，参考文献表著录标点由 #arg-ref("gb7714", "bib-punct-style")[`bib-punct-style`] 管，互不干扰。|
  cite-compress-min:   2,         /// <- `integer`
    /// 顺序编码制中，≥_N_ 个连续编号时压缩为范围。|
  cite-range-separator: "-",      /// <- `string` | `dictionary`
    /// 顺序编码制连续引用压为区间（如 `[1-5]`）时，起讫序号间的连接符。默认短横线 `-`（国标规定）。\
    /// 裸标点字符（`","` 等）随 `cite-punct-style` 按*文档语言*那套感知（区间横跨多条目，无单一条目语言，与「多组括号之间的分隔符恒按文档语言派生」同规）；verbatim 定界 ```typc "{,}"``` 字面不感知。\
    /// 与 #arg-ref("gb7714", "page-range-separator")[`page-range-separator`]（起讫页码连接符）平行独立，互不影响。\
    /// `cite()` 接受 `range-separator` 单次覆盖。仅顺序编码制有区间压缩，著者-出版年制不适用。|
  cite-footnote:       false,     /// <- `boolean`
    /// 全局脚注引用：所有 ```typ @key``` 与 ```typ #cite[@key]``` 把对应条目著录于脚注，正文不再出 `[1]` / `(Author, 2020)` 标注。\
    /// - `false`（默认）：正文标注引用，条目集中于 `bibliography` 处；
    /// - `true`：每次引用即把整条著录（含双语关联条目）写入脚注，适合古籍、法律文书等。\
    /// 单次可用 #arg-ref("cite", "footnote")[ ```typ #cite(footnote: ..)``` ]覆盖。|
  cite-et-al-min:      2,         /// <- `integer` | `dictionary`
    /// 正文引用「等 / et al」的触发阈值：著者**达到**此数就截断，少于则完整列出。\
    /// 默认 `2`：1 位著者完整列出（Smith, 2020），2 位及以上截断（Smith, 等, 2020）。\
    /// *与 CSL 的 `et-al-min` 逐字同义*——样式里的 ```xml et-al-min="2"``` 就是本项的 `2`，照搬即可，不必换算。\
    /// 同收 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`] 的*三档取值*：整数 / 语言档（```typc (zh: 3, rest: 2)```）/ 角色档。行内标注只出主责任者，所以角色档在这里只有 `principal` 有意义。\
    /// 独立于参考文献表的 `bib-et-al-min`；正文引用通常截断更早，故默认值更小。|
  cite-terms-lang:  "by-entry", /// <- `string` | `dictionary`
    /// *cite 侧*（正文标注与脚注标注）术语的语言来源。管 5 个词：`et-al`（等 / et al）、`anon`（佚名 / Anon）、`no-date`（无日期 / n.d.）、`ibid`（同上 / Ibid.）、`footnote-number`（同③）。\
    /// *著录侧没有这个轴*——文献表里的术语恒跟条目语言（国标硬性），不给开关。\
    /// 两种形态：\
    /// - *标量*（一刀切作用于上述全部词）：\
    ///   - `"by-entry"`（默认）：随*被引条目*语言——中文条目「等」「佚名」、西文条目「et al」「Anon」；
    ///   - `"by-doc"`：随*文档*语言（= citeproc 的实际行为，一键复刻）；
    ///   - `"zh"` / `"ja"` / `"ko"` / `"ru"` / `"en"` / `"fr"` / `"de"`：强制该语种。
    /// - *字典*（按 term 项展开，未列出的走默认 `"by-entry"`）：```typc cite-terms-lang: (et-al: "by-doc", ibid: "zh")``` 只让截断词跟文档语言、只让「同上」恒中文。\
    /// 默认 `"by-entry"` 的依据（四方一致）：GB/T 7714 §9.3.1.2 明写「*欧美*第一责任者姓 + et al.，*中国*第一责任者姓名 + 等」——按*著者*语种；Zotero 中文社区 345 个国标 CSL 里 336 个用 CSL-M 的 per-item locale，著者-出版年制的 124 个里 123 个 citation 与 bibliography 的 locale 结构*对称*；胡振震 BibLaTeX 实测两侧都跟条目语言；官方 GB CSL 里被注释掉的那段 CSL-M 明写「按照*文献的语言*输出 et al. 等术语」——CSL 1.0.2 引擎跟文档语言是*技术限制*，不是设计意图。\
    /// 词本身用 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 覆写（本参数决定取哪个语言键，`custom-terms` 决定那个键是什么字，两者正交）。\
    /// 单次可用 #arg-ref("cite", "terms-lang")[ ```typ #cite(terms-lang: ..)``` ]覆盖。|
  cite-et-al-use-last: 0,         /// <- `integer` | `dictionary`
    /// 正文引用截断后，在省略号之后再保留*原名单末尾* _N_ 位著者（`0` = 关，默认）。\
    /// 同 #arg-ref("gb7714", "bib-et-al-use-last")[`bib-et-al-use-last`]，只是作用在行内标注。|
  cite-et-al-use-first: 1,        /// <- `integer` | `dictionary`
    /// 正文引用截断后保留前 _N_ 位著者。\
    /// 默认 `1`：保留首位著者，`(cite-et-al-min: 1, cite-et-al-use-first: 1)` 得 Smith, 等, 2020。\
    /// 通常应满足 `cite-et-al-use-first <= cite-et-al-min`，否则等同不截断。\
    /// 同收 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`] 的*三档取值*（整数 / 语言档 / 角色档）。|
  cite-name-style:    auto,      /// <- `auto` | `dictionary`
    /// 著者-出版年制正文引用中的西文姓名格式，收与 #arg-ref("gb7714", "bib-name-style")[`bib-name-style`] 同形的维度字典。\
    /// `auto`（默认）与各维缺省按*正文标注侧*派生：`given-form` 取 `none`（只姓，GB §9.3.1.2 的「著者姓氏」，如 `(Smith, 2020)`）、`family-case` 取 `none`（保留原大小写）。\
    /// `bib-name-style` 管参考文献表著录处的姓名，本项管正文引用处的姓名，二者各自独立：\
    /// - 著录处（`bib-name-style`）：#text(fill: red)[CRANE D], 1972. Invisible College[M]. Chicago: Univ. of Chicago Press.
    /// - 引用处（`cite-name-style`）：The notion of an invisible college has been explored in the sciences (#text(fill: red)[Crane], 1972).\
    /// 其余 `xxx` 与 `cite-xxx` 配置项的关系类此，后文不再重述。|
  cite-name-date-separator: auto,       /// <- `auto` | `string` | `dictionary`
    /// 著者-出版年制正文引用里「著者 ↔ 出版日期」之间的分隔符（如 张三，2020 中的 `，`）。\
    /// - `auto`（默认）：随条目语言与版本——全角标点条目（中文、日文）恒用逗号 `，`；半角标点条目（西文、俄文、韩文、其他）在 2005 用空格（如 Crane 1972）、在 2015 / 2025 用逗号 `, `；
    /// - 标点字符 `","`（全角 `"，"` 亦可）：强制逗号，但仍全 / 半角感知（中日全角、其余半角，随 `cite-punct-style`）。欲令 2005 西文也用逗号且保留语言感知，设 ```typc cite-name-date-separator: ","```；
    /// - 其它任意字符串：字面量，不再矫正宽度；单字符标点要字面用 verbatim 定界 ```typc "{，}"```。\
    /// 仅作用于正文引用；参考文献表著录处「著者. 年.」由 #arg-ref("gb7714", "bib-name-date-separator")[`bib-name-date-separator`] 管。|
  cite-completion:     true,      /// <- `boolean`
    /// 让编辑器（Tinymist 等）在 ```typ @key``` / ```typ #cite(<key>)``` 处补全 bib 键名并展示著者 / 题名 / 年份。\
    /// - `true`（默认）：发射一份隐形的参考文献注册供编辑器补全，不产生可见排版、不生成重复的参考文献表；
    /// - `false`：不发射，引用照常工作，但编辑器无法据 label 补全键名。\
    /// 本项不改变 `@key` 与同名用户标签的解析：`@key` 恒先查 bib，命中即作引用、不命中才回落为常规引用。故欲让普通标签生效，请避免与 bib 键重名。|

  bib-name-style:     auto,        /// <- `auto` | `dictionary`
    /// 西文姓名格式（中文姓名不受影响）：八维正交字典，键全可省，`auto` 等价空字典。以 `Zhao, Yu Xin` 与 `Godard, Jean-Luc` 为例：\
    /// - `order`：姓名顺序，标量作用全体：`"family-ahead"`（缺省，GB §7.1 姓前名后）/ `"given-ahead"`（名前，`Y X Zhao`）；另收 `(first:, rest:)` 字典*分设*第一责任者与其余责任者（须双键全给）——`(first: "family-ahead", rest: "given-ahead")` 即「只倒装第一责任者」的西文期刊惯例 `Crane, D. R., P. Smith`（首名走 `family-given-separator` 接缝、余名走 `given-family-separator`，各随其序）；
    /// - `family-case`：姓（连同 van der 前缀）的大小写，`auto`（缺省，随 `version`——2005 / 2015 全大写 `ZHAO`、2025 不处理）/ `"uppercase"` / `"lowercase"` / `none`（不处理，照 `.bib` 原样）；
    /// - `given-form`：名的形态，`auto`（缺省，文献表侧取 `"initials"`）/ `none`（*无名、只姓*）/ `"initials"`（缩首字母，`Y X`，GB §7.1）/ `"full"`（全拼 `Yu Xin`）；
    /// - `given-initial-separator`：每个缩写字母后接的字符串，`auto`（缺省，空串——GB §7.1 无点 `Y X`）/ 任意字符串。裸标点字符（`"."` / 全角 `"．"`）享受感知并剥掉槽位间距——恒得紧凑点（```typc given-separator: ""``` 下 `X.L.` 可达），间距归 `given-separator` 管；含空格的字面串逐字尊重（CSL 的 `initialize-with: ". "` 直搬即用，名部末尾自动修剪悬空空格）；
    /// - `given-separator`：名各段的连接，`auto`（缺省，随 `version`——2005 / 2015 各段一律空格 `J P`、2025 保留来源连接符 `J-P`）/ `none`（保留来源）/ 任意字符串（`" "` / `"-"` / `""` 拼接 / 其它）；
    /// - `given-case`：名的大小写（只对 `"full"` 有意义，缩写字母恒大写），`none`（缺省，不处理）/ `"uppercase"` / `"lowercase"` / `"capitalize-first"`（首段大写头、余段全小，`Yu xin`）/ `"capitalize-each"`（每段大写头，`Yu Xin`）；
    /// - `family-given-separator`：*姓前名后*时姓↔名的分隔，`auto`（缺省，空格 `ZHAO Y X`）/ 任意字符串（`", "` 得 `Zhao, Y. X.` 倒装逗号形，即 CSL 的 `sort-separator`）；
    /// - `given-family-separator`：*名前姓后*时名↔姓的分隔，`auto`（缺省，空格 `Y X Zhao`）/ 任意字符串。两条接缝一个顺序配一个名字，哪个 `order` 生效哪个，互不耦合。\
    /// 各 `*-separator` 的*裸标点字符*（`","` / `"，"` 等，与 #arg-ref("gb7714", "custom-punct")[`custom-punct`] 键同一套字符集）享受全/半角感知，与 `name-date-separator` 同惯例——著录处随 `bib-punct-style`、正文标注处（`cite-name-style` 的同名维度）随 `cite-punct-style`，各与所在侧的其他标点同宽度体系；其余字符串逐字尊重。要*单字符标点字面不纠正*，用 verbatim 定界 ```typc "{，}"```（剥外层花括号、任何档位原样；字面花括号写 `\{` `\}`，与模板 DSL 同词汇）。\
    /// `none` 双义按键读：`given-form: none` 是「该成分消失」；case 与 `given-separator` 键的 `none` 是「不处理」（同 `titles-text-case`）。\
    /// 常用组合：拼音 `ZHAO Yu-xin` = ```typc (family-case: "uppercase", given-form: "full", given-separator: "-", given-case: "capitalize-first")```；全拼 `Zhao Yuxin` = ```typc (given-form: "full", given-separator: "", given-case: "capitalize-first")```；西文自然序全名 `YuXin Zhao` = ```typc (order: "given-ahead", given-form: "full", given-separator: "", given-case: "capitalize-each")```；带点倒装 `Crane, D. R.` = ```typc (family-case: none, given-initial-separator: ".", family-given-separator: ", ")```。缩写尾点与结构句点相遇自动去重（`MILLER K. Gamma`，不出 `K..`）。\
    /// 西文姓名前缀（van der 等）的著录形态由 #arg-ref("gb7714", "prefix-last")[`prefix-last`] 独立控制。\
    /// 逐条覆盖：在 `.bib` 单条目写 `nameformat` 域即局部覆盖全局值（兼容 `givenahead` 写法），供混排语料对个别条目单独指定：\
    /// ```bib
    /// @book{zh, author={Zhao, Yuxin}, ..., nameformat={pinyin}}
    /// @book{en, author={Smith, John}, ...}   % 无 nameformat，走全局
    /// ```
    /// 条目局部优先于全局。|
  name-suffix-separator: auto,    /// <- `auto` | `string` | `dictionary`
    /// 西文姓名后缀（Jr. / Sr. / III 等）与姓名之间的分隔符。\
    /// - `auto`（默认）：随 `version`——2015 取 `", "`，输出 `PEEBLES P Z, Jr.`；2025 取 `" "`，输出 `Peebles P Z Jr`；
    /// - 任意字符串：强制使用该分隔符。裸标点字符（`","` 等）随 `bib-punct-style` 全 / 半角感知；单字符要字面不感知用 verbatim 定界 ```typc "{,}"```。\
    /// 后缀自身的尾点（如 `Jr.`）始终去除。|
  et-al-translator-separator: auto,  /// <- `auto` | `string` | `dictionary`
    /// 译者名单被截断时，截断词（等 / et al.）与译者角色词（译 / trans.）之间的分隔符。\
    /// GB/T 7714 的示例是「，等译．」*紧贴*——**起草人明示**：陈浩元《GB/T 7714 新标准对旧标准的主要修改及实施要点提示》（编辑学报 2015, 27(4)）§3.3-7「当遇到『等』『译』连用时，参照新标准给出的示例，可著录为『，等译．』，即『译』前不必标注『，』」。他是三个版本的主要起草人之一。\
    /// - `auto`（默认）：**中文紧贴**（`张三，李四，等译`）、日文紧贴、韩文空格、西文逗号（`..., et al., trans.`）；
    /// - `", "`：回到社区 CSL 的「等, 译」（本项曾以此为缺省——社区样式不是权威，起草人是）；
    /// - 标点字符 `","` 等（与 `custom-punct` 键同一套）：强制该标点，全 / 半角感知；
    /// - 其它任意字符串：字面量原样；单字符标点要字面不感知，用 verbatim 定界 ```typc "{，}"```。\
    /// 只管*译者*；编者截断的「等主编」紧贴是 GB 惯例，不受影响。未截断时「, 译」前的逗号是 GB §7.2 明文，也不归本项管。|
  bib-name-date-separator: auto,  /// <- `auto` | `string` | `dictionary`
    /// 著者-出版年制参考文献表里「著者 ↔ 出版日期」之间的分隔符（如 尼葛洛庞帝. 1996. 中著者后的 `.`）。\
    /// - `auto`（默认）：随 `version`——2005 取句点、2015 / 2025 取逗号，且全 / 半角感知（随 `bib-punct-style`）；
    /// - 标点字符 `","` / `"."`（与 `custom-punct` 键同一套；全角 `"，"`/`"。"` 亦可）：强制逗号 / 句点，仍全 / 半角感知（中日全角、其余半角）。欲令 2005 用逗号且保留语言感知，设 ```typc bib-name-date-separator: ","```；单字符标点要字面不感知，用 verbatim 定界 ```typc "{，}"```；
    /// - 其它任意字符串：字面量，不再矫正宽度（如 `", "` 恒半角、`"，"` 恒全角）。\
    /// 与正文引用的 #arg-ref("gb7714", "cite-name-date-separator")[`cite-name-date-separator`] 对应，本项管文献表、那项管正文标注，互不影响。|
  bib-et-al-min:       4,         /// <- `integer` | `dictionary`
    /// 参考文献表条目里「等 / et al」的触发阈值：著者 / 编者 / 译者**达到**此数就截断，少于则完整列出。\
    /// 默认 `4`：1～3 位完整列出，4 位及以上截断（GB/T 7714 §7.1.2「≤3 全录，>3 录前 3 加『等』」）。\
    /// *与 CSL 的 `et-al-min` 逐字同义*——CSL 样式里的 ```xml et-al-min="4"``` 就是本项的 `4`，照搬即可，不必换算。\
    /// *三档取值*（`bib-et-al-use-first` 与两个 `cite-` 同款同规）：\
    /// - *整数* — `4`：一刀切，所有位置、所有语言同一个阈值。\
    /// - *语言档* — ```typc (zh: 3, rest: 4)```：按*条目语言*分设。语言键与各 `-separator` 的多语言字典同一套（`zh` / `en` / `ja` / `ko` / `ru` / `fr`）。\
    /// - *角色档* — ```typc (principal: 4, host: 5, editor: 2, translator: 3, rest: 4)```：按*截断发生的位置*分设。每个位置的值本身还能再是一个语言档 —— ```typc (editor: (en: 5, ja: 3, rest: 4), rest: 4)``` —— 于是「角色 × 语言」两轴都能表达。\
    /// 四个角色键对应四个*截断位置*，不是 .bib 的字段名：\
    /// #table( columns: 2,
    ///   [*角色键*], [*截断位置*],
    ///   [`principal`], [主责任者。谁顶上由顶替链定（一般 `author`，缺了让 `editor` 顶替，专利先取 `holder`）。行内标注只出主责任者，同走此键。],
    ///   [`host`], [母体责任者，即析出文献 `//` 之后那一格（`bookauthor` 缺了让 `editor` 顶替）。],
    ///   [`editor`], [其他责任者·编者（专著里与 `author` 并存的那位）。],
    ///   [`translator`], [其他责任者·译者。],
    /// )
    /// 两档都能加 `rest` 兜底档，但*不能并列在同一层*（```typc (principal: 4, zh: 3)``` 报错——那种写法没有一致的读法）。\
    /// 角色分设的来路：Zotero 中文社区语料里，「中国政法大学」「中外法学」「法学引注手册」等样式给编者单设了比著者更宽的阈值（英文条目 `et-al-min="5"`，而著者是 `4`），日文条目又收到 `3`。\
    /// 与 #arg-ref("gb7714", "bib-et-al-use-first")[`bib-et-al-use-first`] 配合：本项定何时截断、后者定截断后保留几位，通常应满足 `et-al-use-first < et-al-min`。\
    /// 5 种配置对照（设 5 篇文献，著者数分别为 1 / 2 / 3 / 5 / 8）：\
    /// #table( columns: 6,
    ///   [*配置*], [A1（1 位）], [A2（2 位）], [A3（3 位）], [A4（5 位）], [A5（8 位）],
    ///   [*`(4, 3)`* — 国标默认], [张三], [张三, 李四], [张三, 李四, 王五], [张三, 李四, 王五, 等], [张三, 李四, 王五, 等],
    ///   [*`(2, 1)`* — cite 默认 / 紧凑], [张三], [张三, 等], [张三, 等], [张三, 等], [张三, 等],
    ///   [*`(11, 7)`* — Chicago AD 风格], [张三], [张三, 李四], [张三, 李四, 王五], [全列 5 位], [全列 8 位],
    ///   [*`(4, 1)`* — 国标阈值 + 激进截断], [张三], [张三, 李四], [张三, 李四, 王五], [张三, 等], [张三, 等],
    ///   [*`(6, 3)`* — 阈值 6 / 截断保 3], [张三], [张三, 李四], [张三, 李四, 王五], [全列 5 位], [张三, 李四, 王五, 等],
    /// )
    /// 不支持单次覆盖；某处需不同截断规则时，另建 `gb7714` 实例或写自定义 `custom-drivers` 模板。|
  bib-et-al-use-last: 0,          /// <- `integer` | `dictionary`
    /// 截断后，在省略号之后再保留*原名单末尾* _N_ 位著者：`A，B，C，… Z`。`0`（默认）= 关。\
    /// 开启后**不再出「等 / et al」**——省略号与截断词互斥（citeproc 同判）。\
    /// *前置条件*：`et-al-use-first + et-al-use-last <= et-al-min - 1`，违反即报错。责任者数*恰好达到* `et-al-min` 时（截断刚触发那一刻），显示的是「前 use-first 位 + 省略号 + 末 use-last 位」共 `use-first + use-last` 位——若它不比 `et-al-min` 小，一位都没省掉，省略号就在骗人。\
    /// 同收 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`] 的*三档取值*（整数 / 语言档 / 角色档）。\
    /// 省略号字形走 #arg-ref("gb7714", "custom-punct")[`custom-punct`] 的 `…` 键（默认单个 `…`，与 citeproc 实测一致；中文排版规范的六点写 ```typc custom-punct: ("…": "……")```）。\
    /// *GB 无此规定*，是方言功能。用者如心理学报、心理科学进展（```xml et-al-min="8" et-al-use-first="6" et-al-use-last="true"```）与 APA 7 系的傳播與社會學刊、四川外国语大学、海南大学（`21 / 19 / true`）。\
    /// CSL 的 `et-al-use-last` 是布尔（只留末 1 位），映射到本项就是 `1`（`"false"` → `0`）。收整数是为了与 `et-al-use-first` 值域一致。|
  bib-et-al-use-first: 3,         /// <- `integer` | `dictionary`
    /// 参考文献表条目截断后保留前 _N_ 位著者，余者合并为「等 / et al」。\
    /// 默认 `3`：与 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`] 默认 `4` 配合，得 GB/T 7714 的「4 位及以上列前 3 位 + 等」。\
    /// 同收 `bib-et-al-min` 的*三档取值*（整数 / 语言档 / 角色档，可两轴叠加），配置对照与角色键表见 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`]。|
  show-anon:           auto,      /// <- `auto` | `boolean`
    /// 责任者缺失时的占位。\
    /// - `auto`（默认）：著者-出版年制显示「佚名」（无责任者则无法构成「著者-年」标签），顺序编码制留空（以题名打头）；
    /// - `false`：留空；
    /// - `true`：无著者条目按语言显示占位：
    /// #table( columns: 6,
    ///   [*语言代码*], [`zh`], [`ja`], [`ko`], [`ru`], [`en`、`fr` 及其他],
    ///   [*标题*], [佚名], [#text(font: "MS Mincho")[著者不明]], [#text(font: "Batang")[미상]], [Аноним], [Anon],
    /// )|
  show-no-date:        auto,      /// <- `auto` | `boolean`
    /// 出版日期不明时的占位。与 #arg-ref("gb7714", "show-anon")[`show-anon`] *逐字同构*——两个占位词同为「查找键」（读者拿标签 `(责任者, 年份)` 在文献表里定位），行为一致。\
    /// - `auto`（默认）：著者-出版年制显示「无日期」（无年份则构不成「著者-年」标签），顺序编码制留空（标签是数字序号，没这个问题）。官方 GB CSL 两制实测就是这样；
    /// - `false`：留空；
    /// - `true`：按语言显示占位：
    /// #table( columns: 8,
    ///   [*语言代码*], [`zh`], [`ja`], [`ko`], [`ru`], [`fr`], [`de`], [`en` 及其他],
    ///   [*占位词*], [无日期], [#text(font: "MS Mincho")[日付なし]], [#text(font: "Batang")[일자 없음]], [б. д.], [s. d.], [o. J.], [n.d.],
    /// )
    /// 内置词照抄 CSL 官方 locale 的 `no date` short 形（`zh` 取官方 GB CSL 自己的 `<locale xml:lang="zh">` 覆写）；可用 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 的 `no-date` 键覆写。\
    /// 语言由 #arg-ref("gb7714", "cite-terms-lang")[`cite-terms-lang`] 定（cite 侧），著录侧恒跟条目语言——两侧同源，否则读者按标签在表里定位不到。\
    /// 同责任者多条无年文献靠消歧后缀区分，形态是「无日期-a」（连字符，对齐官方 GB CSL 里显式的 ```xml <group delimiter="-">```；有年的仍是 `2020a`，直接贴）。|
  date-fallback:       none,      /// <- `none` | `"urldate"`
    /// 条目*没有出版年*（`date` 与 `year` 都缺）时，从哪个字段推定一个。\
    /// - `none`（默认）：不推定。出版年就是空的——著者-出版年制下由 #arg-ref("gb7714", "show-no-date")[`show-no-date`] 补占位词；
    /// - `"urldate"`：取引用日期的*年份*，著录为 `[2024]`（方括号=推定值，GB/T 7714—2025 §7.5.4.3「估计的出版年应置于「[]」内」）。\
    /// 值是*字段名*而不是布尔，将来收别的推定源是加一个值、不是加一个参数。\
    /// *2025 版平台式电子资源（EB / DS / PP）不推定*——它们的日期槽是「（创建或修改日期）[引用日期]」，没有传统出版年槽，引用日期已当日期，再推一个出版年是造数据。官方 2025 CSL 同判（网页走 `creation-accessed-date`，无兜底），citeproc-lua 实测网页 / 数据集 / 预印本缺出版年都只出 `[引用日期]`。联机图书（`@book` + url）等有真出版年槽的照常推定。\
    /// *默认关的理由*：官方 compliant CSL（2015 与 2025）做这件事（`issued` 缺失时取 `accessed` 的年，加方括号），但胡振震 biblatex 不做，GB 原文也只规定了「估计的出版年怎么写」、没规定「从哪里推”。推定一个作者从未声明过的年份是造数据，须显式同意（同 #arg-ref("gb7714", "page-range-style")[`page-range-style`] 的裁断）。\
    /// 推定出的年*参与一切*：文献表的出版年位、著者-出版年制的正文标注、排序键、消歧后缀（`[2024a]`）。与「引用日期显不显示」无关——2025 版 `[M/OL]` 不著录引用日期，官方 CSL 照样拿它推定（推的是数据，不是显示）。\
    /// 连引用日期也没有的条目，出版年仍是空的（不造「日期不详」——两版官方 CSL 实测都留空）。|
  show-et-al:           true,     /// <- `boolean`
    /// 截断时末尾是否保留「等 / et al」标记词（不改变截断位数，位数由 #arg-ref("gb7714", "bib-et-al-min")[`bib-et-al-min`] / #arg-ref("gb7714", "bib-et-al-use-first")[`bib-et-al-use-first`] 定）。\
    /// - `true`（默认）：超阈值截断后保留「等 / et al」；
    /// - `false`：超阈值截断后省略「等 / et al」，仅列出 `bib-et-al-use-first` 位著者。\
    /// 欲完整列出全部著者，请把 `bib-et-al-min` 调至大于条目最大著者数（使其不截断），而非用本项。|
  dedup-author-editor:      false,     /// <- `boolean`
    /// - `false`：析出文献的编者正常输出；
    /// - `true`：析出文献的编者与上条相同时省略编者行。|

  title:           auto,      /// <- `auto` | `none` | `content`
    /// 参考文献表标题。\
    /// - `auto`：根据文档语言决定：
    /// #table( columns: 8,
    ///   [*语言代码*], [`zh`], [`zh`], [`ja`], [`ko`], [`fr`], [`ru`], [`en` 及其他],
    ///   [*地区*], [—], [`tw` / `hk`], [—], [—], [—], [—], [—],
    ///   [*标题*], [参考文献], [#text(font: "PMingLiU")[參考文獻]], [#text(font: "MS Mincho")[参考文献]], [#text(font: "Batang")[참고문헌]], [Références], [Список литературы], [References],
    /// )
    /// - `none`：不显示标题；
    /// - `content`：传入自定义内容作为标题。|
  entry-hanging-indent:     auto,       /// <- `auto` | `length`
    /// 条目*余行*缩进量，与原生 ```typc par(hanging-indent: ..)``` 同名同义——量的是「余行相对*正文块*左缘」，是个**段落量**，不是「距版心左缘的绝对位置」。\
    /// `auto`（默认）按制度派生：著者-出版年制 `1.5em`（对齐官方 CSL 的 `hanging-indent="true"`，原生渲成 16.5pt）；顺序编码制 `0pt`——官方 numeric CSL 根本没有这个属性，它那个「余行贴正文列」的效果全部来自 `second-field-align="flush"` 的*编号列*，与本量无关。\
    /// *四种版式下都生效*。编号成列时（`number-placement: "column"` / `"margin"`），正文列本身就是那一段，本量相对*正文列左缘*再缩（缺省 `0pt` 即什么也不动）。\
    /// 「余行顶格」不归本参数管——那是「编号不占一列」，用 #arg-ref("gb7714", "number-placement")[`number-placement: "inline"`]。本量刻意*不*与编号列宽挂钩：编号列宽随条目数变（`[9]` 涨到 `[120]` 宽出 1.4em），若本量是「距版心左缘的绝对值」，用户写死的数随时可能小于编号列宽，余行就倒插到首行文字左边——加减几条参考文献就能把版式弄崩。\
    /// 与 #arg-ref("gb7714", "entry-first-line-indent")[`entry-first-line-indent`] *正交*，可同时生效（首行缩进 A、余行缩进 B）——与原生 ```typc par``` 同义，两个量各管各、同一个坐标系。|
  entry-first-line-indent:  0pt,        /// <- `length`
    /// 条目*首行*缩进量，与原生 ```typc par(first-line-indent: ..)``` 同名同义，默认 `0pt`。\
    /// 与 `entry-hanging-indent` 一样，是个*段落量*（相对正文块左缘），四种版式下都生效；两者*正交*，不互斥（原生 ```typc par``` 里首行在 `first-line-indent`、余行在 `hanging-indent`，各管各）。\
    /// 国标原文式（首行缩进、余行顶格）：顺序编码制直接写 ```typc entry-first-line-indent: 2em```（余行缩进在该制 `auto` 即 `0pt`，不必再写）；著者-出版年制写 ```typc entry-hanging-indent: 0pt, entry-first-line-indent: 2em```。|
  entry-spacing:        auto,      /// <- `auto` | `length`
    /// 条目间距。`auto` 继承当前段落间距。|
  number-gutter:       0.65em,    /// <- `length`
    /// 编号之后与条目正文的间距，默认 `0.65em`。|
  numbering-style:     auto,      /// <- `auto` | `string`
    /// 编号标签样式：\
    /// - `"bracket"`：[1]；
    /// - `"paren"`：(1)；
    /// - `"dot"`：1.；
    /// - `"plain"`：1；
    /// - `"fullwidth-bracket"`：〔1〕；
    /// - `"fullwidth-paren"`：（1）；
    /// - `"circled"`：①——圈码。绘制引擎值内二级展开：标量缺省 Unicode 带圈数字（U+2460～U+32BF，超过 ㊿ 以 (N) 显示）；```typc (circled: "quan")``` 改由 ```typ quan``` 包绘制（字体缺带圈数字时用，可在主文档 ```typ #import "@preview/quan:0.2.1": quan-init, quan-style``` 后配置）——引擎是实现不是样式，不占顶层值，与脚注编号的 #arg-ref("gb7714", "footnote-numbering-use-quan")[`footnote-numbering-use-quan`] 同一哲学；
    /// - `none`：不显示编号。|
  number-placement: "column",  /// <- `string`
    /// 编号*放哪*（有编号时才有意义；`numbering-style: none` 时无编号可放）：\
    /// - `"column"`（默认）：编号自成一列贴版心左缘，正文另起一列，余行贴正文列——对齐官方 GB CSL 的 `second-field-align="flush"`（两制官方样式都用它）。这个 flush 是*编号列*给的，与 #arg-ref("gb7714", "entry-hanging-indent")[`entry-hanging-indent`] 无关；那两个段落量在正文列内照常生效（相对正文列左缘再缩）；
    /// - `"margin"`：编号*挂到版心外*，正文与余行都贴版心左缘——对齐 CSL 的 `second-field-align="margin"`（原生 typst 未实现该值，渲染同 flush；本包实现之）；
    /// - `"inline"`：编号排在*行内*，不成列——余行与首行全由那两个段落量决定（没有编号列给 flush）。\
    /// #arg-ref("gb7714", "number-width")[`number-width`] / #arg-ref("gb7714", "number-align")[`number-align`] / #arg-ref("gb7714", "number-gutter")[`number-gutter`] 只在成列两档（`"column"` / `"margin"`）有意义。|
  number-align:    "left",    /// <- `string`
    /// 编号对齐方式（默认 `"left"`）：\
    /// - `"left"`：左对齐；
    /// - `"right"`：右对齐；
    /// - `"center"`：居中。|
  number-width:    auto,      /// <- `auto` | `length`
    /// 编号列宽度。`auto` 自动测量最宽编号（多列表连续编号时按 `number-offset` 计入偏移，各表对齐）。|
  back-ref:            false,     /// <- `boolean`
    /// 参考文献条目编号反向跳转。\
    /// - `false`（默认）：编号为纯文本，无链接；
    /// - `true`：点击参考文献表中的编号跳转到正文中首次引用该文献处。\
    /// 仅当条目实际带编号时生效（即 #arg-ref("gb7714", "numbering-style")[`numbering-style`] 非 `none`、且非著者-出版年制）。|
  disambiguate:        auto,      /// <- `auto` | `boolean` | `dictionary`
    /// 引用标注的消歧机制。标量是三键同值的简写，字典逐机制指定（缺的键按 `auto`）：\
    /// - `date`（`auto` / `true` / `false`）：同一责任者、同一出版日期的多条给日期加 `a` / `b` / `c` 后缀。`auto`（缺省）只出现在*著者-出版年制的著录处*（`张三, 2020a. …`）与其正文标注；`true` *一律加*——②著录格式轴为 `numeric` 时条目末尾的出版年也带后缀（`…社, 2020a.`）；`false` 一律不加；
    /// - `given-name`（`auto` / `true` / `false`）：*同姓不同人*时给行内标签补名——姓 → 姓+首字母（`(Smith J, 2020)` / `(Smith A, 2020)`）→ 首字母仍撞再升全名（`(Miller John, 2020)`，此时文献表第一责任者同步全名），GB/T 7714 §9.3.1「倘若只标注责任者姓氏无法识别该人名时，可标注责任者姓名」→ §7.1.1，对齐官方 CSL 的 `disambiguate-add-givenname`。只动第一责任者、只动撞名的条目；
    /// - `names`（`auto` / `true` / `false`）：第一责任者相同、合作者不同的撞名条目，逐条展开被「等 / et al」截断的名单直到分开（`(Brown, Wang et al., 2020)` / `(Brown, Chen et al., 2020)`），对齐官方 CSL 的 `disambiguate-add-names`。\
    /// 梯子次序（CSL 同序）：展开名单 → 补名 → 剩下的（真同人同年）落年份后缀。\
    /// `given-name` 与 `names` 的 `auto` 跟*①正文标注形态轴*：`style.cite` 是著者-出版年制才生效（顺序编码制的 `[1]` 无标签可消歧）；混合制（如 ```typc style: (cite: "numeric", bib: "author-date")```）想要表侧效果，显式设 `true`。|

  bib-sort-by:         auto,      /// <- `auto` | `none` | `array`
    /// 参考文献表的排序键，按优先级从高到低排列：\
    /// - `auto`（默认）：按本表的标注体系派生——著者-出版年制取 ```typc ("name", "date", "title")```（GB/T 7714 §9.3.2），顺序编码制取 `none`（GB §9.2.1.1 按引用先后编号）；
    /// - `none`：不排序，保持引用 / `.bib` 原序；
    /// - `array`：排序键数组。元素是键名字符串（默认升序），要指定方向就展开成单条字典：\
    ///   - 合法键：`"name"`（首要责任者姓名，取值链 sortkey → key → author → editor → title，即 GB §3.14「name and date」里的那个 name）、`"date"`（出版日期）、`"title"`（题名）；\
    ///   - 合法方向：`"ascending"`（升序）、`"descending"`（降序）；\
    ///   - 例：```typc ("name", "date", "title")``` 全升序；```typc ("date": "descending")``` 写作 ```typc (("date": "descending"), "author")``` 即先按出版日期降序、再按责任者升序。\
    /// *文种*（语种）恒是最高优先级的隐式键，不写进本项也不可省（GB §9.3.2「先按文种集中」）；文种之间的先后由 #arg-ref("gb7714", "entry-lang-order")[`entry-lang-order`] 决定。\
    /// 正文合并引用组内的次序由 #arg-ref("gb7714", "cite-sort-by")[`cite-sort-by`] 独立控制。逐表可用 #arg-ref("print-bib", "sort-by")[```typ #bibliography(sort-by: ..)```] 覆盖。|
  cite-sort-by:        auto,      /// <- `auto` | `none` | `array`
    /// 正文*合并引用组内*的条目排序键（`@a@b@c` 合并成一组标注时组内的先后）：\
    /// - `auto`（默认）：按本组标注体系与 `version` 派生——顺序编码制取编号升序（`@c@a` 得 `[1-2]`）；著者-出版年制 2025 取 ```typc ("name", "date")```（官方 2025 CSL 的组内排序键），2015 / 2005 保写法序（官方 2015 CSL 无组内排序）；
    /// - `none`：保写法序（顺序编码制此时只压缩写法序里天然连续递增的编号段）；
    /// - `array`：排序键数组，形制同 #arg-ref("gb7714", "bib-sort-by")[`bib-sort-by`] 而合法键只有 `"name"` 与 `"date"`（组内同著者同年的次序由消歧后缀先行决定，无题名判据）。任一标注体系下显式键数组都生效。\
    /// 排序对象与显示对象一致：`name` 键取*行内实际渲染的著者标签串*（经「等 / et al」截断与姓名消歧升级），中文按 #arg-ref("gb7714", "cite-sort-zh-by")[`cite-sort-zh-by`] 取拼音 / 笔画键；`date` 键为出版年数值加消歧后缀。*文种*恒是最高优先级的隐式键（与 `bib-sort-by` 同一条规则）。\
    /// 排序不跨 `merge: false` 边界（各孤立段内部各排各的）。单次可用 #arg-ref("cite", "sort-by")[ ```typ #cite(sort-by: ..)``` ]覆盖。|
  sort-keys:           none,      /// <- `none` | `content`
    /// 自定义排序：\
    /// - `none`（默认）：按样式排序；
    /// - `content`：传入内容块，内部用 ```typ @key``` 引用指定的条目，按书写顺序优先排列，其余追加在后：\
    ///   - `sort-keys: [@key1]` 即 ```typ <key1>``` 对应条目将在主参考文献列表（```typ #bibliography```）中最先展示；\
    ///   - `sort-keys: [@key1@key2@key3]` 即 三个 ```typ <key>``` 对应条目将依次优先展示；
    ///   - 追加在后面的条目依然按照当前所采用的排列方式追加，未引用条目的追加方式同 #arg-ref("gb7714", "full")[`full` 配置项]所述。|
  bib-sort-zh-by:     "pinyin",  /// <- "pinyin" | "bihua"
    /// 参考文献表中文著者姓名的排序方案（仅对中文条目生效）：\
    /// - `"pinyin"`（默认）：按汉语拼音字母顺序；
    /// - `"bihua"`：按笔画排序，笔画少者在前，相同则按笔顺（横竖撇捺折）。\
    /// 顺序编码制按正文引用先后排序，不受此项影响；多音字可用 `sortkey` / `key` 域手动指定排序值。\
    /// 合并引用组内的中文排序由 #arg-ref("gb7714", "cite-sort-zh-by")[`cite-sort-zh-by`] 独立控制。逐表可用 ```typ #bibliography(sort-zh-by: ..)``` 覆盖。|
  cite-sort-zh-by:    "pinyin",  /// <- "pinyin" | "bihua"
    /// 合并引用组内排序（#arg-ref("gb7714", "cite-sort-by")[`cite-sort-by`] 的 `name` 键）对中文著者标签的排序方案，取值同 #arg-ref("gb7714", "bib-sort-zh-by")[`bib-sort-zh-by`]，两轴各自独立。\
    /// 单次可用 #arg-ref("cite", "sort-zh-by")[ ```typ #cite(sort-zh-by: ..)``` ]覆盖。|
  creator-idem:        none,   /// <- `none` | `string`
    /// *紧邻*条目为同一责任者时，第二条起责任者槽整块替换为给定字符串（idem——文献学里
    /// 「同前一人」的正名，与脚注域的 ibid「同前一处」分工；biblatex 的 dashed、AMS 的
    /// \bysame、CSL 的 subsequent-author-substitute 同一特性）：\
    /// - `none`（默认）：不替换（GB 无此惯例）；
    /// - 字符串（如 `"———"`，MLA / Chicago 的三连横线；社科中文刊同形）：替换串。\
    /// 判定与 biblatex fullhash 同义：比*完整名册*（非显示串，et-al 截断偶合不误判），只看
    /// 名单不看顶替来源角色（author 与 editor 顶替同人也替，biber 实测同形）；佚名（名册为空）
    /// 不替；`A、B、A` 序列里隔开的重复不替（CSL preceding-entry 语义）；双语关联条目第二行不参与。\
    /// 逐表可用 ```typ #bibliography(creator-idem: ..)``` 覆盖。|
  sort-use-prefix:     false,  /// <- `boolean`
    /// 西文姓名前缀（van / von / de / della 等）是否计入排序与著者-出版年制正文标注：\
    /// - `false`（默认）：前缀不参与——`Ludwig van Beethoven` 排在 B 区（按 `Beethoven`）、正文标注作 (Beethoven, 2020)；
    /// - `true`：前缀计入——排在 V 区、正文标注作 (van Beethoven, 2020)。\
    /// 参考文献表著录不受影响（姓在前不倒装，`van` 始终随姓著录，如 `VAN BEETHOVEN L`）。中文姓名无前缀，两档一致。\
    /// 本项为全局默认，可被逐条目、逐名字覆盖，优先级为逐名字 > 逐条目 > 全局：\
    /// - 逐条目：在 `.bib` 条目写 ```bib options = {use-prefix=true}```（对该条全部名字生效）；
    /// - 逐名字：用扩展人名格式 ```bib author = {family=Beethoven, given=Ludwig, prefix=van, use-prefix=true}```（名字内含 `=` 即触发，可多名字各设、以 `and` 连接）。\
    /// `bibliography` 接受单次覆盖（仍可被条目 / 名字级再覆盖）。|
  entry-lang-order: ("zh", "ja", "ko", "en", "fr", "ru"), /// <- `array`
    /// 多语言混排时的语种分组顺序，靠前的语种排在前面；未列出的语种排在列出的之后。\
    /// *文种是隐式的最高优先级排序键*——#arg-ref("gb7714", "bib-sort-by")[`bib-sort-by`] 写不写它，文献表都先按文种集中（GB/T 7714—2025 §9.3.2）。\
    /// **`()`（空数组）= 不分组**：所有条目走*一趟全局字顺*，`Adams` / `陈明`（chen）/ `Zhao` 按拼音混排在一起，而不是「中文组在前」。
    /// 这是**偏离国标**的逃生舱（§9.3.2 要求先按文种集中），给要对齐 CSL 与国际惯例的用户——CSL 1.0.2 没有文种分组能力。\
    /// 顺序编码制按引用先后编号，本参数只影响合引组内的排序（`[3,1]` 合并时组内谁先谁后）。|
  entry-lang-detect:         "auto",    /// <- "auto" | "fast" | "accurate"
    /// 条目 `langid` / `language` 域缺失时的语言判定方式（已显式标注语种的条目不受影响）。\
    /// 识别 6 种语言：中文 `zh`、日文 `ja`、韩文 `ko`、俄文 `ru`、法文 `fr`、英文 `en`（其余一律回落 `en`）。\
    /// - `"auto"`（默认）：预扫书目，若含假名或日文独占字符（新字体 経 / 戸 / 沢，国字 辻 / 働 / 込 等）则用 `"accurate"`，否则用 `"fast"`；含未标 `langid` 的法文条目时请显式选 `"accurate"` 或标注 `langid`；
    /// - `"fast"`：仅按字符脚本判定（假名判 `ja`、谚文判 `ko`、西里尔判 `ru`，其余汉字归 `zh`、拉丁归 `en`），零额外开销；
    /// - `"accurate"`：启用中日独占字符表、《百家姓》姓氏白名单与法英辨识全套，边缘场景更准，首次检测需加载识别模型。\
    /// 任何情形下显式标注 `langid` 都最可靠。|

  show-mark:           true,      /// <- `boolean` | `dictionary`
    /// 文献类型标识显示控制。\
    /// - `true`：显示（如 J）；`false`：隐藏；
    /// - 字典：按条目控制，键 = 小写 entry_type（`.bib` 里的类型名）或大写标识码（GB/T 7714 附录 A，按版本中性语义类匹配——`PP` 在 2015 同样命中预印本），`rest` 兜底；优先级 entry_type > 码 > `rest`。\
    /// 例（表 8 脚注 a「标准的文献类型标识为可选项」）：```typ show-mark: (rest: true, S: false)``` 省去标准的 \[S\]、其余照出。\
    /// 值只收布尔（无 `"online-only"` 档：标识不是获取途径，联机判据对它无语义）。|
  show-medium:         true,      /// <- `boolean`
    /// - `true`：显示载体标识（如 OL）；
    /// - `false`：隐藏。|
  show-url:            true,      /// <- `boolean` | `string` | `dictionary`
    /// 获取和访问路径（URL）显示控制。\
    /// - `true`（默认）：著录 URL，条目自动标载体 OL；
    /// - `false`：隐藏 URL，并禁用 OL 自动载体判定；
    /// - `"online-only"`：只有*网络文献*才著录——非联机条目的 URL、永久标识符、引用日期整组不出，载体码同步（纸质书带 `url` 字段不再冒出 \[M/OL\]）。联机判据五级：显式 `medium` 字段 → 显式标识含载体段（如 `usera = {M/OL}`）→ `@online` 类型 → 数字原生类型（webpage / software / dataset / database / preprint）且有获取途径 → 默认非联机；
    /// - 字典：按条目控制，键与 #arg-ref("gb7714", "show-mark")[`show-mark`] 同一套（小写 entry_type > 大写标识码 > `rest`），值 = 布尔或 `"online-only"`。例 ```typ show-url: (rest: false, PP: true)``` 只给预印本著录 URL（跨版本成立）。\
    /// `false` 时若仍要显示 OL 载体，可加 `medium = {OL}` 字段强制：\
    /// ```bib
    /// @article{Кочетков1993,
    ///   author    = {Кочетков, А. Я.},
    ///   title     = {Молибден-медно-золотопорфировое месторождение Рябиновсе},
    ///   journal   = {Отечественная геология},
    ///   volume    = {1993},
    ///   number    = {7},
    ///   pages     = {50--58},
    ///   medium    = {OL} % 强制显示为网络载体
    /// }
    /// ```
    /// 渲染为：\
    /// [1]#h(.5em)КОЧЕТКОВ А Я. Молибден-медно-золотопорфировое месторождение Рябиновсе\
    /// #h(1.65em) [J/OL]. Отечественная геология, 1993(7): 50-58.|
  show-urldate:        true,      /// <- `boolean`
    /// - `true`：显示引用日期（`urldate` 字段）；
    /// - `false`：隐藏。|
  show-related:        true,      /// <- `boolean`
    /// - `true`（默认）：渲染双语关联条目；
    /// - `false`：不渲染。\
    /// 用法：主条目用 `related` 域指向第二语言条目，并加 `relatedtype = {lanversion}`（写法固定）：\
  /// ```bib
    /// % 第一语言条目
    /// @book{primary-entry,
    ///   author      = {이병목},
    ///   title       = {도서관법규총람: 제1권},
    ///   address     = {서울},
    ///   publisher   = {구미무역 출판부},
    ///   year        = {2005},
    ///   pages       = {67--68},
    ///   related     = {secondary-entry}, % 指向第二语言条目的键
    ///   relatedtype = {lanversion}       % 必须加上这一字段，且写法固定
    /// }
    ///
    /// % 第二语言条目
    /// @book{secondary-entry,
    ///   author    = {李炳穆},
    ///   title     = {图书馆法规总览: 第1卷},
    ///   address   = {首尔},
    ///   publisher = {九美贸易出版部},
    ///   year      = {2005},
    ///   pages     = {67--68}
    /// }
    /// ```
    /// `show-related: true` 时，引用第一语言条目键 ```typ <primary-entry>``` 渲染为：\
    /// [1]#h(.5em)이병목. 도서관법규총람: 제 1 권[M]. 서울: 구미무역 출판부, 2005: 67-68.\
    /// #h(1.65em)李炳穆. 图书馆法规总览: 第1卷 [M]. 首尔: 九美贸易出版部, 2005: 67-68.|
  show-patent-country: false,     /// <- `boolean`
    /// - `false`：不显示专利国；
    /// - `true`：专利条目显示专利国（取 `address` / `location` 字段）。|
  volume-title-gutter: auto,      /// <- `auto` | `length`
    /// 多卷书（有 `maintitle` 母书名）里卷号与分卷名之间的间距，如「中国科学技术史：第二卷␣科学思想史」中「第二卷」与「科学思想史」之间。\
    /// - `auto`（默认）：普通词间空格；
    /// - 长度（如 `1em`）：固定横向间距。\
    /// 也接受原样传入的 content / 字符串。|
  show-sine-loco:      false,    /// <- `boolean`
    /// `.bib` 里*没有*出版地字段时的处理：\
    /// - `false`（默认）：留空；
    /// - `true`：补「[S.l.] / 出版地不详」占位（GB/T 7714 严格著录，占位词随条目语言）。\
    /// 自己在 `.bib` 里写了 `location = {[S.l.]}` 的，两档都*原样著录*——那是你按标准著录好的
    /// 数据，本参数只管「字段真的没有时替不替你补」，不改写你写下的字段文本。\
    /// 手册、档案、学位论文（标识码 A、D、S）与联机电子资源不补占位：GB/T 7714—2025 §7.5.2.3
    /// 末句「无出版地的电子资源可省略此项」。|
  show-sine-nomine:    false,    /// <- `boolean`
    /// `.bib` 里*没有*出版者字段时的处理：\
    /// - `false`（默认）：留空；
    /// - `true`：补「[s.n.] / 出版者不详」占位（GB/T 7714 严格著录，占位词随条目语言）。\
    /// 与 `show-sine-loco` 同规：自己写了 `publisher = {[s.n.]}` 就原样著录；两项都缺且都要补时，
    /// 合并成一对方括号「[S.l.: s.n.]」。|
  show-sine-anno:      false,    /// <- `boolean`
    /// 出版信息里*没有出版年*时，要不要在出版年位补占位（`北京: 某社, [日期不详]`）。\
    /// - `false`（默认）：留空；
    /// - `true`：补「[s.a.] / 日期不详」占位（占位词随条目语言，可经 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 的 `sine-anno` 键覆写）。\
    /// *与前两项的地位不同*：GB/T 7714 对无出版地（§7.5.2.3）、无出版者（§7.5.3.3）给了著录形式，
    /// 但对*出版日期缺失*一个字都没说，官方 compliant CSL 实测也不补。它是**方言样式的需求**
    /// （326 个中文 CSL 样式里，15 个顺序编码制样式在著录位补它），所以默认关。\
    /// 西文取拉丁 `s.a.`（sine anno）而非 CSL 的 `n.d.`：GB 对前两项明确选了拉丁体系（`S.l.` /
    /// `s.n.`），第三项在国标体系内类推拉丁才自洽。\
    /// *只对顺序编码制有意义*：著者-出版年制把出版年移到责任者后（§8.1），著录位本来就没有年——
    /// 那一侧的占位归 #arg-ref("gb7714", "show-no-date")[`show-no-date`] 管（缺省就是开的）。两个参数管两个槽，不重叠。\
    /// 与 #arg-ref("gb7714", "show-sine-loco")[`show-sine-loco`] 同规：手册、档案、学位论文（标识码 A、D、S）与联机电子资源不补。|
  show-degree:         false,     /// <- `boolean`
    /// 学位论文条目是否附加学位级别注记（仅文献类型标识为 D 的条目生效）。\
    /// - `false`（默认）：不附加，`@thesis` / `@mastersthesis` / `@phdthesis` 著录相同；
    /// - `true`：在题名标识 [D] 后插入学位级别：
    ///   - `@mastersthesis`（或 `@thesis` + `type = {mathesis}`）：中文 *硕士学位论文* / 英文 *MA thesis* / 日文 *修士論文* / 韩文 *석사학위논문* / 俄文 *магистерская диссертация* / 法文 *thèse de master*；
    ///   - `@phdthesis`（或 `@thesis` + `type = {phdthesis}`）：中文 *博士学位论文* / 英文 *PhD thesis* / 日文 *博士論文* / 韩文 *박사학위논문* / 俄文 *докторская диссертация* / 法文 *thèse de doctorat*；
    ///   - 裸 `@thesis` 无 `type` 字段：不附加。|
  show-annotation:     false,     /// <- `boolean`
    /// 是否在条目末尾追加 `annotation` / `annote` 字段的内容。\
    /// - `false`（默认）：忽略这两个字段；
    /// - `true`：取 `annotation`（优先）或 `annote` 的值，以一个句点加空格接在条目尾部，不再附加其它标点。字段内的 LaTeX 命令 / 转义 / 引号连字按与其它字段相同的规则渲染。\
    /// 用途：把每条文献的补充注释、阅读心得等附加信息著录于参考文献表。\
    /// `bibliography` / `cite(footnote: true)` 接受同名参数，`auto` 继承全局值。|
  prefix-last:         auto,       /// <- `auto` | `boolean`
    /// 西文姓名前缀（van der / von / de 等）的著录形态（中文姓名不受影响）：\
    /// - `auto`（默认）：随版本——2025 取 `true`、2015 取 `false`；
    /// - `true`：前缀缩为各段首字母、置于名缩写之后——`Pieternella H. van der Veen` → `Veen P H v d`（GB/T 7714—2025 示例形态）；
    /// - `false`：前缀全拼、置于姓之前——`van der Veen P H`。\
    /// 与 #arg-ref("gb7714", "bib-name-style")[`bib-name-style`] 正交：大小写仍由 `name-style` 决定（`uppercase` 档下 `true` 得 `VEEN P H V D`）。仅作用于参考文献表著录，正文引用标注用姓氏、不受此项影响。|
  show-series:         false,     /// <- `boolean`
    /// 是否著录丛书项（`series` 字段，如「经济科学译库」）。\
    /// - `false`（默认）：不著录。GB/T 7714—2015 / 2025 的著录格式不含丛书项（仅 2005 版有）；
    /// - `true`：在出版项后以「(丛书名)」或「(丛书名, 丛书号)」著录（`number` 未被类型标识占用时附丛书号），供沿用旧式丛书著录的体例选用。\
    /// 仅专著、析出文献生效；标准 S、学位论文 D、报告 R、专利 P、报纸 N、期刊 J 等 `number` 另有用途的类型不输出。|
  short-journal:       false,     /// <- `boolean`
    /// - `false`：使用 `journal` 字段作为期刊名；
    /// - `true`：使用 `shortjournal` 字段代替。|
  hyperlink:           true,      /// <- `boolean`
    /// - `true`（默认）：链接形式的获取和访问路径渲染为可点击超链接——`url`（链到自身）、DOI（doi.org）、CSTR（cstr.cn）、`eprint`（按 `archiveprefix` 链到 arXiv / PubMed / ChinaXiv 摘要页），以及 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 中 `pid: true` 的自定义永久标识符（值为 URL 时链到自身，或经 `resolver` 模板合成目标）。ISBN / ISSN 无公认解析器，恒为纯文本；
    /// - `false`：全部渲染为纯文本，不可点击。|
  hyperlink-title:          false,     /// <- `boolean`
    /// - `false`：条目题名为纯文本；
    /// - `true`：条目题名渲染为可点击的超链接（需有 `url` / `doi` 字段）。|

  show-pid:            (:),       /// <- `dictionary`
    /// 永久标识符显示控制，统一管理内置 DOI / CSTR / ISBN / ISSN / eprint 及 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 中 `pid: true` 的自定义标识符（URN、Handle 等）。\
    /// 逐标识符取值：\
    /// - `true`：强制显示（即使 URL 已含相同字符串、即使被 CSTR / DOI 互斥压制）；
    /// - `false`：隐藏；
    /// - `"online-only"`：仅条目为网络文献时显示（联机判据见 #arg-ref("gb7714", "show-url")[`show-url`]；不含强制直通豁免，URL 去重仍生效）；
    /// - 缺省或 `auto`：自动（URL 含同字符串或同类型标记则隐藏，否则显示）。\
    /// 例：```typ show-pid: (doi: false, isbn: true, myurn: auto)```。\
    /// 内置标识符的默认显示：DOI 恒显示；CSTR 仅 #arg-ref("gb7714", "version")[`version: 2025`] 默认显示；eprint 默认显示（唯 2025 预印本 PP 且出版平台已由 `eprinttype` / `archiveprefix` 著录时抑制）；ISBN / ISSN 默认不显示（国标列为任选项，需要时显式 ```typ show-pid: (isbn: true)```）。\
    /// 元配置键（不视作标识符名）：\
    /// - `max`：著录数量上限（不设 = 不限）。`max: 1` = 至多著录一个，取 #arg-ref("gb7714", "pid-priority")[`pid-priority`] 次序下首个*能著录*者。\
    ///   数的是**实际印出来的标识符个数**——获取和访问路径（GB/T 7714—2025 §7.8）是另一个著录项目，不占这个配额；被 URL 去重压下的标识符也不占。\
    ///   *缺省不限的依据*：§7.9 全文只有两条（7.9.1 路径含 PID 时可不重复著录、7.9.2 不含时**可按原文如实著录**），**没有数量上限**。「一般只印一个」是惯例不是国标，想要就显式写 `max: 1`；
    /// - `rest`：未点名标识符的兜底档。`rest: false` 全部隐藏（显式置 `true` 者仍生效，如 ```typ show-pid: (rest: false, doi: true)``` 仅留 DOI）；`rest: true` 全部显示（含默认不显示的 ISBN / ISSN）；`rest: "online-only"` 仅网络文献显示。\
    /// 条目词汇键（与 #arg-ref("gb7714", "show-mark")[`show-mark`] / #arg-ref("gb7714", "show-url")[`show-url`] 同一套）：小写 entry_type 或大写标识码，按条目关停全部标识符，如 ```typ show-pid: (book: false)```；标识符名键的显式设置优先于条目词汇键。\
    /// 内置标识符的特殊行为：\
    /// - CSTR 默认仅 2025 启用（2015 需显式 `show-pid: (cstr: true)`），因 2025 才将 CSTR 列为标准永久标识符。\
    ///   *曾有一层「CSTR 命中就抑制 DOI」的互斥，已删除*：它自称的依据「国标只须著录其一」在 GB 里**不存在**；唯一支持 CSTR 的权威（胡振震 biblatex 2025）方向正好相反（有 DOI 印 DOI）；而且它藏在 `pid-priority` 之前，让用户显式点名的次序失效。要「只印一个」用 `max: 1`，要定次序用 #arg-ref("gb7714", "pid-priority")[`pid-priority`]；
    /// - eprint 前缀派生：eprint 标签按 `archiveprefix` / `eprinttype` 派生（arXiv:NNNN.NNNN / ChinaXiv:NNNN / PSSXiv:NNNN / PubMed:NNN 等），缺省回退 eprint:NNNN；
    /// - 预印本 URL 合成（仅 2025）：`archiveprefix` 为 arXiv / ChinaXiv / PubMed 而缺 `url` 时自动按平台合成获取路径（走 `custom-pids` resolver 覆写链）；
    /// - 标签自动大写、冒号随 punct-style：标签英文一律大写（URN / DOI / arXiv 保留派生大小写），冒号随 #arg-ref("gb7714", "bib-punct-style")[`bib-punct-style`] 取半角 `:` 或全角 `：`（无尾空格）；
    /// - 自定义标识符同此机制：`custom-terms.pid: true` 的 token 自动纳入，标签取 `prefix` 或 `bib-field` 名（自动大写），可用 `show-pid: (myurn: ..)` 三态控制。|
  pid-priority: ("cstr", "doi", "eprint", "isbn", "issn"),  /// <- `array`
    /// 永久标识符的渲染次序。缺省就是**完整的链**——你看到的就是全部次序，没有藏在别处的补齐规则。\
    /// 它同时是*残缺名次表*的补齐序：写 ```typ pid-priority: ("issn",)``` 只是把 ISSN 提到最前，其余仍按缺省链跟上（`issn → cstr → doi → eprint → isbn`）。自定义标识符（#arg-ref("gb7714", "custom-pids")[`custom-pids`]）按定义顺序垫在最后。\
    /// *缺省次序的取舍*：CSTR 先于 DOI（它是国家标准的永久标识符）；eprint（预印本编号，能定位到文献）先于 ISBN / ISSN——后两个不是 GB 7.9 的永久标识符，是本包扩展、默认关闭。\
    /// *不必随版本变*：2015 版的 CSTR 由 #arg-ref("gb7714", "show-pid")[`show-pid`] 默认关掉，排在次序里也不会印出来。\
    /// *次序只看本参数*：#arg-ref("gb7714", "show-pid")[`show-pid`] 是开关，它的书写顺序不影响次序（```typ show-pid: (issn: true, isbn: true)``` 与 ```typ (isbn: true, issn: true)``` 输出一致）。\
    /// 与 #arg-ref("gb7714", "show-pid")[`show-pid`] 的 `max` 配合：`max: 1` 时印出来的就是本次序下*首个能著录*的标识符（被 URL 去重压下的不算）。\
    /// *国标没有规定 PID 之间的次序*——GB/T 7714—2025 §7.9 全文只有两条（7.9.1 路径含 PID 时可不重复著录、7.9.2 不含时可按原文如实著录），既没有数量上限，也没有优先级。本参数的缺省值是本包的取舍。|
  dedup-url-pid:       auto,      /// <- `auto` | `boolean`
    /// 获取和访问路径与永久标识符去重：路径里已经含了这个标识符时，不重复著录它。依据 GB/T 7714—2025 §7.9.1「获取和访问路径中含永久标识符时，可不重复著录永久标识符」。\
    /// - `auto`（默认）：随 #arg-ref("gb7714", "version")[`version`]——2025 版开（§7.9.1 是那一版的条款），2015 版关；
    /// - `true` / `false`：显式开关。\
    /// 判据是「**印出来的**路径里含**这一个**标识符」，大小写不敏感（DOI 规范本身大小写不敏感）：\
    /// - `show-url: false` 时路径根本不印，就没有「已经著录过」这回事，标识符照常著录；
    /// - 不按「类型」压制——条目的 `url` 指向*另一个* DOI（比如配套数据集的）时，本文的 DOI 照常著录。\
    /// #arg-ref("gb7714", "show-pid")[`show-pid`] 中显式置 `true` 的标识符强制著录，不受本项影响。|

  bib-punct-style:     auto, /// <- `auto` | "half-with-space" | "half" | "full" | "by-doc-no-space" | "by-doc-with-space" | "by-entry-no-space" | "by-entry-with-space"
    /// 参考文献表著录标点的全 / 半角风格（取值为正文引用 #arg-ref("gb7714", "cite-punct-style")[`cite-punct-style`] 的子集，同名同义，仅少两个制感知 `-and-style`，因著录与样式无关）：\
    /// - `auto`（默认）：随 `version`——2015 取 `"half-with-space"`、2025 取 `"full"`；
    /// - *绝对*：`"half-with-space"`（分隔符带尾空格 `, ` `. ` `: `）/ `"half"`（= `"half-no-space"`，无尾空格）/ `"full"`（一律全角）；
    /// - *随文档语言*：`"by-doc-no-space"` / `"by-doc-with-space"`——著录分隔符按文档语言定全 / 半角，中日文档全角、西文文档半角；
    /// - *随条目语言*：`"by-entry-no-space"` / `"by-entry-with-space"`——按各条目自身语言，中日全角、其余半角。\
    /// 「结构跟文档、内容跟条目」：`by-doc-*` 只管分隔符；`correct-punct` 矫正的字段内标点恒按条目语言，故西文标题内标点在中文文档里仍半角。\
    /// 受控符号（随档切换）：`,` 对 `，`、`:` 对 `：`、`(` 对 `（`、`)` 对 `）`、`;` 对 `；`、`?` 对 `？`、`!` 对 `！`。\
    /// 句号 `.` 例外，恒取半角：覆盖字段间隔、著者-出版年制人名↔年份后、条目末尾等所有结构位置，`"half-with-space"` 与 `"full"` 档为 `. `（带尾空格）、`"half"` 档为 `.`（无尾空格）、末尾去尾空格。\
    /// 恒半角的符号：句号 `.`、斜杠 `/`（护析出符号 `//` 与载体标识 /OL）、方括号 `[]`（文献类型标识容器）；如需将斜杠、方括号改全角，用 #arg-ref("gb7714", "custom-punct")[`custom-punct`] 指定。\
    /// 自定义条目格式 ```typ custom-drivers``` 里裸写的 `,` `:` `(` `)` `;` `?` `!` `.` 同走本套风格（句号仍恒半角）；裸 `/` 恒字面；反引号字面量 `` `,` `` 永不变。|
  custom-punct:     (:),       /// <- `dictionary`
    /// 精确覆盖某符号的字面量，优先级高于 `bib-punct-style`：列出的符号恒用用户值。\
    /// *作用对象是结构标点*——引擎产出的著录格式串符号（段间句点、页码冒号、著者间逗号、卷期括号等），*不触碰用户字段文本*（题名、出版者等原样）；唯一例外是显式开 #arg-ref("gb7714", "correct-punct")[`correct-punct`] 时，字段内*矫正*的目标字形跟随本表的 `text` 值（矫正是否发生由 `correct-punct` 决定，本表只定目标字形）。覆写值为*绝对*字面量，不再做全 / 半角感知（要感知用 `punct-style` 档位或各 `-separator` 的裸字符通道）。\
    /// 键 = 标点字符本身：`,` `:` `;` `.` `?` `!` `/` `(` `)` 九种结构标点之一，半角或全角都认（中文 IME 默认打全角，如 `（` 等价 `(`、`。` 等价 `.`）。也接住 Typst 原生写法 ```typ ((sym.paren.l): "〔")```（计算键被归一成字符 `"("`）。\
    /// 自定义模板 ```typ custom-drivers``` 里裸写的任意标点——含顿号 `、`、间隔号 `·` 等非结构标点——都能用该字符当键覆盖（反引号字面量 `` `,` `` 除外，永不变）。\
    /// 每个键的值有两种写法：\
    /// - 纯字符串：```typ custom-punct: (",": " ### ", "(": "〔", ")": "〕", ".": "。")```——逗号渲染为 ` ### `、括号变〔〕、句号强制全角；
    /// - 字典：须含 `text` 字段（字面字符），其余字段透传给 ```typc text(..)```（可用 `font` / `weight` / `size` / `fill` / `style` 等），如 ```typ ",": (text: "，", font: ("Source Han Serif SC", "Noto Serif CJK SC"))``` 用思源宋体渲染中文逗号、```typ ":": (text: "：", weight: "bold")``` 加粗冒号。\
    /// 字典里 `text` 之外的样式仅作用于引擎产出的符号（出版项 `: `、卷期 `( )`、著者间 `, ` 等）；`correct-punct` 矫正出的字段内标点仅读取 `text` 值、不套用字体 / 字重 / 字号。欲全局统一样式，请直接 ```typc #set text(font: (..))```。|
  correct-punct:       false,     /// <- `boolean`
    /// 是否矫正用户输入的标点。\
    /// - `false`（默认）：不矫正；
    /// - `true`：对长文本字段（`title` / `subtitle` / `titleaddon` / `maintitle` / `booktitle` 及一系列 `book*` / `journal*` / `eventtitle` / `series` / `note`，以及 `custom-terms.bib-field` 透传字段）做单字符替换：`,` 对 `，`、`;` 对 `；`、`!` 对 `！`、`?` 对 `？`，方向由 `bib-punct-style` 与条目语言决定。\
    /// 例：```typ gb7714(.., bib-punct-style: "by-entry-with-space", correct-punct: true)``` 下，```bib title = {我说;再说;还说}``` 渲染为「我说；再说；还说」；```bib title={Hi; Bye}, langid=english``` 渲染为 "Hi; Bye"（不动）。\
    /// 花括号保护：`{…}` 包裹的子串整段跳过矫正（花括号本身被剥离），如 ```bib title={外面;{内部;不矫正}外面;}, langid=chinese``` 渲染为「外面；内部;不矫正外面；」。\
    /// 矫正在初始化解析 `.bib` 前一次性完成，不支持 `cite()` / `bibliography(..)` 单次覆盖；欲切换须换一个 `gb7714(..)` 实例。|
  latex-strict-command: true,     /// <- `boolean`
    /// `.bib` 字段里遇到未定义 LaTeX 命令（拼写错 `\foobar`、CJK 紧贴吞名后的 `\textbf中` 等）时的行为。\
    /// - `true`（默认）：严格，渲染期报错，便于及早发现拼写错 / 漏写命令；
    /// - `false`：宽松，静默丢弃该命令、保留其后内容、继续渲染。\
    /// 与 `latex-strict-char` 各自独立。verbatim 字段（`url` / `doi` / `eprint`）不做 LaTeX 转换、不受影响。仅全局生效。|
  latex-strict-char:   true,      /// <- `boolean`
    /// `.bib` 字段里遇到未转义的 LaTeX 特殊字符 `&` `_` `#` `%` `^`，以及未配对的转义花括号 `\{` / `\}` 时的行为。\
    /// - `true`（默认）：严格，渲染期报错——这些字符在 LaTeX 文本模式下须写作 `\&` / `\_` / `\#` / `\%` / `\textasciicircum` 等转义形式；未配对花括号须改用 `\textbraceleft` / `\textbraceright`（或 `$\lbrace$` / `$\rbrace$`）或确保配对；
    /// - `false`：宽松，裸特殊字符按字面输出、未配对 `\{` / `\}` 亦容忍（适合来不及规范化转义的导入旧库）。\
    /// 与 `latex-strict-command` 各自独立。不影响 verbatim 字段（`url` / `doi` / `eprint` 中的 `&` `_` 恒原样）与数学环境（`$x_i$` 里的 `_` `^` 合法）。\
    /// 不受本开关影响的行为：未配对 `$`（数学定界符）恒报错、裸 `{` `}`（分组符）恒剥除。仅全局生效。|
  url-break-every:     1,         /// <- `none` | `int`
    /// URL / DOI / CSTR / 自定义链接形式标识符渲染时，每 N 个连续不可断字符后插入一个断点机会（断点是否显示连字符由 #arg-ref("gb7714", "url-break-hyphen")[`url-break-hyphen`] 决定），用于救济长域名 / 长查询段，避免两端对齐时溢出页面或行尾大块空白。\
    /// 作用于 URL、DOI、CSTR 与 `custom-terms` 中 `pid: true` 的自定义标识符（短号 ISBN / ISSN / eprint 不处理）。\
    /// - `1`（默认）：每个非分隔符字符后都插入断点机会，URL 任意位置可断行；
    /// - `none`：不插入额外断点；
    /// - `<int>`：每 N 个非分隔符字符后插入一个，如 `8` 即每 8 字符一个断点机会。\
    /// 分隔符（`.` `/` `-` `_` `:` `;` `,` `?` `&` `=` `#` `+` 等）是 URL 的天然断点，本项只作用于其间的连续字母 / 数字串，如 `very-long-endpoint-name-for-testing` 这类长片段。\
    /// `bibliography` / `cite(footnote: true)` 接受同名参数，`auto` 继承全局值。|
  url-break-hyphen:    false,     /// <- `boolean`
    /// URL / DOI / CSTR / 自定义标识符断点处是否显示连字符（总开关）。\
    /// - `false`（默认）：断点用零宽空格（U+200B），任意位置可断行但行末不显连字符，URL 复制干净、不会把连字符误读为 URL 的一部分；
    /// - `true`：断点落行末显示软连字符（U+00AD），便于识别续行；URL 自带的真实 `-` 不叠加、不会出现 `--`。覆盖范围由 #arg-ref("gb7714", "url-break-hyphen-at-delimiters")[`url-break-hyphen-at-delimiters`] 决定。\
    /// 仅 `bibliography` 接受同名参数（`auto` 继承全局值），`cite(footnote: true)` 走全局值。|
  url-break-hyphen-at-delimiters: true, /// <- `boolean`
    /// 与 #arg-ref("gb7714", "url-break-hyphen")[`url-break-hyphen`] 正交：显示连字符（`url-break-hyphen: true`）时，软连字符是否出现在 URL 分隔符（`: / ? # [ ] @ ! $ & ' ( ) * + , ; =` 等）的断点处。\
    /// - `true`（默认）：分隔符断点也显 `-`（含 `url-break-every` 救济断点）；
    /// - `false`：分隔符断点不显 `-`，仅 `url-break-every` 插入的长串救济断点显 `-`。\
    /// 三项正交：`url-break-every` 定在哪里断、`url-break-hyphen` 定断处是否显 `-`、本项定 URL 分隔符断点是否计入显示范围。`url-break-hyphen: false` 时本项无影响。|

  titles-text-case:    none,      /// <- `none` | `string` | `dictionary`
    /// 长标题类字段的大小写转换（替代已废除的 `sentence-case-title` 布尔）。\
    /// 标量值作用于全部白名单字段；字典按字段分设，`rest` 兜底。取值：\
    /// - `none`（默认）：不转换，按 `.bib` 原样（`raw(theme: none)` 同款「关处理、内容照显」语义）；
    /// - `"sentence"`：句首大写、其余小写（CSL `text-case="sentence"`）；
    /// - `"title"`：实词大写、小词小写、首末词恒大写（CSL `text-case="title"`，即 Title Case）。\
    /// 白名单 12 字段：`title` / `subtitle` / `titleaddon` / `maintitle` / `booktitle` / `booksubtitle` / `booktitleaddon` / `journaltitle`（`journal` 为其别名键，真名静默胜）/ `journalsubtitle` / `journaltitleaddon` / `eventtitle` / `series`；其余键 panic。`shortjournal` 不受理——缩写刊名的大小写即其规范。\
    /// 例：```typ titles-text-case: (title: "sentence", journaltitle: "title", rest: none)```。\
    /// `{}` 保护括号内两档都不动（biblatex 惯例）；含 CJK 的字段值整体跳过（大小写无意义，且内嵌拉丁词如 DNA 不得被改）。转换在解析期由 citegeist（Rust）按字段应用。|
  italic-book-title:   false,     /// <- `boolean`
    /// - `false`：西文专著 / 论文集题名（非析出）正体；
    /// - `true`：渲染为斜体。|
  italic-journal:      false,     /// <- `boolean`
    /// - `false`：期刊 / 报纸名正体；
    /// - `true`：渲染为斜体。|
  bold-journal-volume: false,     /// <- `boolean`
    /// - `false`：期刊卷号正常字重；
    /// - `true`：期刊卷号加粗。|
  period-after-creator: true,      /// <- `boolean`
    /// *责任者元素*之后是否加句点。\
    /// - `true`（默认）：加 `.`；
    /// - `false`：改用空格分隔。\
    /// 两制同构——句点落在*责任者元素*之后，而著者-出版年制的责任者元素是「责任者，出版年」*整块*（`ZUO Z, 2020. Titlex` → `ZUO Z, 2020 Titlex`）。\
    /// 责任者与年份之间那个逗号不归本参数管，用 #arg-ref("gb7714", "bib-name-date-separator")[`bib-name-date-separator`]。\
    /// 对应 biblatex 的 `\labelnamepunct`。|
  end-with-period:     true,      /// <- `boolean`
    /// - `true`：条目不以缩写点结尾时自动追加句号 `.`；
    /// - `false`：不追加。|
  space-before-mark:   false,     /// <- `boolean`
    /// - `false`：文献类型标识 [M] 前无空格；
    /// - `true`：前加空格。\
    /// 只作用于 `mark-medium` 这个封装 token（内置八驱动用的就是它）；`custom-drivers` 里的*裸* `mark` / `medium` token 不受它管——标识前的空格由模板自己写。|
  space-before-pages:  true,      /// <- `boolean`
    /// - `true`：页码前加空格（`: 123`）；
    /// - `false`：无空格（`:123`）。|
  page-range-separator:       "-",       /// <- `string` | `dictionary`
    /// 起讫页码连接符，接受任意字符串，如全角波浪线 `"～"`。裸标点字符（`","` 等）随 `bib-punct-style` 与条目语言全 / 半角感知；verbatim 定界 ```typc "{,}"``` 字面不感知。\
    /// *多语言字典*按*条目语言*分设：```typc page-range-separator: (zh: "～")``` 让中文条目出全角波浪线，*其余语言照旧*（走本参数的预设值，这里就是 `"-"`）。键是条目语言码（`zh` / `en` / `ja` / `ko` / `ru` / `fr`），写错的键（`cn:`）直接报错。另收一个 `rest` 兜底档改写「其余语言」那一档：```typc (zh: "～", rest: "–")``` 让未点名的语言出 en dash 而不是预设的 `"-"`（`rest` 的用法同 `show-url` / `titles-text-case`）。挑出来的值*再走上面那三态*——字典只负责挑值，挑出的若是裸标点字符，照样感知。字典档对*全部* `-separator` 配置生效（页码连接符、姓名四接缝、`name-date-separator` 两轴、`et-al-translator-separator`、`cite-range-separator`），不止本项。|
  page-range-style:    none,      /// <- `none` | `string`
    /// 起讫页码的*位数形态*——把 `pages` 里的起讫页重排成折叠或展开写法。与 #arg-ref("gb7714", "page-range-separator")[`page-range-separator`]（管*连接符*）正交：本项产出数字，连接符仍由它给。\
    /// - `none`（默认）：*页码原样*，一个数字都不动。GB/T 7714—2025 §7.7 对页码只规定「阿拉伯数字」，没有规定折叠还是展开——标准不要求，就不替用户决定；开档位即是用户显式同意「改写我的 `pages` 数据」。\
    /// - `"expanded"`：结束页补全（```bib pages={321-28}``` 得 `321-328`）；
    /// - `"minimal"`：只留变化的位（`321-328` 得 `321-8`）；
    /// - `"minimal-two"`：同上但至少两位（`321-328` 得 `321-28`）；
    /// - `"chicago-15"` / `"chicago-16"`：《芝加哥手册》的起讫页规则——起始页 < 100 或整百时全写（`100-104`）、百位后是「0x」时只写变化位（`101-7`）、否则至少两位（`321-28`）；两版只在四位数变三位时不同（`1496-1500` 对 `1496-500`）。CSL 1.0.1 的 `"chicago"` 收作 `"chicago-15"` 的别名。\
    /// 算法照搬 citationberg（Typst 原生 `bibliography()` 的 CSL 引擎），所以与原生 CSL 路由的输出逐字一致。\
    /// 边界：起讫两端的*前缀不同*就整段不动（`xii-xv` 的前缀是 `xii` 与 `xv`，罗马数字因此不受影响；`S12-S18` 的前缀同为 `S`，照常重排）。任一端没有数字也不动。结束页比起始页*长*的是真跨百（`98-103`），不是折叠，不补位。多段页码（`12-15, 20-25`）逐段处理。\
    /// 只作用于文献表的 `pages` 字段：`eid`（文章编号回退）不是范围，正文引用的 `supplement`（引文页码）是用户直接给的内容，都不参与。|
  hyphenate:       true,      /// <- `boolean`
    /// - `true`：参考文献表内允许西文断字；
    /// - `false`：禁用西文断字。|
  footnote-repeat-style:     auto,      /// <- `auto` | `string`
    /// 重复引用同一文献时脚注装什么（首次恒为完整著录——官方 note CSL 与全部社区方言一致）。
    /// 单值；紧邻位的「同上」简化由 #arg-ref("gb7714", "footnote-ibid")[`footnote-ibid`] 独立控制，两参正交出全部有据体例：\
    /// - `auto`（默认）：`"number"`——配合缺省 `footnote-ibid: true` 即官方 note CSL（china-national-standard-gb-t-7714-2015-note）的梯子：紧邻「同上(: 页码)」、隔开「同③(: 页码)」；
    /// - `"full"`：重复著录整条（GB §9.2.1.3「重复著录」正统，社区方言主流；与 `"shortened"` 对仗，即 CMOS 的 full note / shortened citation 逐字术语）；
    /// - `"number"`：同③（首注号,圈码自动镜像文档脚注编号样式，序号假定脚注全文连续编号；custom-terms 的 `footnote-number` 模式词键管它的前后缀与页码分隔——词汇表键在全局空间需完整域名，参数值在本参数域内无需重复前缀）；
    /// - `"shortened"`：缩略「责任者. 题名[标识].」（完整注的*缩减产物*，CMOS 术语；页码接独立著录段）；
    /// - `"reuse"`：*不发新注*，正文上标复用首注号——唯一装不下页码的值。\
    /// 「同上」「同」两词可经 #arg-ref("gb7714", "custom-terms")[`custom-terms`] 的 `ibid`（纯词）与 `footnote-number`（前后缀对）覆写，按*文档语言*取词。|
  footnote-ibid:       auto,      /// <- `auto` | `boolean`
    /// *紧邻*重复（上一条脚注引用就是同一文献，中间夹普通脚注不破坏）是否简化为「同上(: 页码)」：\
    /// - `auto`（默认）：`true`——官方 note CSL 梯子的紧邻档；
    /// - `false`：紧邻不特殊化，与隔开重复一样取 #arg-ref("gb7714", "footnote-repeat-style")[`footnote-repeat-style`] 的值（如 `"full"` 配 `false` = GB 纯重复著录；`"shortened"` 配 `false` = Chicago 17th 全缩略）。\
    /// 「同上」的页码语义走 CSL position 算法：与上次同页码时不重复页码；上次有页码本次没有时降级为隔开。|
  footnote-repeat-reset: none,    /// <- `none` | `selector`
    /// 重复判定的重置界（biblatex `citereset` 的对应物）。selector 的每个匹配处都是一道界，判定只认*最近一道界之后*的引用：    /// - `none`（默认）：全文一个域，现状；
    /// - selector：如 ```typc heading.where(level: 1)```（章界——同上不跨章、每章首次引用重新完整著录、「同③」只在本章内找注号）、任意标签（```typc <part-break>```，正文写 ```typ #[]<part-break>``` 手工插一道界）、元素函数（`heading` 任意级标题都切）、`.or()` 组合。    /// 只管*判定*，不动脚注编号——每章重编号是文档排版自己的事（```typc show heading.where(level: 1): it => { counter(footnote).update(0); it }```），但*每章重编号的文档必须同设本参数*，否则「同③」会跨章指向上一章的注号。`"reuse"` 内容物复用的是全局首注（原生标签只有一处），不受本参数影响。|
  footnote-numbering-use-quan:      false,      /// <- `boolean`
    /// 应用本包即接管脚注编号为带圈数字（国标示例的圈码形），缺省用 Unicode 带圈字符 ①～㊿
    /// （超过 50 退化为 (N)，依赖字体覆盖）。本项为 `true` 时改由 ```typ @preview/quan``` 包*绘制*
    /// 带圈数字（不受字体限制）。\
    /// 其它编号样式不设配置项：直接 ```typc set footnote(numbering: ..)``` 覆盖即可（set 在
    /// `show` 之内、后设者胜）；「同③」的引语号*自动镜像*文档当前的脚注编号样式，任何样式都跟对。\
    /// 字号 / 缩进 / 对齐等同样自行 `set footnote(...)` / `set footnote.entry(...)`。|

  custom-marks:      (:),       /// <- `dictionary`
    /// 配置级「条目类型 → 默认标识码」登记表——自造类型设码的正道入口，也可覆写内置类型的默认码。\
    /// - 键 = entry_type（小写，开放集）：```typ custom-marks: (dissertation: "D", software: "SW")``` 让 `@dissertation` 出 \[D\]、`@software` 改出 \[SW\]；
    /// - 值 = 标识码本体（非空字符串）；载体段不在此写——`/OL` 由 `medium` 字段与联机判据决定。\
    /// 链位：条目数据五通道（note 劫持 / usera / entrytypeid / entrysubtype / mark）之下、版本化类型默认之上——条目字段永远压配置，配置压内置默认。\
    /// 登记的自造码自动并入大写码键的合法集：`show-mark` / `show-url` / `show-pid` 字典与 `custom-drivers` 都能用 ```typ (SW: ..)``` 点名；码变则格式路由随之（码即身份）。|
  custom-drivers:    (:),       /// <- `dictionary`
    /// 用户自定义条目模板。dictionary 形式 `(<entry_type 或 大写标识码>: 「模板字符串」, ...)`：\
    /// - 命中后用自定义条目格式渲染，覆盖该类条目的所有内置格式逻辑；
    /// - 小写键 = entry_type，点名 `.bib` 里的类型（如 `patent` / `inproceedings`，含 `@standard` 等非 crate 标准类型）；
    /// - 大写键 = 文献类型标识码（GB/T 7714 附录 A 闭集，拼错报错），按版本中性语义类匹配——如 `D:` 一键接管全部学位论文；优先级 entry_type > 码；
    /// - 内部类别词（`monograph` / `component-part` / `serial-article` / `serial` / `electronic`）不是用户词汇，命中报错并给出改写指引；
    /// - 模板语法见手册「自定义条目格式」一节。|
  custom-terms:        (:),       /// <- `dictionary`
    /// 自定义*本地化字面量* token —— 既能*注册新词*、也能*覆盖内置词*（键决定用途，二合一）。带字段的 token 请用 #arg-ref("gb7714", "custom-fields")[`custom-fields`]，永久标识符请用 #arg-ref("gb7714", "custom-pids")[`custom-pids`]。\
    /// 值为字符串（语言无关）或多语言字典 `(zh: "见", en: "See")`——按条目语言取值，缺该语言时按字典插入顺序回退。\
    /// - *注册新词*（键为自创名）：例 ```typ custom-terms: (see: (zh: "见", en: "See"))``` 后，`custom-drivers` 模板里写 `see` 即按条目语言渲染「见」/「See」；
    /// - *覆盖内置词*（键 ∈ 封闭集合 `et-al` / `editor` / `translator` / `anon` / `sine-loco` / `sine-nomine` / `ma-thesis` / `phd-thesis`）：例 ```typ custom-terms: (et-al: (en: "et al"), editor: (zh: "编"))``` 把西文截断词改回无点、中文编者标签改成「编」。\
    /// 限制：键若撞了*内置结构 token*（如 `author` / `title` / `doi`）会 panic（覆盖内置词只支持上列封闭集合）；不得含 `field` / `prefix` / `pid` / `resolver` 等结构键（放错篮子，会 panic 引导到 custom-fields / custom-pids）。\
    /// 注：Typst 无 warning API，内置词键*拼错*（如 `et-la`）只会被当成「注册了个没人引用的死 token」静默无效，不报错。|
  custom-fields:       (:),       /// <- `dictionary`
    /// 自定义*字段* token：把 `.bib` 字段暴露成 `custom-drivers` 模板里可用的 token，可选加本地化前后缀。\
    /// - `auto`（纯透传，字段名 == token 名）：```typ custom-fields: (myarxiv: auto)``` 后模板里 `myarxiv` 直接读 ```typ entry.field.myarxiv``` 原值；
    /// - 字典 `(field: "xxx", prefix:.., suffix:..)`：读 `xxx` 字段并在前 / 后拼固定文本。例 ```typ (myref: (field: "userref", prefix: "abc: "))```，```bib userref = {hello}``` 渲染为 `abc: hello`。`prefix` / `suffix` 接受字符串或多语言字典 ```typ (zh: "见: ", en: "See: ")```，按条目语言择一；字段缺失则该 token 为空。\
    /// 字段值同其它显示字段走 LaTeX→Typst 处理（`\textbf{}` / 引号连字 / 转义正常，未定义命令优雅降级）。\
    /// 限制：token 名不与内置 token 同名；`field` 取值不能与本包内部已用字段名冲突。|
  custom-pids:         (:),       /// <- `dictionary`
    /// *永久标识符*入口,一箭双雕:键是*自创名*就*注册新* PID(URN / Handle 等),键 ∈ `doi` / `cstr` / `isbn` / `issn` / `eprint` 就*覆写内置* PID。均著录于条目末尾「获取和访问路径」区。\
    /// 值为字典 `(field: "xxx", prefix:.., resolver:..)`:从 `field` 字段读值,标签取 `prefix`(或 `field` 名,自动补冒号)。\
    /// - *注册新* PID(必须给 `field`):例 ```typ custom-pids: (myurn: (field: "urn"))```,```bib urn = {urn:nbn:...}``` 渲染为 `URN:urn:nbn:...`;
    /// - *覆写内置* PID(`field` 可省,缺则读默认字段):例 ```typ custom-pids: (doi: (resolver: "https://doi.company.com/{}"), isbn: (prefix: "书号"))``` 把 DOI 换成机构镜像解析器、ISBN 标签改成「书号」;也可 ```typ (doi: (field: "mydoi"))``` 让 DOI 改读别的字段。\
    /// 可点击跳转(#arg-ref("gb7714", "hyperlink")[`hyperlink`] 为 `true` 时):值为 URL(`http`/`https`/`ftp` 开头)时链到自身;否则 `resolver` 模板——含 `{}` 占位则替换字段值、否则当前缀拼接。例 ```typ (handle: (field: "handle", prefix: "HDL", resolver: "https://hdl.handle.net/"))``` 把 ```bib handle = {20.500/abc}``` 链到 ```typ https://hdl.handle.net/20.500/abc```。\
    /// 配合 #arg-ref("gb7714", "show-pid")[`show-pid`] / #arg-ref("gb7714", "pid-priority")[`pid-priority`] / #arg-ref("gb7714", "dedup-url-pid")[`dedup-url-pid`] 使用。\
    /// 限制:新 PID 名不与内置结构 token 同名;新 PID 的 `field` 不与内部已用字段名冲突;永久标识符只在条目末尾渲染,不作 `custom-drivers` 模板 token(模板里放整块请用内置 `access` token)。|
  warn-missing-title:  false,     /// <- `boolean`
    /// 缺题名时是否报错。GB/T 7714 要求每条文献都著录题名。\
    /// - `false`（默认）：缺 / 空 title 软退化为空题名槽，照常渲染；
    /// - `true`：任一非特殊类型条目缺 / 空 title 即报错并指明该键，令缺失早暴露。|
) = {

  version = _coerce-version(version)

  let punct-style = bib-punct-style
  let name-style = bib-name-style
  let et-al-min = bib-et-al-min
  let et-al-use-first = bib-et-al-use-first
  let et-al-use-last = bib-et-al-use-last
  let name-date-separator = bib-name-date-separator
  validate-terms(custom-terms)
  validate-fields(custom-fields)
  validate-pids(custom-pids)
  punct-custom.validate-punct(custom-punct)

  let _version-auto = (
    prefix-last: prefix-last == auto,
    dedup-url-pid: dedup-url-pid == auto,
    punct-style: punct-style == auto,
    name-suffix-separator: name-suffix-separator == auto,
  )

  let _name-style-raw = name-style
  let name-style = creators.resolve-name-style(name-style, version: version, side: "bib")

  if prefix-last == auto { prefix-last = (version == 2025) }

  if dedup-url-pid == auto { dedup-url-pid = (version == 2025) }

  if punct-style == auto { punct-style = if version == 2025 { "full" } else { "half-with-space" } }

  if name-suffix-separator == auto { name-suffix-separator = if version == 2025 { " " } else { ", " } }

  let page-range-style = pages.normalize-page-range-style(page-range-style)
  let footnote-repeat-style = footnote-cite.normalize-footnote-repeat-style(footnote-repeat-style)
  let footnote-ibid = footnote-cite.normalize-footnote-ibid(footnote-ibid)
  let footnote-repeat-reset = footnote-cite.normalize-footnote-repeat-reset(footnote-repeat-reset)

  let _format-footnote-number(n) = numbering(std.footnote.numbering, n)

  if show-anon == auto { show-anon = (style.at("bib", default: style.at("cite", default: "numeric")) == "author-date") }

  if show-no-date == auto { show-no-date = (style.at("bib", default: style.at("cite", default: "numeric")) == "author-date") }
  let _cite-form-state = state("gb7714-cite-form-override", auto)
  let _cite-style-state = state("gb7714-cite-style-override", auto)
  let _cite-punct-style-state = state("gb7714-cite-punct-style-override", auto)
  let _cite-supplement-style-state = state("gb7714-cite-supplement-style-override", auto)
  let _cite-name-style-state = state("gb7714-cite-name-style-override", auto)
  let _cite-merge-state = state("gb7714-cite-merge-override", auto)

  let _cite-nomerge = state("gb7714-cite-nomerge", false)

  let _cite-footnote-override = state("gb7714-cite-footnote-override", auto)

  let _biblioref-seen = state("gb7714-biblioref-seen", ())
  let _cite-et-al-min-state = state("gb7714-cite-et-al-min-override", auto)
  let _cite-et-al-use-first-state = state("gb7714-cite-et-al-use-first-override", auto)
  let _cite-et-al-use-last-state = state("gb7714-cite-et-al-use-last-override", auto)
  let _cite-terms-lang-state = state("gb7714-cite-terms-lang-override", auto)
  let _cite-compress-min-state = state("gb7714-cite-compress-min-override", auto)
  let _cite-sort-by-state = state("gb7714-cite-sort-by-override", auto)
  let _cite-sort-zh-by-state = state("gb7714-cite-sort-zh-by-override", auto)
  let _cite-collapse-date-state = state("gb7714-cite-collapse-date-override", auto)
  let _cite-range-separator-state = state("gb7714-cite-range-separator-override", auto)

  let _lsp-bib-active = state("gb7714-lsp-bib-active", false)

  let bib-file-keys = (:)
  let bib-parts = ()

  let _assert-bib-content(s, description) = {
    let str-s = str(s)
    if not str-s.contains(regex("@\\w+\\s*\\{")) {
      errors.raise("load.not-bib-content", what: description,
        value: if str-s.len() > 60 { str-s.slice(0, 60) + "…" } else { str-s })
    }
  }

  if type(path) == dictionary {
    for (label, content) in path {
      _assert-bib-content(content, "字典 key `" + label + "` 对应的值")
      let keys = bib-keys(content)
      bib-file-keys.insert(label, keys)
      bib-parts.push(content)
    }
  } else if type(path) == array {
    for (i, content) in path.enumerate() {
      _assert-bib-content(content, "数组第 " + str(i + 1) + " 项")
      bib-parts.push(content)
    }
  } else if type(path) == str {
    _assert-bib-content(path, "path 参数")
    bib-parts.push(path)
  } else {
    errors.raise("load.bad-path-type")
  }
  let bib-string = bib-parts.join("\n")

  bib-string = bib-string.replace(
    regex("(?i)(,\\s*)address(\\s*=)"),
    m => m.captures.at(0) + "location" + m.captures.at(1),
  )

  bib-string = bib-string.replace(
    regex("(?i)(,\\s*)nameatype(\\s*=)"),
    m => m.captures.at(0) + "editoratype" + m.captures.at(1),
  )
  bib-string = bib-string.replace(
    regex("(?i)(,\\s*)namea(\\s*=)"),
    m => m.captures.at(0) + "editora" + m.captures.at(1),
  )

  bib-string = bib-string.replace("\\\\", _SLB)
  bib-string = bib-string.replace("\\$", _SD)
  bib-string = bib-string.replace(regex("\\\\textasciitilde(\\{\\}|\\s)?"), _ST)
  bib-string = bib-string.replace(regex("\\\\textasciicircum(\\{\\}|\\s)?"), _SCIRC)
  bib-string = bib-string.replace(regex("\\\\textbackslash(\\{\\}|\\s)?"), _SBS)

  bib-string = bib-string.replace(regex("\\\\textbraceleft(\\{\\}|\\s)?"), _SLBR)
  bib-string = bib-string.replace(regex("\\\\textbraceright(\\{\\}|\\s)?"), _SRBR)

  bib-string = bib-string.replace(regex("\\\\textunderscore(\\{\\}|\\s)?"), _SUND)
  bib-string = bib-string.replace(regex("\\\\textdollar(\\{\\}|\\s)?"), _SD)

  bib-string = bib-string.replace("\\&", _SAMP).replace("\\_", _SUND).replace("\\#", _SHSH).replace("\\%", _SPCT)

  if latex-strict-char and bib-string.matches("\\{").len() != bib-string.matches("\\}").len() {
    assert(false, message: "omni-gb7714: bib 中存在未配对的转义花括号 `\\{` / `\\}`（真 biblatex 下会打乱 biber 的花括号计数、导致解析失败——`\\{`/`\\}` 不是可靠写法）。\n— 字面花括号*推荐*用 `\\textbraceleft` / `\\textbraceright`（或 `$\\lbrace$` / `$\\rbrace$`）：它们不参与花括号计数、未配对也安全；\n— 或确保 `\\{` 与 `\\}` 成对出现；\n— 要让本包*容忍*未配对（宽松），设 `gb7714(latex-strict-char: false)`。")
  }

  bib-string = bib-string.replace("\\{", _SLBR).replace("\\}", _SRBR)

  bib-string = latex.normalize-decls(bib-string)

  if calc.rem(bib-string.matches("$").len(), 2) != 0 {
    assert(false, message: "omni-gb7714: bib 中存在未配对的数学定界符 `$`（biblatex 下等价错误：“! Missing $ inserted.”）。\n— 要表示*字面美元符*，请写 `\\$`；\n— 要写*数学公式*，请成对使用 `$...$`（每个字段值内自闭合）。")
  }

  if correct-punct {
    bib-string = punct.preprocess(bib-string, punct-style, custom-punct)
  }

  let _ttc-fields = ("title", "subtitle", "titleaddon", "maintitle", "booktitle", "booksubtitle", "booktitleaddon", "journaltitle", "journalsubtitle", "journaltitleaddon", "eventtitle", "series")
  let _ttc-map = if std.type(titles-text-case) == dictionary {
    for (k, v) in titles-text-case {
      if k not in _ttc-fields and k != "journal" and k != "rest" { errors.raise("titles-text-case.bad-key", key: k) }
      if v not in (none, "sentence", "title") { errors.raise("titles-text-case.bad-value", key: k, value: repr(v)) }
    }
    let rest = titles-text-case.at("rest", default: none)
    let m = (:)
    for f in _ttc-fields {
      let v = titles-text-case.at(f, default: auto)

      if f == "journaltitle" and v == auto { v = titles-text-case.at("journal", default: auto) }
      m.insert(f, if v == auto { rest } else { v })
    }
    m
  } else {
    errors.check-enum("titles-text-case", titles-text-case)
    let m = (:)
    for f in _ttc-fields { m.insert(f, titles-text-case) }
    m
  }
  let _ttc-mode(v) = if v == "sentence" { "1" } else { "2" }
  let _ttc-parts = ()
  for pr in _ttc-map.pairs() {
    if pr.at(1) != none {
      _ttc-parts.push(pr.at(0) + "=" + _ttc-mode(pr.at(1)))

      if pr.at(0) == "journaltitle" { _ttc-parts.push("journal=" + _ttc-mode(pr.at(1))) }
    }
  }
  let _ttc-payload = _ttc-parts.join("," , default: "")
  let bib-data = load-bibliography(bib-string, keep-raw-names: true, sentence-case-titles: false, text-case: _ttc-payload)

  let _set-redirect = entryset.redirect(bib-data)

  let bib-key-order = bib-data.keys()

  let _dynamic-type-to-mark = (:)
  if version == 2025 {
    _dynamic-type-to-mark.insert("preprint", "PP")
  }

  let _audiovisual-types = ("image", "video", "audio", "artwork", "music", "movie", "performance")

  let _user-marked-keys = ()
  for (k, e) in bib-data {
    if e.fields.at("usera", default: none) != none or e.fields.at("entrytypeid", default: none) != none or e.fields.at("mark", default: none) != none { _user-marked-keys.push(k) }
  }
  let _patched = (:)
  for (k, e) in bib-data {
    let raw = e.entry_type

    let mark = if raw in _audiovisual-types { if field.has-online(e) { "EB" } else { "Z" } } else { _dynamic-type-to-mark.at(raw, default: none) }
    if mark != none {
      let new-fields = e.fields
      new-fields.insert("_omni-mark-override", mark)
      let new-entry = e
      new-entry.fields = new-fields
      _patched.insert(k, new-entry)
    } else {
      _patched.insert(k, e)
    }
  }
  bib-data = _patched

  mark-custom.validate-marks(custom-marks)
  bib-data = mark-custom.apply-marks(bib-data, custom-marks)
  let _registered-marks = mark-custom.registered-marks(custom-marks)

  {
    let _base-patched = (:)
    for (k, e) in bib-data {
      if k not in _user-marked-keys {
        let new-fields = e.fields
        new-fields.insert("_omni-mark-base", mark-medium.mark(e))
        new-fields.insert("_omni-rawtype", e.entry_type)
        let new-entry = e; new-entry.fields = new-fields
        _base-patched.insert(k, new-entry)
      } else { _base-patched.insert(k, e) }
    }
    bib-data = _base-patched
  }

  if version == 2025 {
    let _ver-type-overrides = (unpublished: "A")
    let _patched-ver = (:)
    for (k, e) in bib-data {
      let type-override = _ver-type-overrides.at(e.entry_type, default: none)
      if type-override != none {
        let new-fields = e.fields; new-fields.insert("_omni-mark-override", type-override)
        let new-entry = e; new-entry.fields = new-fields
        _patched-ver.insert(k, new-entry)
      } else { _patched-ver.insert(k, e) }
    }
    bib-data = _patched-ver
  }

  if version == 2005 {
    let _patched-05 = (:)
    for (k, e) in bib-data {

      let remap = if e.entry_type != "preprint" {
        let current-mark = mark-medium.mark(e)
        if current-mark in ("A", "DS", "CM") { "Z" } else if current-mark == "Z" { "M" } else { none }
      } else { none }
      if remap != none {
        let new-fields = e.fields; new-fields.insert("_omni-mark-override", remap)
        let new-entry = e; new-entry.fields = new-fields
        _patched-05.insert(k, new-entry)
      } else { _patched-05.insert(k, e) }
    }
    bib-data = _patched-05
  }

  let _has-no-explicit-mark(e) = {
    let no-usera = e.fields.at("usera", default: none) == none
    let no-eid = e.fields.at("entrytypeid", default: none) == none
    let no-mark = e.fields.at("mark", default: none) == none
    no-usera and no-eid and no-mark
  }
  let _routed = (:)
  for (k, e) in bib-data {
    let is-2015-preprint = (version != 2025) and (e.entry_type == "preprint") and _has-no-explicit-mark(e)
    let _has-preprint-subtype = {
      let subtype = e.fields.at("entrysubtype", default: none)
      subtype != none and lower(str(subtype)) == "preprint"
    }

    let _is-prepublished = {
      let pubstate-val = e.fields.at("pubstate", default: none)
      pubstate-val != none and lower(str(pubstate-val)) == "prepublished"
    }
    let is-2025-preprint = (version == 2025) and _has-no-explicit-mark(e) and (
      (e.entry_type == "article" and (_has-arxiv-fields(e) or _has-preprint-subtype)) or _is-prepublished
    )

    let is-article-preprint = (version != 2025) and (e.entry_type == "article") and _is-preprint-routed(e)
    if is-2015-preprint {

      let new-fields = e.fields
      if new-fields.at("entrysubtype", default: none) == none {
        new-fields.insert("entrysubtype", "preprint")
      }
      new-fields.insert("_omni-mark-override", _preprint-mark(version))

      let new-entry = e
      new-entry.insert("entry_type", "article")
      new-entry.insert("fields", new-fields)
      _routed.insert(k, new-entry)
    } else if is-article-preprint {
      let new-fields = e.fields
      new-fields.insert("_omni-mark-override", _preprint-mark(version))
      let new-entry = e
      new-entry.fields = new-fields
      _routed.insert(k, new-entry)
    } else if is-2025-preprint {

      let new-fields = e.fields
      new-fields.insert("_omni-mark-override", "PP")
      let new-entry = e
      new-entry.fields = new-fields
      _routed.insert(k, new-entry)
    } else {
      _routed.insert(k, e)
    }
  }
  bib-data = _routed

  let _use-accurate = (
    if entry-lang-detect == "accurate" { true }
    else if entry-lang-detect == "auto" { language.bib-has-japanese(bib-data) }
    else { false }
  )
  if _use-accurate {
    let _detected = (:)
    for (_k, _e) in bib-data {
      if _e.fields.at("langid", default: none) == none and _e.fields.at("language", default: none) == none {
        let _fields = _e.fields
        _fields.insert("langid", language.detect-accurate(_e))
        _e.fields = _fields
      }
      _detected.insert(_k, _e)
    }
    bib-data = _detected
  }

  if date-fallback != none {
    let _field-name = str(date-fallback)
    let _filled = (:)
    for (_k, _e) in bib-data {
      let _has-year = _e.fields.at("date", default: none) != none or _e.fields.at("year", default: none) != none

      let _is-platform-form = category.is-platform-form(_e, version: version)
      let _source = _e.fields.at(_field-name, default: none)
      if not _has-year and not _is-platform-form and _source != none {
        let _year = str(_source).split("-").first().trim()
        if _year != "" {
          let _fields = _e.fields
          _fields.insert("year", _year + "~")
          _e.fields = _fields
        }
      }
      _filled.insert(_k, _e)
    }
    bib-data = _filled
  }

  if warn-missing-title {
    for (_k, _e) in bib-data {
      if _e.entry_type in _SPECIAL-ENTRY-TYPES { continue }
      let _t = _e.fields.at("title", default: none)
      let _t-empty = _t == none or (type(_t) == str and _t.trim() == "")
      if _t-empty {
        errors.raise("load.missing-title", key: _k)
      }
    }
  }

  let _active-list = state("gb7714-active-list", none)

  let _list-style-map = state("gb7714-list-style-map", (:))

  let _list-footnote-map = state("gb7714-list-footnote-map", (:))
  let _main-footnote = state("gb7714-main-list-footnote", auto)

  let _list-ids = state("gb7714-list-ids", (:))

  let _list-suffix-map = state("gb7714-list-suffix-map", (:))
  /**
  = `set-bib-label` — 切换引用列表 <set-bib-label>

  将后续 ```typ @key```（或 ```typ #cite()```）引用归属到指定的参考文献列表，
  配合 ```typ #bibliography(.., label: "..")``` 可实现多参考文献列表分区排版。

  传入 `none` 则恢复到主列表。引用格式由对应列表的
  ```typ #bibliography(.., label: "..", style: "..")``` 决定。

  ```typ
  #set-bib-label("sec2") // 切换到新的参考文献列表，此列表的标签为 "sec2"
  @zhang2020@li2021      // 这两条引用的格式由对应列表的 style 决定

  = 第二节参考文献
  #bibliography(
    read("refs.bib"),
    label: "sec2",       // 打印标签为 "sec2" 的参考文献列表
    style: "author-date" // 本列表样式（含其归属引用的行内形态）；缺省跟随全局
  )

  #set-bib-label(none)   // 恢复主参考文献列表
  #bibliography(read("refs.bib"))
  ```
  **/
  let set-bib-label(
    list-label, /// <- `string` | `none` <`required`>
      /// 列表标签；`none` 恢复到主列表。|
  ) = {
    _active-list.update(list-label)
    if list-label != none {
      _list-ids.update(m => { if list-label not in m { m.insert(list-label, str(m.len() + 1)) }; m })
    }
  }

  let _extract-refs(c) = {
    if type(c) != content { return () }
    if c.func() == std.ref { return (c,) }
    if c.has("children") {
      let result = ()
      for child in c.children { result += _extract-refs(child) }
      return result
    }
    if c.has("body") { return _extract-refs(c.body) }
    ()
  }

  let _sort-keys-content = sort-keys
  let sort-keys = if sort-keys == none { none }
    else { _extract-refs(sort-keys).map(r => str(r.target)) }

  let cite-name-style-eff = creators.resolve-name-style(cite-name-style, version: version, side: "cite")

  let disambiguate = author-date-cite.normalize-disambiguate(disambiguate)

  let _cite-axis-author-date = style.at("cite", default: "numeric") == "author-date"
  let _escalate-given-name = disambiguate.given-name == true or (disambiguate.given-name == auto and _cite-axis-author-date)
  let _expand-names = disambiguate.names == true or (disambiguate.names == auto and _cite-axis-author-date)
  let _disambiguation = author-date-cite.disambiguation(bib-data, cite-et-al-min: cite-et-al-min, cite-et-al-use-first: cite-et-al-use-first, name-style: cite-name-style-eff, sort-keys: sort-keys, escalate-given-name: _escalate-given-name, expand-names: _expand-names)

  let _author-date-cite-label(key, name-format: cite-name-style-eff, suffixes: none, escalations: none, name-separator: ", ", et-al-min: auto, et-al-use-first: auto, et-al-use-last: auto, parts: false, name-punct-style: "half-with-space", terms-lang: "by-entry", document-lang: "en") = {
    let entry = bib-data.at(key, default: none)
    if entry == none { return if parts { (author: key, year: "", delim: "") } else { key } }
    let _et-al-min = _api-pick(et-al-min, cite-et-al-min)
    let _et-al-use-first = _api-pick(et-al-use-first, cite-et-al-use-first)
    let _et-al-use-last = _api-pick(et-al-use-last, cite-et-al-use-last)

    let _escalation-table = if escalations != none { escalations } else { _disambiguation.escalations }
    let _escalation = _escalation-table.at(key, default: (use-first: none, given-form: none))
    if _escalation.use-first != none { _et-al-use-first = _escalation.use-first }
    let _first-name-style = if _escalation.given-form != none { let d = name-format; d.insert("given-form", _escalation.given-form); d } else { none }
    let author = author-date-cite.author-short(entry, cite-et-al-min: _et-al-min, cite-et-al-use-first: _et-al-use-first, cite-et-al-use-last: _et-al-use-last, name-style: name-format, first-name-style: _first-name-style, terms-lang: terms-lang, document-lang: document-lang, sort-use-prefix: sort-use-prefix, name-separator: name-separator, name-suffix-separator: name-suffix-separator, custom-terms: custom-terms, punct-style: name-punct-style)

    let creator-empty = false
    if author == none {

      let lbl-field = punct.field-text(entry, "label")
      if lbl-field != none { return if parts { (author: lbl-field, year: "", delim: "") } else { lbl-field } }

      if entry.entry_type == "set" { return if parts { (author: key, year: "", delim: "") } else { key } }

      if show-anon {
        author = terms.anon-for(terms.cite-term-lang(terms-lang, "anon", entry, document-lang), custom-terms: custom-terms)
      } else { author = ""; creator-empty = true }
    }
    let year = publication-date.year(entry)
    let suffix-table = if suffixes != none { suffixes } else if disambiguate.date == false { (:) } else { _disambiguation.cite-suffixes }
    let suffix = suffix-table.at(key, default: "")

    let year-part = if year != none { publication-date.with-suffix(year, suffix) }
      else if show-no-date {
        let word = terms.no-date-for(terms.cite-term-lang(terms-lang, "no-date", entry, document-lang), custom-terms: custom-terms)
        if suffix != "" { word + "-" + suffix } else { word }
      } else { "" }

    let cite-name-date-separator = if std.type(cite-name-date-separator) == dictionary {
      punct.pick-separator-by-lang(cite-name-date-separator, language.get(entry), auto)
    } else { cite-name-date-separator }

    let _name-date-delim = if cite-name-date-separator in (",", "，") { name-separator }

      else if cite-name-date-separator != auto { punct.unwrap-separator(cite-name-date-separator).text }
      else if version == 2005 and not punct.is-cj-entry(entry) { " " }
      else { name-separator }

    let _name-date-delim = if creator-empty { "" } else { _name-date-delim }

    if parts { return (author: author, year: year-part, delim: _name-date-delim) }
    if year-part == "" { author } else { author + _name-date-delim + year-part }
  }

  let global-style-cite = style.at("cite", default: "numeric")
  let global-style-bib = style.at("bib", default: global-style-cite)

  let _global-config = (style-cite: global-style-cite, style-bib: global-style-bib, disambiguate: disambiguate, version: version, entry-hanging-indent: entry-hanging-indent, entry-first-line-indent: entry-first-line-indent, hyphenate: hyphenate, entry-spacing: entry-spacing, number-gutter: number-gutter, numbering-style: numbering-style, number-placement: number-placement, number-align: number-align, number-width: number-width, bold-journal-volume: bold-journal-volume, page-range-separator: page-range-separator, page-range-style: page-range-style, end-with-period: end-with-period, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, hyperlink: hyperlink, italic-book-title: italic-book-title, italic-journal: italic-journal, entry-lang-order: entry-lang-order, name-style: name-style, show-anon: show-anon, show-no-date: show-no-date, show-et-al: show-et-al, dedup-author-editor: dedup-author-editor, name-suffix-separator: name-suffix-separator, et-al-translator-separator: et-al-translator-separator, name-date-separator: name-date-separator, period-after-creator: period-after-creator, short-journal: short-journal, show-mark: show-mark, show-medium: show-medium, show-sine-loco: show-sine-loco, show-sine-nomine: show-sine-nomine, show-sine-anno: show-sine-anno, show-patent-country: show-patent-country, show-related: show-related, show-url: show-url, show-urldate: show-urldate, space-before-mark: space-before-mark, space-before-pages: space-before-pages, hyperlink-title: hyperlink-title, back-ref: back-ref, show-degree: show-degree, show-series: show-series, prefix-last: prefix-last, custom-drivers: custom-drivers, custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids, correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid, show-annotation: show-annotation, creator-idem: creator-idem, bib-sort-by: bib-sort-by, cite-sort-by: cite-sort-by, bib-sort-zh-by: bib-sort-zh-by, cite-sort-zh-by: cite-sort-zh-by, cite-collapse-date: cite-collapse-date, sort-use-prefix: sort-use-prefix, volume-title-gutter: volume-title-gutter, custom-marks: custom-marks, _registered-marks: _registered-marks, _name-style-raw: _name-style-raw, _version-auto: _version-auto)

  let _format-opts = (show-sine-loco: show-sine-loco, show-sine-nomine: show-sine-nomine, show-sine-anno: show-sine-anno, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-url: show-url, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, end-with-period: end-with-period, hyperlink: hyperlink, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, page-range-separator: page-range-separator, page-range-style: page-range-style, period-after-creator: period-after-creator, show-et-al: show-et-al, name-style: name-style, hyperlink-title: hyperlink-title, dedup-author-editor: dedup-author-editor, show-degree: show-degree, show-series: show-series, prefix-last: prefix-last, name-suffix-separator: name-suffix-separator, et-al-translator-separator: et-al-translator-separator, version: version, volume-title-gutter: volume-title-gutter)
  let _emit-entry(entry, show-anon: show-anon, skip-date: false, date-suffix: "", pages-override: none, creator-override: none, custom-drivers: custom-drivers, custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids, correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid, show-annotation: show-annotation) = {

    dispatch.entry(entry, .._format-opts, show-anon: show-anon, skip-date: skip-date, date-suffix: date-suffix, pages-override: pages-override, creator-override: creator-override, registered-marks: _global-config.at("_registered-marks", default: ()), custom-drivers: custom-drivers, custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids, correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid, show-annotation: show-annotation)
  }

  let _get-related(entry) = {
    let k = _get-related-key(entry)
    if k != none { bib-data.at(k, default: none) } else { none }
  }

  let _emit-entry-author-date(entry, suffix-key: none, show-anon: show-anon, suffixes: none, pages-override: none, creator-override: none, custom-drivers: custom-drivers, custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids, correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid, show-annotation: show-annotation) = {

    let _author-date-roles = creators.default-roles(entry, component-part: category.get(entry, version: version) == "component-part")

    let _escalation = if suffix-key != none { _disambiguation.escalations.at(suffix-key, default: (use-first: none, given-form: none)) } else { (use-first: none, given-form: none) }
    let _first-name-style = if _escalation.given-form == "full" { let d = name-style; d.insert("given-form", "full"); d } else { none }
    let author = creators.principal(entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-anon: show-anon, show-et-al: show-et-al, name-style: name-style, first-name-style: _first-name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: custom-terms, name-suffix-separator: name-suffix-separator, roles: _author-date-roles, prefix-last: prefix-last)
    let suffix-table = if suffixes != none { suffixes } else if disambiguate.date == false { (:) } else { _disambiguation.cite-suffixes }

    let author = if creator-override != none { creator-override } else { author }

    let author-date = _author-date-prefix(author, entry, suffix-table, suffix-key, punct-style: punct-style, custom-punct: custom-punct, version: version, name-date-separator: name-date-separator, show-no-date: show-no-date, custom-terms: custom-terms)

    let rest = dispatch.entry(entry, .._format-opts, show-anon: true, skip-date: true, skip-creator: true, pages-override: pages-override, registered-marks: _global-config.at("_registered-marks", default: ()), custom-drivers: custom-drivers, custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids, correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid, show-annotation: show-annotation)
    _author-date-join(author-date, rest, period-after-creator, entry, punct-style, custom-punct)
  }

  let _bib-link(anchor-string, list-label, bib-key, body) = {

    let loc = omni-aux.bib-anchor-map().at(anchor-string, default: none)
    if loc == none {

      body
    } else if _IS-HTML {

      let ref-id = _anchor-id(anchor-string) + "-ref"
      [#context {
        let attrs = (href: "#" + _anchor-id(anchor-string), role: "doc-biblioref")
        if ref-id not in _biblioref-seen.get() { attrs.insert("id", ref-id) }
        html.elem("a", attrs: attrs, body)
      }#_biblioref-seen.update(s => if ref-id in s { s } else { s + (ref-id,) })]
    } else {
      link(loc, body)
    }
  }

  let _assemble-footnote-render-options(overrides: (:)) = {
    let _pick-override(name, fallback) = _api-pick(overrides.at(name, default: auto), fallback)
    let related-indent-value = overrides.at("footnote-related-indent", default: auto)

    let indent = if related-indent-value == auto {
      context {
        let n = counter(std.footnote).get().first()
        h(std.footnote.entry.indent + measure(super(numbering(std.footnote.numbering, n))).width + 0.05em)
      }
    }
      else if related-indent-value != none { related-indent-value }
      else { [] }
    let eff-custom-drivers = _pick-override("custom-drivers", _global-config.custom-drivers)
    let eff-custom-terms = _pick-override("custom-terms", _global-config.custom-terms)
    let eff-custom-fields = _pick-override("custom-fields", _global-config.custom-fields)
    let eff-custom-pids = _pick-override("custom-pids", _global-config.custom-pids)

    let eff-punct-style  = punct.resolve-bib-document(_pick-override("footnote-punct-style", _global-config.punct-style), text.lang)
    let eff-custom-punct  = _pick-override("footnote-custom-punct", _global-config.custom-punct)

    let eff-correct-punct  = _global-config.correct-punct
    let eff-url-break-every = _pick-override("footnote-url-break-every", _global-config.url-break-every)

    let eff-show-pid = _pick-override("show-pid", _global-config.show-pid)
    mark-medium.validate-setting-keys(eff-show-pid, "show-pid", extra-marks: _global-config.at("_registered-marks", default: ()))
    let eff-pid-priority = _pick-override("pid-priority", _global-config.pid-priority)
    let eff-dedup-url-pid  = _pick-override("dedup-url-pid", _global-config.dedup-url-pid)
    let eff-show-annotation   = _pick-override("show-annotation", _global-config.show-annotation)

    let style-override = overrides.at("style", default: auto)
    let eff-style = if style-override != auto and type(style-override) == str and style-override in ("numeric", "author-date") { style-override } else { global-style-cite }
    (
      indent: indent, eff-style: eff-style, bib-style: global-style-bib, show-url: show-url, eff-show-annotation: eff-show-annotation,
      end-with-period: end-with-period, eff-custom-drivers: eff-custom-drivers, version: version,
      eff-punct-style: eff-punct-style, eff-custom-punct: eff-custom-punct,
      _emit-entry-author-date: _emit-entry-author-date, _emit-entry: _emit-entry,
      eff-custom-terms: eff-custom-terms, eff-custom-fields: eff-custom-fields, eff-custom-pids: eff-custom-pids,
      eff-correct-punct: eff-correct-punct, eff-url-break-every: eff-url-break-every,
      eff-show-pid: eff-show-pid, eff-pid-priority: eff-pid-priority, eff-dedup-url-pid: eff-dedup-url-pid,
      _get-related: _get-related, _set-redirect: _set-redirect, bib-data: bib-data,
      footnote-repeat-style: footnote-repeat-style, footnote-ibid: footnote-ibid, footnote-repeat-reset: footnote-repeat-reset,
      cite-terms-lang: cite-terms-lang,
      format-footnote-number: _format-footnote-number,
      _active-list: _active-list, _bib-link: _bib-link,
      show-anon: show-anon, show-et-al: show-et-al,
      _global-config: _global-config, show-mark: show-mark, show-medium: show-medium,
      space-before-mark: space-before-mark, correct-punct: correct-punct,
    )
  }

  /**
  = `cite` — 手动引用 <cite-fn>

  在 ```typ @key``` 原生语法的基础上做了多项扩展：可一次合并多条、附加 `supplement` 页码/补充信息、临时覆盖 `bib-label`、单次切换 style / form / 标注全半角 / supplement 显示格式，以及生成脚注式完整条目。位置参数可写若干 `label`（`<key>`，原生 `#cite()` 兼容写法）和/或若干 content（内部可含任意数量 `@key` 引用），混合后按顺序合并。

  ```typ
  #cite[@zhang2020]                                           // 单条
  #cite[@zhang2020@li2021] 或 #cite[@zhang2020]#cite[@li2021] // 多条合并，两种写法等价
  #cite(<zhang2020>, <li2021>)                                // 原生 label 多键写法（本包扩展）
  #cite(<zhang2020>)[@li2021]                                 // label + content 混合，等价 @zhang2020@li2021
  #cite(supplement: [260])[@zhang2020]                        // 带页码
  #cite(supplement: [1--3])[@li2021@zhang2020]                // 单值作用于首位，即@li2021（末位用 (none, [1--3])）
  #cite(supplement: [第二章])[@li2021]#cite(supplement: [1--3])[@zhang2020] // 带补充信息的多条合并
  #cite(bib-label: "appendix")[@zhang2020]                    // 临时归属到其他文献列表
  #cite(form: "inline")[@zhang2020]                           // 顺序编码制下不上标即 [1]
  #cite(form: "prose")[@zhang2020]                            // 著者-出版年制下叙事式：Author (year)
  #cite(form: "author")[@zhang2020]                           // 仅显示作者
  #cite(form: "year")[@zhang2020]                             // 仅显示出版年
  #cite(style: "author-date")[@zhang2020]                     // 单次切换为著者-出版年制
  #cite(punct-style: "full")[@zhang2020@li2021]               // 标注内部强制全角：（A，2020；B，2021）
  #cite(supplement-style: "compact", supplement: [p3])[@zhang2020] // 紧凑：[1:p3] / (A, 2020: p3)
  #cite(footnote: true)[@zhang2020]                           // 在脚注里打印完整条目（双语时含关联条目）
  ```
  **/

  let cite(
    ..args,                       /// <- (`label` | `content`)... <`required`>
      /// 位置参数；可任意混合 `label`（`<key>`，原生兼容）与 `content`（含 `@key` 引用），按出现顺序合并。\
      /// 例如 `#cite(<a>, <b>)[@c]` 等价 `#cite[@a@b@c]`。|
    bib-label:   auto,            /// <- `auto` | `string` | `none`
      /// 临时把这些引用归属到指定文献列表；`auto` 沿用当前 `set-bib-label` 作用域。|
    supplement:  none,            /// <- `none` | `content` | `array`
      /// 附加页码或补充说明，两种来源，优先级为逐键自带 > 参数：\
      /// - 逐键自带：在 content 形态里给每个 `@key` 各跟 `[supplement]`，如 ```typ #cite[@a[111]@b[222]]``` 即 a 带 111、b 带 222（与裸写 ```typ @a[111]@b[222]``` 一致）；
      /// - `supplement` 参数（给未自带 supplement 的键兜底），按位置对齐到去重后的各引用（第 _i_ 个配第 _i_ 条）：\
      ///   - 数组（`(content, content, ..)`）：逐位对齐，```typ #cite(<a>, <b>, <c>, supplement: ([s1], [s2]))``` 即 a→s1、b→s2、c 无；缺位不带 supplement，多于键数时截断；
      ///   - 单值（`content`）：等价于单元素数组，作用于首位引用，如 ```typ #cite(supplement: [p3])[@a@b]``` 即仅 a 带 p3；
      ///   - 欲令参数 supplement 落在特定位（如末位），用显式空位数组 ```typ supplement: (none, none, [p3])``` 即只第三条带 p3；
      /// - 重复 key 静默去重（连其 supplement）：```typ #cite[@a[111]@a[222]]``` → a 仅保留首次（111）；```typ #cite(<a>, <b>, supplement: ([s1], [s2], [s3]))[@b@c]``` 中 b 仅保留首次、参数按去重后顺序对齐 a→s1、b→s2、c→s3。|
    style:       auto,            /// <- `auto` | `string`
      /// 本次引用的样式，单次覆盖 #arg-ref("gb7714", "style")[`style`]。\
      /// - `"numeric"` / `"author-date"`：切换本包样式；
      /// - 其它字符串（如 `"ieee"`、`"apa"`）：本包不支持，回落到列表 / 全局样式，不报错；
      /// - `auto`（默认）：跟随列表或全局样式。\
      /// 优先级：`cite()` > `bibliography(style:)` > `gb7714(style:)`。|
    form:        auto,            /// <- `auto` | `string`
      /// 同 #arg-ref("gb7714", "cite-form")，单次覆盖。|
    name-style: auto,            /// <- `auto` | `dictionary`
      /// 同 #arg-ref("gb7714", "cite-name-style")，单次覆盖。|
    punct-style:     auto,        /// <- `auto` | `string` | `dictionary`
      /// 同 #arg-ref("gb7714", "cite-punct-style")，单次覆盖（控制正文引用标注内部标点；欲控制脚注中著录条目的标点用 `footnote-punct-style`）。|
    supplement-style:     auto,        /// <- `auto` | `string`
      /// 同 #arg-ref("gb7714", "cite-supplement-style")，单次覆盖。|
    merge:           auto,        /// <- `auto` | `boolean`
      /// 同 #arg-ref("gb7714", "cite-merge")，单次覆盖，语义为「完全孤立」：只作用于本次 ```typ #cite()```（含其多 key），不传染相邻 ```typ @key```，如 ```typ #cite(merge: false)[@a] @b@c``` → ```typ [1][2-3]```。|
    footnote:    auto,            /// <- `auto` | `boolean`
      /// 是否走脚注引用：`true` 时在脚注里著录每条引用的完整条目（含双语关联条目），不再生成正文引用标注；引用形态相关参数此时被忽略。\
      /// - `auto`（默认）：继承全局 #arg-ref("gb7714", "cite-footnote")；
      /// - 显式 `true` / `false`：单次覆盖。|
    footnote-related-indent: auto,  /// <- `auto` | `none` | `length` | `content`
      /// 脚注模式下双语关联条目第二行前的缩进。\
      /// - `auto`（默认）：与首行首字对齐——实测注号前缀宽（`entry.indent` + 注号上标宽 + 原生号后间隙），任意编号样式（quan / 用户 set）都跟对，假定编号样式全文一致（同「同③」）；
      /// - `none`：无缩进；任意 length / content：显式指定。\
      /// 表内（非脚注）双语第二行的缩进由 ```typ #bibliography(related-indent: ..)``` 逐表控制，两者独立。|
    custom-drivers: auto,       /// <- `auto` | `dictionary`
      /// 同 #arg-ref("gb7714", "custom-drivers")，仅 `footnote: true` 时生效。|
    custom-terms:           auto,        /// <- `auto` | `dictionary`
      /// 同 #arg-ref("gb7714", "custom-terms")，仅 `footnote: true` 时生效。|
    custom-fields:          auto,        /// <- `auto` | `dictionary`
      /// 同 #arg-ref("gb7714", "custom-fields")，仅 `footnote: true` 时生效。|
    custom-pids:            auto,        /// <- `auto` | `dictionary`
      /// 同 #arg-ref("gb7714", "custom-pids")，仅 `footnote: true` 时生效。|
    show-pid:        auto,        /// <- `auto` | `dictionary`
      /// 同 #arg-ref("gb7714", "show-pid")，仅 `footnote: true` 时生效。|
    pid-priority:       auto,        /// <- `auto` | `array`
      /// 同 #arg-ref("gb7714", "pid-priority")，仅 `footnote: true` 时生效。|
    dedup-url-pid:   auto,        /// <- `auto` | `boolean`
      /// 同 #arg-ref("gb7714", "dedup-url-pid")，仅 `footnote: true` 时生效。|
    show-annotation: auto,        /// <- `auto` | `boolean`
      /// 同 #arg-ref("gb7714", "show-annotation")，仅 `footnote: true` 时生效。|
    et-al-min:       auto,        /// <- `auto` | `integer` | `dictionary`
      /// 同 #arg-ref("gb7714", "cite-et-al-min")，单次覆盖。如全局紧凑、某处临时全列著者可写 `et-al-min: 999`。|
    et-al-use-first: auto,        /// <- `auto` | `integer` | `dictionary`
      /// 同 #arg-ref("gb7714", "cite-et-al-use-first")（含三档取值），单次覆盖。|
    et-al-use-last:  auto,        /// <- `auto` | `integer` | `dictionary`
      /// 同 #arg-ref("gb7714", "cite-et-al-use-last")（含三档取值），单次覆盖。|
    terms-lang:      auto,        /// <- `auto(继承)` | "by-doc" | "by-entry" | "zh" | "ja" | "ko" | "ru" | "en" | "fr"
      /// 同 #arg-ref("gb7714", "cite-terms-lang")，单次覆盖本次引用的截断词语言。|
    compress-min:    auto,        /// <- `auto` | `integer`
      /// 同 #arg-ref("gb7714", "cite-compress-min")，单次覆盖。|
    range-separator: auto,        /// <- `auto` | `string` | `dictionary`
      /// 同 #arg-ref("gb7714", "cite-range-separator")，单次覆盖本次引用的区间连接符。|
    sort-by:         auto,        /// <- `auto` | `none` | `array`
      /// 同 #arg-ref("gb7714", "cite-sort-by")，单次覆盖本组组内排序（单次裸名即 cite 轴）。\
      /// 如 ```typ #cite(<a>, <b>, sort-by: none)``` 保写法序。|
    sort-zh-by:      auto,        /// <- `auto` | "pinyin" | "bihua"
      /// 同 #arg-ref("gb7714", "cite-sort-zh-by")，单次覆盖组内排序的中文排序方案。|
    collapse-date:   auto,        /// <- `auto` | `boolean`
      /// 同 #arg-ref("gb7714", "cite-collapse-date")，单次覆盖本组的年份折叠。|
    footnote-punct-style:     auto,  /// <- `auto` | `string`
      /// 同 #arg-ref("gb7714", "bib-punct-style")，仅 `footnote: true` 时生效。\
      /// 与本函数 `punct-style` 区分：后者控制正文引用标注内部标点，本项控制脚注里著录的条目标点。|
    footnote-custom-punct: auto,  /// <- `auto` | `dictionary`
      /// 同 #arg-ref("gb7714", "custom-punct")，仅 `footnote: true` 时生效。|
    footnote-url-break-every: auto,  /// <- `auto` | `none` | `int`
      /// 同 #arg-ref("gb7714", "url-break-every")，仅 `footnote: true` 时生效。|
  ) = {

    let positional = args.pos()
    if positional.len() == 0 {
      errors.raise("cite.no-keys")
    }
    let ref-elems = ()
    for p in positional {
      if type(p) == label {
        ref-elems.push(std.ref(p))
      } else if type(p) == content {
        ref-elems = ref-elems + _extract-refs(p)
      } else {
        errors.raise("cite.bad-positional")
      }
    }
    if ref-elems.len() == 0 { return }

    let unique-refs = ()
    let _seen-keys = ()
    for r in ref-elems {
      let k = str(r.target)
      if k in _seen-keys { continue }
      _seen-keys.push(k)
      unique-refs.push(r)
    }

    let supplement-array = if type(supplement) == array { supplement } else if supplement == none { () } else { (supplement,) }
    let supplements = ()
    for i in range(unique-refs.len()) {
      let own = unique-refs.at(i).at("supplement", default: none)
      if own != none and own != auto {
        supplements.push(own)
      } else if i < supplement-array.len() {
        supplements.push(supplement-array.at(i))
      } else {
        supplements.push(none)
      }
    }

    let eff-footnote = _api-pick(footnote, cite-footnote)

    let eff-merge = _api-pick(merge, cite-merge)

    if eff-footnote {
      if custom-terms != auto { validate-terms(custom-terms) }
      if custom-fields != auto { validate-fields(custom-fields) }
      if custom-pids != auto { validate-pids(custom-pids) }
      if footnote-custom-punct != auto { punct-custom.validate-punct(footnote-custom-punct) }

      let footnote-items = ()
      let unknown-refs = ()
      for (ref-index, r) in unique-refs.enumerate() {
        if str(r.target) not in bib-data { unknown-refs.push(r) }
        else { footnote-items.push((key: str(r.target), supplement: supplements.at(ref-index, default: none))) }
      }
      let cite-overrides = (
        custom-drivers: custom-drivers, custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids,
        footnote-punct-style: footnote-punct-style, footnote-custom-punct: footnote-custom-punct,
        footnote-url-break-every: footnote-url-break-every,
        show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid,
        show-annotation: show-annotation, style: style, footnote-related-indent: footnote-related-indent,
      )

      let native-registration = _is-native-mode(state("gb7714-bib-list", ()).final())
      let nomerge-flag = if eff-merge == false { _MNM } else { "" }
      let emitted = for item in footnote-items {
        [#metadata((kind: "gb7714-fnsidecar", supplement: item.supplement, overrides: cite-overrides))]
        if native-registration { std.cite(std.label(item.key), form: none) }
        _M + nomerge-flag + _MF + item.key + _M
      }

      return [#unknown-refs.join()#sym.wj#emitted]
    }

    let cites-inner = for (i, r) in unique-refs.enumerate() {
      let supplement = supplements.at(i)

      if str(r.target) not in bib-data { r }
      else { std.cite(r.target, supplement: supplement) }
    }

    let cites-wrapped = if form == auto { cites-inner } else { [#_MB#cites-inner#_MB] }

    let _word-joiner-form = if form == auto { cite-form } else { form }

    let _emit-word-joiner = eff-footnote or (if _word-joiner-form == auto { global-style-cite != "author-date" } else { _word-joiner-form == "super" })
    let _cwj = if _emit-word-joiner { sym.wj } else { [] }
    let cites-nm = [#_cwj#_cite-nomerge.update(eff-merge == false)#cites-wrapped#_cite-nomerge.update(false)]

    let cites-nm = if footnote == auto { cites-nm } else { [#_cite-footnote-override.update(footnote)#cites-nm#_cite-footnote-override.update(auto)] }

    let cites = cites-nm

    let with-list = if bib-label == auto {
      cites
    } else {
      context {
        let previous = _active-list.get()
        [#_active-list.update(bib-label)#cites#_active-list.update(previous)]
      }
    }
    let with-form = if form == auto {
      with-list
    } else {
      [#_cite-form-state.update(form)#with-list#_cite-form-state.update(auto)]
    }
    let with-style = if style == auto { with-form }
      else {

        let eff = if type(style) == str and style in ("numeric", "author-date") { style } else { auto }
        if eff == auto { with-form }
        else { [#_cite-style-state.update(eff)#with-form#_cite-style-state.update(auto)] }
      }
    let with-punct = if punct-style == auto { with-style }
      else { [#_cite-punct-style-state.update(punct-style)#with-style#_cite-punct-style-state.update(auto)] }
    let with-supplement = if supplement-style == auto { with-punct }
      else { [#_cite-supplement-style-state.update(supplement-style)#with-punct#_cite-supplement-style-state.update(auto)] }
    let with-name-format = if name-style == auto { with-supplement }
      else { [#_cite-name-style-state.update(name-style)#with-supplement#_cite-name-style-state.update(auto)] }
    let with-et-min = if et-al-min == auto { with-name-format }
      else { [#_cite-et-al-min-state.update(et-al-min)#with-name-format#_cite-et-al-min-state.update(auto)] }
    let with-et-first = if et-al-use-first == auto { with-et-min }
      else { [#_cite-et-al-use-first-state.update(et-al-use-first)#with-et-min#_cite-et-al-use-first-state.update(auto)] }
    let with-et-last = if et-al-use-last == auto { with-et-first }
      else { [#_cite-et-al-use-last-state.update(et-al-use-last)#with-et-first#_cite-et-al-use-last-state.update(auto)] }
    let with-terms-lang = if terms-lang == auto { with-et-last }
      else { [#_cite-terms-lang-state.update(terms-lang)#with-et-last#_cite-terms-lang-state.update(auto)] }
    let with-compress = if compress-min == auto { with-terms-lang }
      else { [#_cite-compress-min-state.update(compress-min)#with-terms-lang#_cite-compress-min-state.update(auto)] }
    let with-range = if range-separator == auto { with-compress }
      else { [#_cite-range-separator-state.update(range-separator)#with-compress#_cite-range-separator-state.update(auto)] }
    let with-sort-by = if sort-by == auto { with-range }
      else { [#_cite-sort-by-state.update(sort-by)#with-range#_cite-sort-by-state.update(auto)] }
    let with-sort-zh-by = if sort-zh-by == auto { with-sort-by }
      else { [#_cite-sort-zh-by-state.update(sort-zh-by)#with-sort-by#_cite-sort-zh-by-state.update(auto)] }
    if collapse-date == auto { with-sort-zh-by }
    else { [#_cite-collapse-date-state.update(collapse-date)#with-sort-zh-by#_cite-collapse-date-state.update(auto)] }
  }

  /**
  = `bibliography` — 生成参考文献表 <print-bib>

  与 Typst 原生 `bibliography` 同形：首位置参数收 bib 内容（`read("refs.bib")` 的结果，
  仅多这一层 `read()` 是 Typst 包沙箱的限制），`title` / `full` / `style` / `target` / `group`
  与原生同名同义（后两者需 typst 0.15+）。在此之上扩展：`label` 命名列表、按类型 / 关键词 /
  自定义函数过滤、多种排序与布局覆盖。多次调用即多个独立列表，编号自动全局连续。

  注意：`filter` / `keys` / `entry-type` / `mark` / `keyword` 是*显示过滤*，不改变编号空间——
  被滤掉条目的正文引用编号仍占位（适合「分表展示各子集」，各子集合起来应覆盖全部已引用条目，
  否则会出现列表中找不到的孤儿编号）。

  ```typ
  // 主参考文献表（标题按文档语言自动取「参考文献 / References」等）
  #bibliography(read("refs.bib"))

  // 只打印图书，且换自定义标题
  #bibliography(read("refs.bib"), type: "M", title: [参考图书])

  // 被引用的标准（网络版除外），追加未引用条目
  #bibliography(
    read("appx.bib"),
    mark: "S", // 文献类型标识码为 S
    full: true, // 含未引用条目
    filter: e => e.fields.at("url", default: none) == none, // 不含 URL
    title: [#heading(level: 2)[引用标准]],
  )

  // 命名列表（配合 set-bib-label / cite(bib-label:) 归属引用）
  #bibliography(read("refs.bib"), label: "sec2", title: [第二节参考文献])

  // 原生国标 CSL 全名自动映射回本包实现并锁定版本；其它原生 CSL 名（"ieee" / "apa" 等）
  // 则把本列表整个交 typst 原生渲染（typst 0.15+）
  #bibliography(read("refs.bib"), style: "gb-7714-2015-author-date")
  ```
  **/
  let print-bib(

    bib-file:      none,   /// <- `none` | `string`
      /// 纯内部：命名列表（`label:`）自动传入的源标签，用户不可见、不可用。|
    entry-type:    none,   /// <- `none` | `string` | `array`
      /// 按条目类型（biblatex 的 `@book` 那个类型）过滤，如 `"book"`、`("book", "incollection")`。\
      /// 按*文献类型标识码*筛用 #arg-ref("print-bib", "mark")[`mark`]。|
    filter:        none,   /// <- `none` | `function`
      /// 自定义过滤函数 `entry => bool`，可访问条目所有字段。|
    full:          false,  /// <- `boolean`
      /// - `true`：除已引用条目外，追加显示其他所有符合筛选条件的条目。|
    keys:          none,   /// <- `none` | `content`
      /// 指定要著录的条目键（列表），此时忽略其他过滤条件。传入内容块，内部用 ```typ @key``` 引用，如 ```typ keys: [@zhang2020@li2021]```，函数递归提取块内全部引用并著录。|
    keyword:       none,   /// <- `none` | `string`
      /// 对条目 `keywords` 字段做大小写敏感的子串匹配，仅著录含该关键词的条目；需更精准的正则匹配请用 `filter` 自行构建。|
    mark:          none,   /// <- `none` | `string` | `array`
      /// 按*文献类型标识码*过滤，如 `"M"`、`"J"`、`("C", "G")`。匹配条目标识等于该值，载体不影响匹配，如 `"EB"` 可匹配 EB/OL。\
      /// 曾叫 `type:`——那个名字与 bib 的 `type` 字段（报告种类、学位类型）撞名，还遮蔽了 Typst 内置的 `type()` 函数。\
      /// 按*条目类型*筛用 #arg-ref("print-bib", "entry-type")[`entry-type`]。|

    label:         none,   /// <- `none` | `string`
      /// 著录指定标签的参考文献列表。\
      /// - `none`：主列表；
      /// - `"xxx"`：```typ #set-bib-label("xxx")``` 归属的引用；每条条目自动生成 `<gb7714-xxx-key>` 标签供 `#cite` 跳转。|
    title:         none,   /// <- `none` | `content`
      /// 列表标题；`none` 不输出标题。|

    sort-keys:     none,   /// <- `none` | `content`
      /// 自定义排序：传入内容块，内部用 ```typ @key``` 引用指定的条目，按书写顺序优先排列，其余追加，例：```typ sort-keys: [@key1@key2]```。|
    sort-by:       auto,   /// <- `auto` | `none` | `array`
      /// #arg-ref("gb7714", "bib-sort-by")。`auto` 时继承全局（逐表裸名即 bib 轴）。|
    sort-zh-by:    auto,   /// <- `auto` | "pinyin" | "bihua"
      /// #arg-ref("gb7714", "bib-sort-zh-by")。`auto` 时继承全局（逐表裸名即 bib 轴）。|
    creator-idem:  auto,   /// <- `auto` | `none` | `string`
      /// #arg-ref("gb7714", "creator-idem")。`auto` 时继承全局。|

    bold-journal-volume: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "bold-journal-volume")。|
    page-range-separator: auto,   /// <- `auto` | `string` | `dictionary`
      /// #arg-ref("gb7714", "page-range-separator")。|
    page-range-style: auto,       /// <- `auto` | `none` | `string`
      /// #arg-ref("gb7714", "page-range-style")。|
    end-with-period: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "end-with-period")。|
    et-al-min:     auto,   /// <- `auto` | `integer` | `dictionary`
      /// #arg-ref("gb7714", "bib-et-al-min")。|
    et-al-use-first: auto, /// <- `auto` | `integer` | `dictionary`
      /// #arg-ref("gb7714", "bib-et-al-use-first")（含三档取值）。|
    et-al-use-last: auto,  /// <- `auto` | `integer` | `dictionary`
      /// #arg-ref("gb7714", "bib-et-al-use-last")（含三档取值）。|
    entry-hanging-indent:     auto,   /// <- `auto` | `length`
      /// #arg-ref("gb7714", "entry-hanging-indent")。|
    entry-first-line-indent:  auto,   /// <- `auto` | `length`
      /// #arg-ref("gb7714", "entry-first-line-indent")。|
    hyperlink:     auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "hyperlink")。|
    hyphenate:     auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "hyphenate")。|
    italic-book-title: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "italic-book-title")。|
    italic-journal: auto,  /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "italic-journal")。|
    entry-spacing:      auto,   /// <- `auto` | `length`
      /// #arg-ref("gb7714", "entry-spacing")。|
    number-gutter:     auto,   /// <- `auto` | `length`
      /// #arg-ref("gb7714", "number-gutter")。|
    numbering-style: auto, /// <- `auto` | `string`
      /// #arg-ref("gb7714", "numbering-style")。|
    entry-lang-order:    auto,   /// <- `auto` | `array`
      /// #arg-ref("gb7714", "entry-lang-order")。|
    sort-use-prefix:    auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "sort-use-prefix")。|
    name-style:   auto,   /// <- `auto` | `string`
      /// #arg-ref("gb7714", "bib-name-style")。|
    show-anon:     auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-anon")。|
    show-no-date:  auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-no-date")。|
    show-et-al:     auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-et-al")。|
    dedup-author-editor: auto,  /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "dedup-author-editor")。|
    number-placement: auto,  /// <- `auto` | `string`
      /// #arg-ref("gb7714", "number-placement")。|
    number-align:  auto,   /// <- `auto` | `string`
      /// #arg-ref("gb7714", "number-align")。|
    number-width:  auto,   /// <- `auto` | `length`
      /// #arg-ref("gb7714", "number-width")。|
    period-after-creator: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "period-after-creator")。|
    related-indent: none,  /// <- `none` | `length` | `content`
      /// 双语关联条目（related + `lanversion`）第二行前的缩进。`none` 无缩进。|
    short-journal: auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "short-journal")。|
    show-mark:     auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-mark")。|
    show-medium:   auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-medium")。|
    show-sine-loco: auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-sine-loco")。|
    show-sine-nomine: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-sine-nomine")。|
    show-sine-anno: auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-sine-anno")。|
    show-patent-country: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-patent-country")。|
    volume-title-gutter: auto, /// <- `auto` | `length`
      /// #arg-ref("gb7714", "volume-title-gutter")。|
    show-related:  auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-related")。|
    show-url:      auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-url")。|
    show-urldate:  auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-urldate")。|
    space-before-mark: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "space-before-mark")。|
    space-before-pages: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "space-before-pages")。|
    disambiguate:  auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "disambiguate")。`auto` 继承全局。|
    style:         none,   /// <- `none` | `dictionary`
      /// #arg-ref("gb7714", "style")。本列表的两轴（`(cite: .., bib: ..)`，各键 `none` 表示继承全局）。|
    hyperlink-title:    auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "hyperlink-title")。|
    back-ref:      auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "back-ref")。|
    show-degree:   auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-degree")，仅临时覆盖本次 `bibliography` 调用，不影响主参考文献表与其它命名列表。|
    show-series:   auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-series")，仅临时覆盖本次 `bibliography` 调用。|
    prefix-last:   auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "prefix-last")，仅临时覆盖本次 `bibliography` 调用。|
    custom-drivers: auto, /// <- `auto` | `dictionary`
      /// #arg-ref("gb7714", "custom-drivers")，仅临时覆盖本次 `bibliography` 调用，不影响主参考文献表与其它命名列表。|
    custom-terms:         auto,   /// <- `auto` | `dictionary`
      /// #arg-ref("gb7714", "custom-terms")，仅临时覆盖本次 `bibliography` 调用，不影响主参考文献表与其它命名列表。|
    custom-fields:        auto,   /// <- `auto` | `dictionary`
      /// #arg-ref("gb7714", "custom-fields")，仅临时覆盖本次 `bibliography` 调用，不影响主参考文献表与其它命名列表。|
    custom-pids:          auto,   /// <- `auto` | `dictionary`
      /// #arg-ref("gb7714", "custom-pids")，仅临时覆盖本次 `bibliography` 调用，不影响主参考文献表与其它命名列表。|
    punct-style:   auto,   /// <- `auto` | `string`
      /// #arg-ref("gb7714", "bib-punct-style")，仅临时覆盖本次调用。|
    custom-punct: auto, /// <- `auto` | `dictionary`
      /// #arg-ref("gb7714", "custom-punct")，仅临时覆盖本次调用。|
    url-break-every: auto, /// <- `auto` | `none` | `int`
      /// #arg-ref("gb7714", "url-break-every")，仅临时覆盖本次调用。|
    url-break-hyphen: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "url-break-hyphen")，仅临时覆盖本次调用。|
    url-break-hyphen-at-delimiters: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "url-break-hyphen-at-delimiters")，仅临时覆盖本次调用。|
    show-pid:      auto,   /// <- `auto` | `dictionary`
      /// #arg-ref("gb7714", "show-pid")，仅临时覆盖本次调用。|
    pid-priority:     auto,   /// <- `auto` | `array`
      /// #arg-ref("gb7714", "pid-priority")，仅临时覆盖本次调用。|
    dedup-url-pid: auto,   /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "dedup-url-pid")，仅临时覆盖本次调用。|
    show-annotation: auto, /// <- `auto` | `boolean`
      /// #arg-ref("gb7714", "show-annotation")，仅临时覆盖本次调用。|
    number-offset:    0,      /// <- `int`
      /// 编号起始偏移。本列表第一条编号 = `number-offset + 1`。\
      /// 供多 bib 场景使多个独立列表之间编号全局连续。|
    footnote:      auto,   /// <- `auto` | `boolean`
      /// 本列表的脚注制开关：归属本列表的引用走脚注（完整著录于脚注处）。\
      /// - `auto`（默认）：跟随全局 #arg-ref("gb7714", "cite-footnote")[`cite-footnote`]；
      /// - `true` / `false`：列表级覆盖（解析链：`cite(footnote:)` 显式 > 本参数 > 全局）。|
    version:       auto,   /// <- `auto` | `integer`
      /// 本列表的国标版本，单次覆盖 #arg-ref("gb7714", "version")[`version`]：2025 / 2015 / 2005；`auto` 跟随全局。\
      /// `style` 给原生国标 CSL 全名（如 `"gb-7714-2015-numeric"`）时按名锁定对应版本，优先于本参数。|
    target:        auto,   /// <- `auto` | `selector`
      /// typst 0.15 原生 cite 路由选择器（如 `selector(std.cite).within(<ch1>)`），把匹配的正文引用归属本列表。需 typst 0.15+。|
    group:         auto,   /// <- `auto` | `string` | `none`
      /// typst 0.15 原生编号分组：标同一 `group` 的多个列表共享一段连续编号；`auto` 全文档连续、`none` 各自从 [1] 起。需 typst 0.15+。|
  ) = context {

    let list-style-cite = if style != none { style.at("cite", default: none) } else { none }
    let list-style-bib = if style != none { style.at("bib", default: none) } else { none }
    let eff-cite-style = if list-style-cite != none { list-style-cite } else { global-style-cite }
    let eff-bib-style = if list-style-bib != none { list-style-bib }
      else if list-style-cite != none { list-style-cite }
      else { global-style-bib }

    let eff-disambiguate = if disambiguate != auto { author-date-cite.normalize-disambiguate(disambiguate) } else { _global-config.disambiguate }
    let eff-numeric-date-suffix = eff-disambiguate.date == true
    let eff-escalate-given-name = eff-disambiguate.given-name == true or (eff-disambiguate.given-name == auto and eff-cite-style == "author-date")
    let eff-expand-names = eff-disambiguate.names == true or (eff-disambiguate.names == auto and eff-cite-style == "author-date")

    let list-label = label

    if keys != none {
      for r in _extract-refs(keys) {
        if str(r.target) not in bib-data { r }
      }
    }
    if sort-keys != none {
      for r in _extract-refs(sort-keys) {
        if str(r.target) not in bib-data { r }
      }
    }

    let sort-keys = if sort-keys == none { none }
      else { _extract-refs(sort-keys).map(r => str(r.target)) }

    if list-label != none {
      _list-style-map.update(m => { m.insert(list-label, eff-cite-style); m })
      if footnote != auto { _list-footnote-map.update(m => { m.insert(list-label, footnote); m }) }
    } else if footnote != auto { _main-footnote.update(footnote) }

    let cited-keys = omni-aux.cited-keys(bib-data, list-label)
    let source-keys = if keys != none {

      let raw = _extract-refs(keys).map(r => str(r.target)).filter(k => k in bib-data)
      let dedup = ()
      for k in raw { if k not in dedup { dedup.push(k) } }
      dedup
    }
    else if full {
      let all-keys = cited-keys
      for key in bib-key-order { if key not in all-keys { all-keys.push(key) } }
      all-keys
    } else { cited-keys }

    let source-keys = if bib-file != none {
      let file-keys = bib-file-keys.at(bib-file, default: ())
      source-keys.filter(k => k in file-keys)
    } else { source-keys }

    let filtered = bib.select-entries(source-keys, (
      bib-data: bib-data,
      mark: mark, entry-type: entry-type, keyword: keyword, filter: filter,
      eff-show-related: _api-pick(show-related, _global-config.show-related),
      get-related-key: _get-related-key,
    ))

    let _sort-by-config = if sort-by != auto { sort-by }
      else if _global-config.bib-sort-by != auto { _global-config.bib-sort-by }
      else if eff-cite-style == "author-date" { ("name", "date", "title") } else { none }
    let eff-sort-by = sort.normalize-sort-by(_sort-by-config, param: if sort-by != auto { "sort-by" } else { "bib-sort-by" })

    let eff-sort-zh-by = if sort-zh-by != auto { errors.check-enum("sort-zh-by", sort-zh-by); sort-zh-by } else { _global-config.bib-sort-zh-by }

    let eff-creator-idem = if creator-idem != auto { creator-idem } else { _global-config.creator-idem }

    let eff-version = if version == auto { _global-config.version } else { _coerce-version(version) }

    let _va = _global-config.at("_version-auto", default: (:))
    let _va-derive(key, list-param, v2025, v2015) = {
      if list-param != auto { list-param }
      else if _va.at(key, default: false) and eff-version != _global-config.version { if eff-version == 2025 { v2025 } else { v2015 } }
      else { _global-config.at(key) }
    }

    if eff-version != _global-config.version {
      filtered = filtered.map(pair => {
        let e = pair.at(1)
        let base = e.fields.at("_omni-mark-base", default: none)
        if base == none { return pair }
        let rawtype = e.fields.at("_omni-rawtype", default: e.entry_type)
        let new-fields = e.fields; new-fields.insert("_omni-mark-override", _version-mark(base, rawtype, eff-version, is-preprint: _is-preprint-routed(e)))
        let new-entry = e; new-entry.fields = new-fields
        (pair.at(0), new-entry)
      })
    }

    let eff-bold-journal-volume = _api-pick(bold-journal-volume, _global-config.bold-journal-volume)
    let eff-page-range-separator       = _api-pick(page-range-separator, _global-config.page-range-separator)

    let eff-page-range-style           = pages.normalize-page-range-style(_api-pick(page-range-style, _global-config.page-range-style))
    let eff-end-with-period     = _api-pick(end-with-period, _global-config.end-with-period)
    let eff-et-al-min           = _api-pick(et-al-min, _global-config.et-al-min)
    let eff-et-al-use-first     = _api-pick(et-al-use-first, _global-config.et-al-use-first)
    let eff-et-al-use-last      = _api-pick(et-al-use-last, _global-config.et-al-use-last)
    let eff-hyperlink           = _api-pick(hyperlink, _global-config.hyperlink)
    let eff-italic-book-title   = _api-pick(italic-book-title, _global-config.italic-book-title)
    let eff-italic-journal      = _api-pick(italic-journal, _global-config.italic-journal)
    let eff-entry-lang-order          = _api-pick(entry-lang-order, _global-config.entry-lang-order)
    let eff-sort-use-prefix          = _api-pick(sort-use-prefix, _global-config.sort-use-prefix)

    let eff-name-style = creators.resolve-name-style(
      if name-style != auto { name-style } else { _global-config.at("_name-style-raw", default: auto) },
      version: eff-version, side: "bib")

    let eff-name-suffix-separator = _va-derive("name-suffix-separator", auto, " ", ", ")

    let eff-et-al-translator-separator = _global-config.at("et-al-translator-separator", default: auto)
    let eff-show-anon           = _api-pick(show-anon, _global-config.show-anon)
    let eff-show-no-date        = _api-pick(show-no-date, _global-config.show-no-date)
    let eff-show-et-al           = _api-pick(show-et-al, _global-config.show-et-al)
    let eff-dedup-author-editor      = _api-pick(dedup-author-editor, _global-config.dedup-author-editor)
    let eff-period-after-creator = _api-pick(period-after-creator, _global-config.period-after-creator)

    let eff-short-journal       = _api-pick(short-journal, _global-config.short-journal)
    let eff-show-mark           = _api-pick(show-mark, _global-config.show-mark)
    let eff-show-medium         = _api-pick(show-medium, _global-config.show-medium)
    let eff-show-sine-loco      = _api-pick(show-sine-loco, _global-config.show-sine-loco)
    let eff-show-sine-anno      = _api-pick(show-sine-anno, _global-config.show-sine-anno)
    let eff-show-sine-nomine    = _api-pick(show-sine-nomine, _global-config.show-sine-nomine)
    let eff-show-patent-country = _api-pick(show-patent-country, _global-config.show-patent-country)
    let eff-volume-title-gutter = _api-pick(volume-title-gutter, _global-config.volume-title-gutter)
    let eff-show-related        = _api-pick(show-related, _global-config.show-related)
    let eff-show-url            = _api-pick(show-url, _global-config.show-url)
    let eff-show-urldate        = _api-pick(show-urldate, _global-config.show-urldate)
    let eff-space-before-mark   = _api-pick(space-before-mark, _global-config.space-before-mark)
    let eff-space-before-pages  = _api-pick(space-before-pages, _global-config.space-before-pages)
    let eff-hyperlink-title          = _api-pick(hyperlink-title, _global-config.hyperlink-title)
    let eff-back-ref                 = _api-pick(back-ref, _global-config.back-ref)
    let eff-show-degree              = _api-pick(show-degree, _global-config.show-degree)
    let eff-show-series              = _api-pick(show-series, _global-config.show-series)
    let eff-prefix-last             = _va-derive("prefix-last", prefix-last, true, false)
    let eff-custom-drivers         = _api-pick(custom-drivers, _global-config.custom-drivers)
    let eff-custom-terms                    = _api-pick(custom-terms, _global-config.custom-terms)
    let eff-custom-fields                   = _api-pick(custom-fields, _global-config.custom-fields)
    let eff-custom-pids                     = _api-pick(custom-pids, _global-config.custom-pids)

    let eff-punct-style              = punct.resolve-bib-document(_va-derive("punct-style", punct-style, "full", "half-with-space"), text.lang)
    let eff-custom-punct          = _api-pick(custom-punct, _global-config.custom-punct)

    let eff-correct-punct            = _global-config.correct-punct
    let eff-url-break-every          = _api-pick(url-break-every, _global-config.url-break-every)
    let eff-url-break-hyphen         = _api-pick(url-break-hyphen, _global-config.url-break-hyphen)
    let eff-url-break-hyphen-at-delimiters = _api-pick(url-break-hyphen-at-delimiters, _global-config.url-break-hyphen-at-delimiters)
    let eff-show-pid                 = _api-pick(show-pid, _global-config.show-pid)

    let _extra-marks = _global-config.at("_registered-marks", default: ())
    mark-medium.validate-setting-keys(eff-show-mark, "show-mark", extra-marks: _extra-marks)
    mark-medium.validate-setting-keys(eff-show-url, "show-url", extra-marks: _extra-marks)
    mark-medium.validate-setting-keys(eff-show-pid, "show-pid", extra-marks: _extra-marks)
    let eff-pid-priority                = _api-pick(pid-priority, _global-config.pid-priority)
    let eff-dedup-url-pid            = _va-derive("dedup-url-pid", dedup-url-pid, true, false)
    let eff-show-annotation          = _api-pick(show-annotation, _global-config.show-annotation)
    if custom-terms != auto { validate-terms(custom-terms) }
    if custom-fields != auto { validate-fields(custom-fields) }
    if custom-pids != auto { validate-pids(custom-pids) }
    if custom-punct != auto { punct-custom.validate-punct(custom-punct) }

    filtered = sort.apply(filtered, (
      sort-by: eff-sort-by,
      eff-entry-lang-order: eff-entry-lang-order,
      sort-zh-by: eff-sort-zh-by,
      eff-sort-use-prefix: eff-sort-use-prefix,
      sort-keys: sort-keys,
      show-anon: eff-show-anon,
      custom-terms: eff-custom-terms,
    ))

    let _disambiguation = author-date-cite.disambiguation(bib-data, cite-et-al-min: cite-et-al-min, cite-et-al-use-first: cite-et-al-use-first, name-style: cite-name-style-eff, sort-keys: sort-keys, scope-keys: filtered.map(p => p.at(0)), escalate-given-name: eff-escalate-given-name, expand-names: eff-expand-names)

    let eff-suffixes = if eff-disambiguate.date == false { (:) } else { _disambiguation.cite-suffixes }
    let eff-escalations = _disambiguation.escalations

    _list-suffix-map.update(m => { m.insert(if list-label != none { list-label } else { "" }, (suffixes: eff-suffixes, escalations: eff-escalations)); m })

    if filtered.len() == 0 { return }

    let _title-heading = if title != none { heading(level: 1, numbering: none, title) } else { none }

    let eff-number-placement       = _api-pick(number-placement, _global-config.number-placement)
    let eff-entry-first-line-indent = _api-pick(entry-first-line-indent, _global-config.entry-first-line-indent)

    let eff-number-gutter       = _api-pick(number-gutter, _global-config.number-gutter)
    let eff-entry-spacing       = _api-pick(entry-spacing, _global-config.entry-spacing)
    let eff-number-align  = _api-pick(number-align, _global-config.number-align)

    let _numbering-config = _api-pick(numbering-style, _global-config.numbering-style)
    let eff-numbering-style = if _numbering-config == auto {
      if eff-cite-style == "numeric" { "bracket" } else { none }
    } else { _numbering-config }

    let eff-circled-engine = if std.type(eff-numbering-style) == dictionary { eff-numbering-style.at("circled", default: "unicode") } else { "unicode" }
    let eff-numbering-style = if std.type(eff-numbering-style) == dictionary { "circled" } else { eff-numbering-style }

    let _numbered      = eff-numbering-style != none
    let _column-mode   = _numbered and eff-number-placement == "column"
    let _margin-mode   = _numbered and eff-number-placement == "margin"
    let eff-hyphenate  = _api-pick(hyphenate, _global-config.hyphenate)

    let _eff-format-opts = (show-sine-loco: eff-show-sine-loco, show-sine-nomine: eff-show-sine-nomine, show-sine-anno: eff-show-sine-anno, et-al-min: eff-et-al-min, et-al-use-first: eff-et-al-use-first, et-al-use-last: eff-et-al-use-last, show-url: eff-show-url, show-mark: eff-show-mark, show-medium: eff-show-medium, show-patent-country: eff-show-patent-country, short-journal: eff-short-journal, show-urldate: eff-show-urldate, end-with-period: eff-end-with-period, hyperlink: eff-hyperlink, italic-journal: eff-italic-journal, bold-journal-volume: eff-bold-journal-volume, italic-book-title: eff-italic-book-title, space-before-mark: eff-space-before-mark, space-before-pages: eff-space-before-pages, page-range-separator: eff-page-range-separator, page-range-style: eff-page-range-style, period-after-creator: eff-period-after-creator, show-et-al: eff-show-et-al, name-style: eff-name-style, hyperlink-title: eff-hyperlink-title, dedup-author-editor: eff-dedup-author-editor, show-degree: eff-show-degree, show-series: eff-show-series, prefix-last: eff-prefix-last, name-suffix-separator: eff-name-suffix-separator, et-al-translator-separator: eff-et-al-translator-separator, registered-marks: _global-config.at("_registered-marks", default: ()), custom-drivers: eff-custom-drivers, custom-terms: eff-custom-terms, custom-fields: eff-custom-fields, custom-pids: eff-custom-pids, correct-punct: eff-correct-punct, punct-style: eff-punct-style, custom-punct: eff-custom-punct, url-break-every: eff-url-break-every, url-break-hyphen: eff-url-break-hyphen, url-break-hyphen-at-delimiters: eff-url-break-hyphen-at-delimiters, version: eff-version, show-pid: eff-show-pid, pid-priority: eff-pid-priority, dedup-url-pid: eff-dedup-url-pid, show-annotation: eff-show-annotation, volume-title-gutter: eff-volume-title-gutter)
    let _emit-entry(entry, show-anon: eff-show-anon, skip-date: false, date-suffix: "", creator-override: none) = {
      dispatch.entry(entry, .._eff-format-opts, show-anon: show-anon, skip-date: skip-date, date-suffix: date-suffix, creator-override: creator-override)
    }
    let _emit-entry-author-date(entry, suffix-key: none, show-anon: eff-show-anon, suffixes: none, creator-override: none) = {

      let _author-date-roles = creators.default-roles(entry, component-part: category.get(entry, version: eff-version) == "component-part")

      let _escalation = if suffix-key != none { eff-escalations.at(suffix-key, default: (use-first: none, given-form: none)) } else { (use-first: none, given-form: none) }
      let _first-name-style = if _escalation.given-form == "full" { let d = eff-name-style; d.insert("given-form", "full"); d } else { none }
      let author = creators.principal(entry, et-al-min: eff-et-al-min, et-al-use-first: eff-et-al-use-first, show-anon: show-anon, show-et-al: eff-show-et-al, name-style: eff-name-style, first-name-style: _first-name-style, punct-style: eff-punct-style, custom-punct: eff-custom-punct, custom-terms: _global-config.custom-terms, name-suffix-separator: eff-name-suffix-separator, roles: _author-date-roles, prefix-last: eff-prefix-last)
      let suffix-table = if suffixes != none { suffixes } else if eff-disambiguate.date == false { (:) } else { _disambiguation.cite-suffixes }

      let author = if creator-override != none { creator-override } else { author }

      let author-date = _author-date-prefix(author, entry, suffix-table, suffix-key, punct-style: eff-punct-style, custom-punct: eff-custom-punct, version: eff-version, name-date-separator: _global-config.name-date-separator, show-no-date: eff-show-no-date, custom-terms: eff-custom-terms)
      let rest = dispatch.entry(entry, .._eff-format-opts, show-anon: true, skip-date: true, skip-creator: true)
      _author-date-join(author-date, rest, eff-period-after-creator, entry, eff-punct-style, eff-custom-punct)
    }

    let _plabel(number) = {
      if eff-numbering-style == "paren" { "(" + number + ")" }
      else if eff-numbering-style == "dot" { number + "." }
      else if eff-numbering-style == "plain" { number }
      else if eff-numbering-style == "fullwidth-bracket" { "〔" + number + "〕" }
      else if eff-numbering-style == "fullwidth-paren" { "（" + number + "）" }
      else if eff-numbering-style == "circled" { if eff-circled-engine == "quan" { _quan(int(number)) } else { bib.circled-number(int(number)) } }
      else if eff-numbering-style == none { [] }
      else { "[" + number + "]" }
    }

    let eff-number-width = if eff-numbering-style == none { 0pt }
    else if number-width != auto { number-width }
    else if _global-config.number-width != auto { _global-config.number-width }

    else { measure(_plabel(str(filtered.len() + number-offset))).width }

    let eff-entry-hanging-indent = {
      let v = _api-pick(entry-hanging-indent, _global-config.entry-hanging-indent)
      if v == auto { if eff-bib-style == "author-date" { 1.5em } else { 0pt } } else { v }
    }

    let lbl-align = if eff-number-align == "left" { left }
                    else if eff-number-align == "center" { center }
                    else { right }

    let _html-section-class = if eff-numbering-style == none and eff-entry-hanging-indent != 0pt { "hanging-indent" } else { none }

    let _rendered = bib.render-entries(filtered, (
      bib-data: bib-data,
      _emit-entry: _emit-entry, _emit-entry-author-date: _emit-entry-author-date, _plabel: _plabel, _get-related: _get-related,
      _disambiguation: _disambiguation, _active-list: _active-list,
      eff-bib-style: eff-bib-style, eff-suffixes: eff-suffixes, eff-numeric-date-suffix: eff-numeric-date-suffix, eff-numbering-style: eff-numbering-style,
      eff-show-related: eff-show-related, eff-show-url: eff-show-url, eff-show-annotation: eff-show-annotation,
      eff-end-with-period: eff-end-with-period, eff-custom-drivers: eff-custom-drivers, eff-version: eff-version,
      eff-punct-style: eff-punct-style, eff-custom-punct: eff-custom-punct, eff-hyphenate: eff-hyphenate,
      eff-entry-hanging-indent: eff-entry-hanging-indent, eff-entry-first-line-indent: eff-entry-first-line-indent,
      eff-number-placement: eff-number-placement, _column-mode: _column-mode, _margin-mode: _margin-mode,
      eff-number-gutter: eff-number-gutter, eff-number-width: eff-number-width, eff-back-ref: eff-back-ref,
      list-label: list-label, number-offset: number-offset,
      lbl-align: lbl-align, related-indent: related-indent, eff-creator-idem: eff-creator-idem,
    ))
    let _rows = _rendered.rows
    let _grid-cells = _rendered.grid-cells

    bib.assemble-list(_rows, _grid-cells, (
      title-heading: _title-heading,
      is-html: _IS-HTML,
      html-section-class: _html-section-class,
      number-width: eff-number-width,
      number-gutter: eff-number-gutter,
      entry-spacing: eff-entry-spacing,
      lbl-align: lbl-align,
      ambient-spacing: par.spacing,
    ))
  }

  let _parse-markers(text) = {

    text.matches(regex(_M + "(?s:.+?)" + _M)).map(m => {
      let inner = m.text.trim(_M)

      let nomerge = inner.starts-with(_MNM)
      if nomerge { inner = inner.slice(_MNM.len()) }
      if inner.starts-with(_MF) {

        let sub-parts = inner.slice(_MF.len()).split(_MS)
        (footnote: true, key: sub-parts.at(0), supplement-rank: if sub-parts.len() > 1 { int(sub-parts.at(1)) } else { none }, number: 0, list: none, nomerge: nomerge)
      } else if inner.starts-with(_ML) {
        let parts = inner.split(_ML)
        let listname = parts.at(1, default: "")
        let sub-parts = parts.at(2, default: "0").split(_MS)
        (number: int(sub-parts.at(0)), supplement-rank: if sub-parts.len() > 1 { int(sub-parts.at(1)) } else { none }, list: listname, nomerge: nomerge)
      } else {
        let sub-parts = inner.split(_MS)
        (number: int(sub-parts.at(0)), supplement-rank: if sub-parts.len() > 1 { int(sub-parts.at(1)) } else { none }, list: none, nomerge: nomerge)
      }
    })
  }

  let _cite-context = omni-aux.cite-context

  let _handle-cite(it) = {

    let key = _set-redirect.at(str(it.key), default: str(it.key))

    if key not in bib-data {
      errors.raise("cite.unknown-key", key: str(it.key))
    }

    context {
      let my-list = _active-list.at(here())

      let _list-footnote = if my-list != none { _list-footnote-map.final().at(my-list, default: auto) }
        else { _main-footnote.final() }
      let _footnote-override = _cite-footnote-override.at(here())
      let _eff-footnote = if _footnote-override == true or _footnote-override == false { _footnote-override }
        else if _list-footnote == true or _list-footnote == false { _list-footnote }
        else { cite-footnote }
      if _eff-footnote {

        let supplement-value = if it.supplement == auto { none } else { it.supplement }
        let _nomerge-flag = if _cite-nomerge.at(here()) { _MNM } else { "" }
        return [#metadata((kind: "gb7714-fnsidecar", supplement: supplement-value, overrides: (:)))#(_M + _nomerge-flag + _MF + str(it.key) + _M)]
      }

      let _fast = my-list == none and _list-ids.final().len() == 0 and not state("gb7714-has-fncite", false).final()
      let number = if _fast {
        let _counter = state("gb7714-cite-counter", (order: (), map: (:))).at(here())
        _counter.map.at(key, default: _counter.order.len() + 1)
      } else {
        _cite-context(bib-data, my-list).number-of.at(key, default: none)
      }
      if number == none {
        errors.raise("cite.number-missing", key: str(it.key), redirected: key)
      }

      let has-supplement = it.supplement != none and it.supplement != auto
      let supplement-part = if has-supplement {
        let all-bib-refs = _cite-context(bib-data, my-list).all-refs
        let my-rank = all-bib-refs.position(r => r.location() == it.location())
        if my-rank != none { _MS + str(my-rank) } else { "" }
      } else { "" }

      let _nomerge-flag = if _cite-nomerge.at(here()) { _MNM } else { "" }
      if my-list == none {
        let _marker = _M + _nomerge-flag + str(number) + supplement-part + _M
        if _fast {

          [#state("gb7714-cite-counter", (order: (), map: (:))).update(c => {
            if key in c.map { c } else {
              let order = c.order; order.push(key)
              let key-map = c.map; key-map.insert(key, order.len())
              (order: order, map: key-map)
            }
          })#_marker]
        } else { _marker }
      } else {
        let list-id = _list-ids.at(here()).at(my-list, default: my-list)
        _M + _nomerge-flag + _ML + list-id + _ML + str(number) + supplement-part + _M
      }
    }
  }

  let _handle-cite-native(it) = {
    let key = _set-redirect.at(str(it.key), default: str(it.key))
    if key not in bib-data {
      errors.raise("cite.unknown-key", key: str(it.key))
    }
    context {
      let bibs = state("gb7714-bib-list", ()).final()

      let _footnote-override = _cite-footnote-override.at(here())
      let _any-per-bib-footnote = bibs.any(b => { let flag = b.at("footnote", default: auto); flag == true or flag == false })
      let _emit-footnote-marker() = {

        let supplement-value = if it.supplement == auto { none } else { it.supplement }
        let _nomerge-flag = if _cite-nomerge.at(here()) { _MNM } else { "" }
        [#metadata((kind: "gb7714-fnsidecar", supplement: supplement-value, overrides: (:)))#(_M + _nomerge-flag + _MF + str(it.key) + _M)]
      }
      if _footnote-override == true { return _emit-footnote-marker() }
      if _footnote-override != false and not _any-per-bib-footnote and cite-footnote { return _emit-footnote-marker() }
      let table = _native-route-table(bibs, _set-redirect)
      let hit = _native-route-number(table, it.location())
      if hit == none { return it }
      if _footnote-override != false and _any-per-bib-footnote {
        let _routed-footnote = bibs.at(hit.bib-index, default: (:)).at("footnote", default: auto)
        let _eff-footnote = if _routed-footnote == true or _routed-footnote == false { _routed-footnote } else { cite-footnote }
        if _eff-footnote { return _emit-footnote-marker() }
      }
      let number = hit.number
      let bib-index = hit.bib-index
      let _nomerge-flag = if _cite-nomerge.at(here()) { _MNM } else { "" }
      let has-supplement = it.supplement != none and it.supplement != auto
      let supplement-part = if has-supplement {
        let all-bib-refs = _cite-context(bib-data, none).all-refs
        let my-rank = all-bib-refs.position(r => r.location() == it.location())
        if my-rank != none { _MS + str(my-rank) } else { "" }
      } else { "" }

      [#state("gb7714-native-seen", ()).update(table.seen)#(_M + _nomerge-flag + _ML + str(bib-index) + _ML + str(number) + supplement-part + _M)]
    }
  }

  let _footnote-cite-runs(items) = {
    let runs = {
      let accumulated = ()
      let current = ()
      for (item-index, item) in items.enumerate() {
        if item-index > 0 and (item.nomerge or items.at(item-index - 1).nomerge) {
          accumulated.push(current); current = (item,)
        } else { current.push(item) }
      }
      if current.len() > 0 { accumulated.push(current) }
      accumulated
    }

    runs.map(run => footnote-cite.render(run, overrides => _assemble-footnote-render-options(overrides: overrides), merge-notes: true)).join()
  }
  let _render-footnote-cite-run(raw-items) = {

    _footnote-cite-runs(raw-items.map(raw => (key: raw.key, nomerge: raw.at("nomerge", default: false))))
  }

  let _render-inline-cite-run(raw-items) = context {
    let my-list-id = raw-items.first().at("list", default: none)

    let _native-seen = state("gb7714-native-seen", ()).final()
    let _native = _native-seen.len() > 0

    let my-list = if _native or my-list-id == none { none }
      else {
        let id-map = _list-ids.final()
        let list-id-to-label = (:)
        for (lbl, list-id) in id-map { list-id-to-label.insert(list-id, lbl) }
        list-id-to-label.at(my-list-id, default: my-list-id)
      }

    let seen = if _native {
      let flat = ()
      for array in _native-seen { for (index, k) in array.enumerate() { if k != "" { while flat.len() <= index { flat.push("") }; flat.at(index) = k } } }
      flat
    } else { omni-aux.cited-keys(bib-data, my-list) }

    let _any-supplement = raw-items.any(it => it.at("supplement-rank", default: none) != none)
    let all-bib-refs = if _any-supplement { _cite-context(bib-data, my-list).all-refs } else { () }

    let items = raw-items.map(it => {
      let supplement-content = if it.supplement-rank != none {
        let r = all-bib-refs.at(it.supplement-rank, default: none)
        if r != none and r.supplement != none and r.supplement != auto { r.supplement } else { none }
      } else { none }
      let _bib-index = if _native and it.list != none { int(it.list) } else { none }
      let _key = if _native and _bib-index != none { _native-seen.at(_bib-index, default: ()).at(it.number - 1, default: "") } else { none }
      (number: it.number, supplement: supplement-content, list: it.list, bib-index: _bib-index, key: _key, nomerge: it.at("nomerge", default: false))
    })

    let _seen = ()
    let _dedup = ()
    for it in items {
      let disp-key = if _native { (it.key, it.supplement) } else { (it.number, it.supplement) }
      if disp-key not in _seen { _seen.push(disp-key); _dedup.push(it) }
    }
    let items = _dedup

    let _dedup-key-of(it) = if _native { it.key } else { it.number }
    let _supplement-dedup-keys = items.filter(it => it.supplement != none).map(_dedup-key-of)
    let items = items.filter(it => it.supplement != none or _dedup-key-of(it) not in _supplement-dedup-keys)

    let cite-style-override = _cite-style-state.at(here())
    let eff-style = if cite-style-override != auto and (type(cite-style-override) == str and cite-style-override in ("numeric", "author-date")) { cite-style-override }
      else if my-list != none {
        let list-style-val = _list-style-map.final().at(my-list, default: none)
        if list-style-val != none and list-style-val in ("numeric", "author-date") { list-style-val } else { global-style-cite }
      }
      else {
        let main-style = state("gb7714-main-list-style", none).final()
        if main-style != none and main-style in ("numeric", "author-date") { main-style } else { global-style-cite }
      }

    let eff-form = {
      let override = _cite-form-state.at(here())
      let chosen = _api-pick(override, cite-form)
      if chosen == auto {
        if eff-style == "author-date" { "normal" } else { "super" }
      } else { chosen }
    }

    let _segments-raw = {
      let segments = ()
      let current = ()
      for (i, it) in items.enumerate() {
        if i > 0 and (it.at("nomerge", default: false) or items.at(i - 1).at("nomerge", default: false)) {
          segments.push(current); current = (it,)
        } else { current.push(it) }
      }
      if current.len() > 0 { segments.push(current) }
      segments
    }
    let _group-merge = _segments-raw.len() <= 1
    let eff-cite-punct-style = {
      let override = _cite-punct-style-state.at(here())
      _api-pick(override, cite-punct-style)
    }
    let eff-supplement-style = {
      let override = _cite-supplement-style-state.at(here())
      _api-pick(override, cite-supplement-style)
    }
    let supplement-mode = punct.supplement-style(eff-supplement-style, eff-style)
    let name-style-override = _cite-name-style-state.at(here())
    let eff-name-style = if name-style-override != auto { creators.resolve-name-style(name-style-override, version: version, side: "cite") } else { cite-name-style-eff }

    let _et-al-min-override = _cite-et-al-min-state.at(here())
    let eff-cite-et-al-min = _api-pick(_et-al-min-override, cite-et-al-min)
    let _et-al-use-first-override = _cite-et-al-use-first-state.at(here())
    let eff-cite-et-al-use-first = _api-pick(_et-al-use-first-override, cite-et-al-use-first)
    let _et-al-use-last-override = _cite-et-al-use-last-state.at(here())
    let eff-cite-et-al-use-last = _api-pick(_et-al-use-last-override, cite-et-al-use-last)
    let _et-al-lang-override = _cite-terms-lang-state.at(here())
    let eff-cite-terms-lang = _api-pick(_et-al-lang-override, cite-terms-lang)
    let _compress-min-override = _cite-compress-min-state.at(here())
    let eff-compress-min = _api-pick(_compress-min-override, cite-compress-min)
    let _range-separator-override = _cite-range-separator-state.at(here())
    let eff-cite-range-separator = _api-pick(_range-separator-override, cite-range-separator)

    let _sort-by-override = _cite-sort-by-state.at(here())
    let _cite-sort-by-raw = _api-pick(_sort-by-override, cite-sort-by)
    let _sort-zh-by-override = _cite-sort-zh-by-state.at(here())
    let eff-cite-sort-zh-by = _api-pick(_sort-zh-by-override, cite-sort-zh-by)
    let _collapse-date-override = _cite-collapse-date-state.at(here())
    let eff-collapse-date = _api-pick(_collapse-date-override, cite-collapse-date)

    let eff-cite-sort-by = if _cite-sort-by-raw == auto {
      if eff-style == "author-date" {
        if version == 2025 { (("name", "ascending"), ("date", "ascending")) } else { none }
      } else { "number" }
    } else if _cite-sort-by-raw == none { none }
    else { sort.normalize-sort-by(_cite-sort-by-raw, keys: sort.cite-sort-by-keys, param: if _sort-by-override != auto { "sort-by" } else { "cite-sort-by" }) }

    let document-lang = text.lang

    let p(n, entry: none) = punct.cite(n, eff-cite-punct-style, document-lang, if entry != none { language.get(entry) } else { document-lang }, eff-style)

    let document-comma = p("comma")
    let document-semi  = p("semicolon")

    let eff-cite-range-separator = punct.resolve-cite-separator(eff-cite-range-separator, eff-cite-punct-style, document-lang, document-lang, eff-style, "-")

    let _suffix-map = _list-suffix-map.final()
    let _list-disambiguation = _suffix-map.at(if my-list != none { my-list } else { "" },
      default: (suffixes: _disambiguation.cite-suffixes, escalations: _disambiguation.escalations))
    let suffix-table = if disambiguate.date == false { (:) } else { _list-disambiguation.suffixes }
    let escalation-table = _list-disambiguation.escalations
    let lbl-prefix = if my-list == none { "gb7714" + _LSEP } else { "gb7714" + _LSEP + my-list + _LSEP }

    let _num-link(k, n, display: none) = {
      let link-text = if display != none { display } else { str(n) }
      if my-list == none { _bib-link("gb7714" + _LSEP + k, none, k, link-text) }
      else { _bib-link("gb7714" + _LSEP + my-list + _LSEP + k, my-list, k, link-text) }
    }

    let _key-of(item) = if item.at("key", default: none) != none { item.key } else { seen.at(item.number - 1, default: "") }

    let _name-punct-direction(entry) = punct.cite-direction(eff-cite-punct-style, document-lang, if entry != none { language.get(entry) } else { document-lang }, eff-style)
    let _cite-author(entry) = if entry != none { author-date-cite.author-short(entry, cite-et-al-min: eff-cite-et-al-min, cite-et-al-use-first: eff-cite-et-al-use-first, cite-et-al-use-last: eff-cite-et-al-use-last, name-style: eff-name-style, terms-lang: eff-cite-terms-lang, document-lang: document-lang, sort-use-prefix: sort-use-prefix, name-separator: p("comma", entry: entry), name-suffix-separator: name-suffix-separator, custom-terms: _global-config.custom-terms, punct-style: _name-punct-direction(entry)) } else { "" }

    let _entry-of(item) = bib-data.at(_key-of(item), default: none)
    let _order-items(run-items) = {
      if eff-cite-sort-by == none or run-items.len() <= 1 { return run-items }
      if eff-cite-sort-by == "number" { return run-items.sorted(key: item => item.number) }
      let ordered = run-items
      for (name, order) in eff-cite-sort-by.rev() {
        let key-of = if name == "name" {
          item => {
            let entry = _entry-of(item)
            if entry == none { return "" }
            let author = _author-date-cite-label(_key-of(item), name-format: eff-name-style, suffixes: suffix-table, escalations: escalation-table, et-al-min: eff-cite-et-al-min, et-al-use-first: eff-cite-et-al-use-first, et-al-use-last: eff-cite-et-al-use-last, terms-lang: eff-cite-terms-lang, document-lang: document-lang, parts: true).author
            sort.collate(author, language.get(entry), eff-cite-sort-zh-by)
          }
        } else {
          item => {
            let entry = _entry-of(item)
            (if entry != none { sort.date-key(entry) } else { "999999" }) + suffix-table.at(_key-of(item), default: "")
          }
        }
        ordered = if order == "descending" { ordered.rev().sorted(key: key-of).rev() } else { ordered.sorted(key: key-of) }
      }
      ordered.sorted(key: item => {
        let entry = _entry-of(item)
        if entry != none { sort.lang-key(entry, entry-lang-order: entry-lang-order) } else { "99" }
      })
    }

    let _segments = if eff-style != "author-date" and eff-cite-sort-by == "number" {
      _segments-raw.sorted(key: segment => segment.map(it => it.number).fold(none, (a, b) => if a == none or b < a { b } else { a }))
    } else { _segments-raw }

    let cite-opts = (
      eff-form: eff-form,
      _key-of: _key-of, _cite-author: _cite-author, _order-items: _order-items,
      bib-data: bib-data, publication-date: publication-date, p: p,
      _bib-link: _bib-link, _num-link: _num-link, _author-date-cite-label: _author-date-cite-label,
      lbl-prefix: lbl-prefix, my-list: my-list, suffix-table: suffix-table, escalation-table: escalation-table,
      supplement-mode: supplement-mode, document-semi: document-semi, document-comma: document-comma,
      seen: seen,
      eff-name-style: eff-name-style, eff-cite-et-al-min: eff-cite-et-al-min, eff-cite-et-al-use-first: eff-cite-et-al-use-first,
      eff-cite-terms-lang: eff-cite-terms-lang, document-lang: document-lang,
      eff-compress-min: eff-compress-min, eff-cite-range-separator: eff-cite-range-separator,
      eff-collapse-date: eff-collapse-date, _name-punct-direction: _name-punct-direction,
    )

    let _render-items(items, _group-merge) = {
      if eff-form == none {  }
      else if eff-style == "author-date" { author-date-cite.render-run(items, _group-merge, cite-opts) }
      else { numeric-cite.render-run(items, _group-merge, cite-opts) }
    }

    set super(typographic: false)
    if _segments.len() <= 1 {
      _render-items(items, true)
    } else {
      _segments.map(segment => _render-items(segment, true)).join()
    }
  }

  let _handle-cite-group(matched) = {
    let raw-items = _parse-markers(matched.text)
    if raw-items.any(item => item.at("footnote", default: false)) {
      let segments = ()
      for item in raw-items {
        let item-is-footnote = item.at("footnote", default: false)
        if segments.len() > 0 and segments.last().first().at("footnote", default: false) == item-is-footnote {
          let last-segment = segments.pop(); last-segment.push(item); segments.push(last-segment)
        } else { segments.push((item,)) }
      }
      return segments.map(segment => {
        if segment.first().at("footnote", default: false) { _render-footnote-cite-run(segment) }
        else { _render-inline-cite-run(segment) }
      }).join()
    }
    _render-inline-cite-run(raw-items)
  }

  (
    print-bib: print-bib,
    cite: cite,

    handle-cite: _handle-cite,
    handle-cite-native: _handle-cite-native,
    handle-cite-group: _handle-cite-group,

    bib-data: bib-data,
  )
}
