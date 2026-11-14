/// GB/T 7714 参考文献样式入口：通过 `show` 规则设置全局选项并控制全文的引用渲染。
/// 必须在任何引用之前生效。
///
/// ```typ
/// #show: gb7714                                  // 全默认（2025 版，顺序编码制）
/// #show: gb7714(version: 2015, style: "author-date")
/// 正文引用 @key
/// #bibliography(read("refs.bib"))
/// ```
///
/// 著录格式、正文标注、排序、姓名等选项见参数说明与用户手册。
#let gb7714(
  ..rest,
  /// 引用格式："numeric"（顺序编码制 [1]）/ "author-date"（著者-出版年制 (张三, 2020)）
  style:               "numeric",
  /// GB/T 7714 国标版本：2025（默认，最新国标）/ 2015（旧版，需显式指定）/ 2005（更旧版，需显式指定；差异见 api.typ version 文档）
  version:             2025,
  /// true 时参考文献表输出全部条目（未引用的追加在已引用之后）
  full:                false,
  /// 正文标注形式：auto / "super" 上标 / "inline" 行内 / "normal" 默认形式 / "prose" 叙述式 / "author" 仅作者 / "year" 仅出版年 / "full" 原位显示完整条目 / none 不显示
  cite-form:           auto,
  /// 相邻引用合并为一组：@a@b@c 显示为 [1-3]；脚注模式下合并为一个脚注
  cite-merge:          true,
  /// 带 supplement 的引用显示格式：auto / "compact"（[1:p3, 2]）/ "split"（[1]p3, [2]）
  cite-supplement-style:    auto,
  /// 引用标注内部标点风格。语义见 src/marks/punct.typ 的 `cite` 注释：
  /// "by-doc-and-style"（默认，按文档语言和标注体系自动选择）/ "by-doc-no-space" / "by-doc-with-space"
  /// / "by-entry-and-style" / "by-entry-no-space" / "by-entry-with-space"（跟被引条目语言） / "half"(="half-no-space") / "half-with-space" / "full" / 按样式分派的字典
  cite-punct-style:    "by-doc-and-style",
  /// 顺序编码制中 ≥ N 个连续编号压缩为范围（如 [1-5]）
  cite-compress-min:   2,
  /// 引文区间 [1-5] 的起讫号连接符（默认 -，与 page-range-separator 平行独立）
  cite-range-separator: "-",
  /// 标注两侧相邻空格：auto 在相邻字符为 CJK 时删除（中文 `见 @key 所述` 不留空格，西文保留）/ true 始终保留 / false 始终删除
  cite-adjacent-space: auto,
  /// 注释模式：none 使用行内标注（默认）/ "foot" 使用脚注 / "end" 使用尾注
  note:                none,
  /// 正文引用「等 / et al」的触发阈值：责任者人数达到 N 时截断
  cite-et-al-min:      2,
  /// 正文引用截断后保留前 N 位作者
  cite-et-al-use-first: 1,
  cite-et-al-use-last: 0,
  /// 正文引用「等 / et al」截断词语言："by-doc"（跟文档语言 text.lang）/ "by-entry"（跟被引条目）/ "zh"/"ja"/"ko"/"ru"/… 强制
  cite-terms-lang:  "by-entry",
  /// 正文引用西文姓名格式：auto（只姓、原大小写）或八维字典（order / family-case / given-form / given-initial-separator / given-separator / given-case / family-given-separator / given-family-separator）
  cite-name-style:    auto,
  /// 正文标注中著者与出版日期的分隔符：auto（中日文用全角逗号；西文在 2005 版用空格、2015/2025 版用逗号）/ 单个标点字符（自动转换全角或半角）/ 任意字符串（原样输出）
  cite-name-date-separator: auto,
  /// 生成不可见的 bibliography，供 LSP 补全 @key；不产生可见输出
  cite-completion:     true,
  /// 参考文献表中的西文姓名格式：auto 或姓名格式字典（order / family-case / given-form / given-initial-separator / given-separator / given-case / family-given-separator / given-family-separator）；auto 按 version 取值
  bib-name-style:     auto,
  /// 西文姓名后缀（Jr/Sr）前分隔符：auto（随 version：2015 取 ", " 逗号、2025 取 " " 空格）/ 任意字符串
  name-suffix-separator: auto,
  /// 译者截断词（等/et al.）与角色词（译/trans.）之间的分隔符：auto（中文 2005/2025 版为「等，译」，2015 版为「等译」）/ ""（不加分隔符）/ ", "（加逗号）/ 单个标点字符（自动转换全角或半角）/ 任意字符串
  et-al-translator-separator: auto,
  /// 析出文献题名与出处项之间的分隔符：默认 "//"，也可使用任意字符串或多语言字典
  component-part-separator: "//",
  /// 参考文献表中著者与出版日期的分隔符：auto（2005 版用句点，2015/2025 版用逗号，并自动转换全角或半角）/ 单个标点字符 / 任意字符串（原样输出）
  bib-name-date-separator: auto,
  /// 参考文献表「等 / et al」触发阈值：作者多于 N 才截断（国标默认 3）
  bib-et-al-min:       4,
  /// 参考文献表截断后保留前 N 位作者（国标默认 3）
  bib-et-al-use-first: 3,
  bib-et-al-use-last: 0,
  /// auto（默认）：著者-出版年制显示「佚名 / Anon」，顺序编码制留空；true / false 强制显示或隐藏
  show-anon:           auto,
  /// 出版日期不明时的占位（与 show-anon 逐字同构）：auto=著者-出版年制显示「无日期」、顺序编码制留空
  show-no-date:        auto,
  /// 缺出版年时从哪个字段推定：none=不推定（默认）；"urldate"=取引用日期的年，著录为 [2024]（方括号=推定值）
  date-fallback:       none,
  /// 截断后是否补充“等 / et al.”（默认启用）；false 仅省略该词，不改变保留人数；完整列出全部责任者时，应将 et-al-min 设为大于责任者人数的值
  show-et-al:           true,
  /// 析出文献作者与图书编者相同时，省略重复的编者
  dedup-author-editor:      false,
  /// 参考文献表标题：auto（随文档语言取「参考文献 / Bibliography」等，与原生 typst 本地化一致）/ none 不显示 / 自定义 content
  title:               auto,
  /// 条目第二行及后续各行的缩进量；`auto` 在无编号的著者-出版年制中为 1.5em，其余（顺序编码制、带显式编号的著者-出版年制）为 0pt
  entry-hanging-indent:     auto,
  /// 条目*首行缩进量*：设为正值即「首行缩进 + 余行顶格」（国标原文式，与悬挂互斥）；默认 `0pt`。
  entry-first-line-indent:  0pt,
  /// 条目间距：auto 继承段落间距
  entry-spacing:            auto,
  /// 编号与正文之间的列间距——「编号后那道间隔」，视编号 / 正文为两列、即列间 gutter
  /// （默认 0.65em，与 typst 原生 gb-7714-2015-numeric 悬挂缩进一致）
  number-gutter:    0.65em,
  /// 参考文献表编号位置："column"（独立编号列）/ "margin"（版心外）/ "inline"（条目正文内）
  number-placement:    "column",
  /// 编号格式："bracket" [1] / "paren" (1) / "dot" 1. / "plain" 1 / "fullwidth-bracket" ［1］ / "fullwidth-paren" （1） / "shell" 〔1〕（六角括号，旧 GB-1987）/ "circled" ①（默认使用 Unicode；(circled: "quan") 使用 quan 包绘制）/ none 不显示编号
  bib-numbering-style:        auto,
  /// 正文标注编号的括号格式；bib-numbering-style 控制参考文献表编号，本参数控制正文中的 [1]："bracket" [1]（默认）/ "paren" (1) / "fullwidth-bracket" ［1］ / "fullwidth-paren" （1）/ "shell" 〔1〕（六角括号，旧 GB-1987）
  cite-numbering-style:   "bracket",
  /// 编号对齐："left"（默认，同原生） / "right" / "center"
  number-align:        "left",
  /// 编号列宽度：auto 自动测量最宽编号
  number-width:        auto,
  number-punct-width:  "full",
  /// true 时参考文献表编号可点击跳回正文首次引用处
  back-ref:            false,
  /// 正文标注消歧：标量统一控制所有机制，或用字典分别设置 (date: 年份 a/b/c, given-name: 同姓时补名字, names: 展开 et al. 名单)；given-name / names 的 auto 按正文标注体系取值
  disambiguate:        auto,
  /// 参考文献表排序键：auto 根据标注体系确定 / none 保持引用顺序 / 数组按顺序指定排序键
  bib-sort-by:         auto,
  /// 合并引用组内排序键：auto 根据引用体系和版本选择（顺序编码制按编号升序；著者-出版年制 2025 按责任者、日期排序，2015/2005 保持书写顺序）/ none 保持书写顺序 / 数组（键 "name"/"date"，可指定方向）
  cite-sort-by:        auto,
  /// 自定义排序：传内容块 [@k1@k2]，对应条目优先排列
  sort-keys:           none,
  /// 参考文献表中文姓名排序："pinyin" 拼音 / "bihua" 笔画
  bib-sort-zh-by:     "pinyin",
  /// 合并引用组内排序（cite-sort-by 的 name 键）的中文排序方案："pinyin" / "bihua"
  cite-sort-zh-by:    "pinyin",
  /// 著者-出版年制合并组内的年份折叠：同著者相邻条目并组、年份连列（张三，2020，2021）；带页码的条目不参与
  cite-collapse-date:  true,
  /// 相邻条目的责任者相同时，从第二条起用此字符串替代责任者（如 "———"；相当于 biblatex 的 dashed 或 AMS 的 bysame）；none 关闭
  creator-idem:        none,
  /// 西文姓名前缀粒子（van/von/de/della）是否参与排序与行内标注（对齐 biblatex useprefix）：false 跳过（Beethoven 排 B）/ true 计入（van Beethoven 排 V）
  sort-use-prefix:     false,
  /// 多语言混排时的语种分组顺序；空数组表示不按语种分组，而按统一排序键排序
  entry-lang-order:          ("zh", "ja", "ko", "en", "fr", "ru"),
  /// 缺 langid 时的语言判定："auto" / "fast" 纯字符脚本 / "accurate" 字符表+姓氏表+模型
  entry-lang-detect:         "auto",
  /// 是否显示文献类型标识（如 [M]、[J]）：true 显示；auto 在单个著录项目中省略；false 隐藏；也可按条目类型设置
  show-mark:           true,
  /// 显示文献载体标识（如 /OL）
  show-medium:         true,
  /// 显示 URL（条目自动标 /OL）：bool / "online-only" 仅网络文献著录 / 字典按条目控（键同 show-mark）
  show-url:            true,
  /// 显示引用日期（urldate 字段）
  show-urldate:        true,
  /// 渲染由 related 和 relatedtype=lanversion 指定的双语关联条目
  show-related:        true,
  /// 专利条目显示专利国
  show-patent-country: false,
  /// 多卷书卷号与分卷名之间的间距 gutter：auto（普通词间空格，对齐官方 CSL）/ 长度（如 1em = 李泽平 \quad 宽间距）
  volume-title-gutter: auto,
  /// 出版地缺失时是否补充 [S.l.] / 出版地不详。auto 仅在存在出版者时补充；true 始终补充；false 留空
  show-sine-loco:      auto,
  /// 出版者缺失时是否补充 [s.n.] / 出版者不详。auto 仅在存在出版地时补充；true 始终补充；false 留空
  show-sine-nomine:    auto,
  /// 出版年缺失时是否显示占位文字（[s.a.] / 日期不详）：GB 未作规定，供特定样式使用；默认关闭，仅对顺序编码制有效
  show-sine-anno:      false,
  /// 学位论文在 [D] 后附加「硕士学位论文 / 博士学位论文」注记
  show-degree:         false,
  /// 是否著录丛书项（series 字段，如「经济科学译库」）。默认关——GB 著录格式不含丛书项，对齐标准与各参照实现
  show-series:         false,
  /// 西文姓名前缀（如 van der）的著录形式：auto 根据版本确定，也可设置前缀位置
  prefix-last:         auto,
  /// 条目末尾追加 annotation / annote 字段内容
  show-annotation:     false,
  /// true 时用 shortjournal 字段替代期刊名
  short-journal:       false,
  /// URL / DOI 渲染为可点击超链接
  hyperlink:           true,
  /// 条目题名渲染为可点击超链接（需有 url / doi）
  hyperlink-title:     false,
  /// 永久标识符显示控制，如 (doi: false, max: 1, rest: "online-only", book: false)
  show-pid:            (:),
  /// 永久标识符的显示顺序；未列出的内置标识符按照默认顺序排列在其后
  pid-priority: ("cstr", "doi", "eprint", "isbn", "issn"),
  /// URL 已含同一永久标识符时不重复著录：auto 随版本（2015 并列、2025 去重）/ true 去重 / false 都列
  dedup-url-pid:       auto,
  /// 参考文献表标点（cite 值的子集，无 -and-style）：auto（随 version：2015 取 "half-with-space"、2025 取 "full"，即部分全角对齐 GB/T 7714—2025）/ "half-with-space" / "half"(="half-no-space") / "full" / "by-doc-no-space"/"-with-space"（分隔符跟文档语言） / "by-entry-no-space"/"-with-space"（跟条目）
  bib-punct-style:     auto,
  /// PID(DOI/CSTR/eprint 等)标签与值间那一个冒号的全/半角，独立于结构冒号(出版项/年:页)。取值同 bib-punct-style：auto（跟随 bib-punct-style，即历史行为） / "half"(DOI:x) / "half-with-space"(DOI: x) / "full"(DOI：x) / "by-doc-*" / "by-entry-*"；非 auto 时绕过 custom-punct 的 colon
  pid-colon-style:     auto,
  /// 覆盖指定的*结构标点*（只影响著录格式字符串，不修改用户字段；替换值原样输出），如 (",": "，", ":": "：")
  custom-punct:     (:),
  /// 矫正长文本字段（题名等）里用户输入的标点全/半角
  correct-punct:       false,
  /// 未定义 LaTeX 命令的处理方式：true（默认）报错；false 忽略命令并保留其后的内容
  latex-strict-command: true,
  /// 未转义的 LaTeX 特殊字符及未配对花括号的处理方式：true（默认）报错；false 按原样输出
  latex-strict-char:   true,
  /// URL 每 N 个连续字符插一个断点机会：none 不插 / 1 任意处可断
  url-break-every:     1,
  /// URL 断行位置是否显示连字符：false（默认）不显示；true 在行末显示软连字符
  url-break-hyphen:    false,
  /// 显连字符时，URL 分隔符(RFC 3986 delimiter,`/ . : ? &`)断点算不算在内：true 含（默认，= jurlstify 0.2.1） / false 仅 every 救济断点显（旧 0.2.0 partial）
  url-break-hyphen-at-delimiters: true,
  /// 长标题字段大小写：none 原样 / "sentence" 句首大写 / "title" Title Case; 字典按字段+rest; {DNA} 花括号保护
  titles-text-case:    none,
  /// 按位置施加斜体 / 加粗 / 包裹符（替代 italic-book-title / italic-journal / bold-journal-volume）
  emphasis:            (:),
  /// 作者字段后加句点（false 改空格）
  period-after-creator: true,
  /// 末尾句点：auto 在单项著录时省略、在多项著录时添加；true 始终添加；false 始终省略
  show-end-period:     auto,
  /// 文献类型标识 [M] 前加空格
  space-before-mark:   false,
  /// 文献类型标识方括号半/全角："half" [M]（默认，GB 标准）/ "full" ［M］（全角方括号，斜杠恒半角）
  mark-medium-bracket-style: "half",
  /// 页码前加空格（: 123 与 :123）
  space-before-pages:  true,
  /// 注释（annotation/annote）前加空格：auto 按注释首字符宽窄定（CJK / 全角标点不加），true/false 强制
  space-before-annotation: auto,
  /// 页码范围连字符，如 "-" / "～"
  page-range-separator:       "-",
  /// 日期区间连接符：auto 保留破折号；字符串或按条目语言设置的字典
  date-range-separator:       auto,
  /// 起讫页码的位数格式：none 原样输出（默认）/ "expanded" 补全 / "minimal" / "minimal-two" / "chicago-15" / "chicago-16"
  page-range-style:    none,
  /// 参考文献表内允许西文断字
  hyphenate:           true,
  /// 是否按条目语言设置 text(lang:)：用于西文连字和 CJK 本地化字形；auto 按版本设置，true 启用，false 禁用
  entry-localized-glyphs:   auto,
  /// 重复引用时的脚注形式；首次引用始终完整著录
  note-repeat-style:     auto,
  /// 紧邻重复是否简化为「同上」：auto = true（官方规则）/ false 紧邻同隔开一样取 note-repeat-style
  note-ibid:       auto,
  /// 重复引用判断的重置范围：none 表示全文（默认）；selector 可按一级标题等位置分段。进入新范围后，首次引用重新显示完整著录，「同上」和「同③」不跨范围引用
  note-repeat-reset: none,
  /// 默认使用 Unicode 圈码；(circled: "quan") 使用 quan 包。默认模式可用 set footnote(numbering: ...) 指定其他编号格式。
  note-numbering-style:             "circled",
  /// 按条目类型设置默认文献类型标识，如 (software: "SW", mytype: "XX")
  custom-marks:      (:),
  /// 自定义条目模板字典，如 (book: "author `. ` title")
  custom-drivers:    (:),
  /// 用户自定义本地化字面量 token；键 ∈ et-al/editor/translator/anon/sine-loco/sine-nomine/ma-thesis/phd-thesis 时覆盖内置词，否则注册新词
  custom-terms:        (:),
  /// 用户自定义字段 token：把 bib 字段暴露成模板 token（auto 纯原样传递 / (field:.., prefix:.., suffix:..)）
  custom-fields:       (:),
  /// 用户自定义永久标识符（field:.., prefix:.., resolver:..），著录于条目末尾
  custom-pids:         (:),
  /// 注册新语言码（(de: ("german", "deu")) 等），让内置识别外的西文语种能出自己的本地化术语；仅影响显式标注 langid 的西文条目
  custom-languages:    (:),
  /// 缺题名时是否报错：false 容错处理为空题名，true 遇缺 / 空 title 即报错指明该 key
  warn-missing-title:  false,
) = {

  import "src/api.typ": _is-native-mode
  import "src/errors.typ" as _errors
  import "src/style.typ" as _style
  import "src/elements/creators.typ" as _creators
  import "src/elements/imprint/date.typ": validate-range-separator as _validate-date-range-separator
  import "src/parse/csl-json.typ" as _csl-json
  import "src/api.typ": apply-note-numbering as _apply-note-numbering, bib-keys as _bib-keys, BIB-ENTRY-RE as _BIB-ENTRY-RE, gb7714 as _create-instance
  import std: type as _std-type, bibliography as _std-bibliography, cite as _std-cite, version as _std-version
  import "src/errors.typ": raise as _raise
  import sys: version as _typst-version
  _errors.check-enum("cite-form", cite-form, extra: (auto,))
  if std.type(bib-numbering-style) == dictionary {
    _errors.check-circled-dict("bib-numbering-style", bib-numbering-style)
  } else { _errors.check-enum("bib-numbering-style", bib-numbering-style, extra: (auto,)) }
  _errors.check-enum("number-align", number-align)
  _errors.check-enum("number-punct-width", number-punct-width)
  _errors.check-enum("mark-medium-bracket-style", mark-medium-bracket-style)
  _creators.validate-name-style(bib-name-style, param: "bib-name-style")
  _creators.validate-name-style(cite-name-style, param: "cite-name-style")
  if std.type(bib-punct-style) != dictionary { _errors.check-enum("bib-punct-style", bib-punct-style, extra: (auto,)) }
  _errors.check-enum("bib-punct-style", pid-colon-style, extra: (auto,), alias: "pid-colon-style")
  if cite-adjacent-space != auto and std.type(cite-adjacent-space) != bool { _errors.raise("shell.cite-adjacent-space-invalid", value: repr(cite-adjacent-space)) }
  if space-before-annotation != auto and std.type(space-before-annotation) != bool { _errors.raise("shell.space-before-annotation-invalid", value: repr(space-before-annotation)) }
  if std.type(cite-punct-style) != dictionary { _errors.check-enum("punct-style", cite-punct-style, extra: (auto,), alias: "cite-punct-style") }
  _errors.check-enum("supplement-style", cite-supplement-style, extra: (auto,), alias: "cite-supplement-style")
  _errors.check-enum("entry-lang-detect", entry-lang-detect)
  _errors.check-enum("date-fallback", date-fallback)
  _validate-date-range-separator(date-range-separator)
  _errors.check-enum("sort-zh-by", bib-sort-zh-by, alias: "bib-sort-zh-by")
  _errors.check-enum("sort-zh-by", cite-sort-zh-by, alias: "cite-sort-zh-by")
  import "src/bibliography/sort.typ" as _sort
  if bib-sort-by != auto and bib-sort-by != none { let _ = _sort.normalize-sort-by(bib-sort-by, param: "bib-sort-by") }
  if cite-sort-by != auto and cite-sort-by != none { let _ = _sort.normalize-sort-by(cite-sort-by, keys: _sort.cite-sort-by-keys, param: "cite-sort-by") }
  if cite-collapse-date not in (true, false) {
    _errors.raise("collapse-date.bad-value", param: "cite-collapse-date", allowed: "true / false", got: repr(cite-collapse-date))
  }
  import "src/sentinel.typ": _M, _MB, _MSP, _CJK-ADJ

  let (eff-style-cite, eff-style-bib, eff-version, eff-note) = {
    let normalized = _style.normalize(style)
    if normalized.native { _errors.raise("shell.style-invalid") }
    let resolved-version = if normalized.version != auto { normalized.version } else { version }

    let resolved-note = if normalized.note != auto { normalized.note } else { note }
    let axes = _style.resolve(normalized, (cite: none, bib: none))
    (axes.cite, axes.bib, resolved-version, resolved-note)
  }

  let _emit-body(body-content) = _apply-note-numbering(note-numbering-style, body-content)
  let style-axes = (cite: eff-style-cite, bib: eff-style-bib)

  let config = (
    style: style-axes, version: eff-version, full: full,
    cite-form: cite-form, cite-merge: cite-merge, cite-supplement-style: cite-supplement-style,
    cite-punct-style: cite-punct-style, cite-compress-min: cite-compress-min, cite-range-separator: cite-range-separator,
    cite-adjacent-space: cite-adjacent-space,
    note: eff-note, cite-et-al-min: cite-et-al-min,
    cite-et-al-use-first: cite-et-al-use-first, cite-et-al-use-last: cite-et-al-use-last, cite-terms-lang: cite-terms-lang, cite-name-style: cite-name-style,
    cite-name-date-separator: cite-name-date-separator,
    cite-completion: cite-completion,
    bib-name-style: bib-name-style, name-suffix-separator: name-suffix-separator, et-al-translator-separator: et-al-translator-separator, component-part-separator: component-part-separator, bib-name-date-separator: bib-name-date-separator, bib-et-al-min: bib-et-al-min, bib-et-al-use-first: bib-et-al-use-first, bib-et-al-use-last: bib-et-al-use-last,
    show-anon: show-anon, show-no-date: show-no-date, date-fallback: date-fallback, show-et-al: show-et-al, dedup-author-editor: dedup-author-editor, creator-idem: creator-idem,
    title: title, entry-hanging-indent: entry-hanging-indent, entry-first-line-indent: entry-first-line-indent, entry-spacing: entry-spacing, number-gutter: number-gutter,
    bib-numbering-style: bib-numbering-style, cite-numbering-style: cite-numbering-style, number-placement: number-placement, number-punct-width: number-punct-width, number-align: number-align, number-width: number-width,
    back-ref: back-ref,
    disambiguate: disambiguate, bib-sort-by: bib-sort-by, cite-sort-by: cite-sort-by, sort-keys: sort-keys, bib-sort-zh-by: bib-sort-zh-by, cite-sort-zh-by: cite-sort-zh-by, cite-collapse-date: cite-collapse-date, sort-use-prefix: sort-use-prefix, entry-lang-order: entry-lang-order, entry-lang-detect: entry-lang-detect,
    show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-urldate: show-urldate,
    show-related: show-related, show-patent-country: show-patent-country, volume-title-gutter: volume-title-gutter,
    show-sine-loco: show-sine-loco, show-sine-nomine: show-sine-nomine, show-sine-anno: show-sine-anno, show-degree: show-degree, show-series: show-series, prefix-last: prefix-last, show-annotation: show-annotation,
    short-journal: short-journal, hyperlink: hyperlink, hyperlink-title: hyperlink-title,
    show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid,
    bib-punct-style: bib-punct-style, pid-colon-style: pid-colon-style, custom-punct: custom-punct, correct-punct: correct-punct,
    latex-strict-command: latex-strict-command, latex-strict-char: latex-strict-char,
    url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters,
    titles-text-case: titles-text-case, emphasis: emphasis,
    period-after-creator: period-after-creator, show-end-period: show-end-period,
    space-before-mark: space-before-mark, mark-medium-bracket-style: mark-medium-bracket-style, space-before-pages: space-before-pages, space-before-annotation: space-before-annotation,
    page-range-separator: page-range-separator, date-range-separator: date-range-separator, page-range-style: page-range-style, hyphenate: hyphenate, entry-localized-glyphs: entry-localized-glyphs, note-numbering-style: note-numbering-style,
    note-repeat-style: note-repeat-style, note-ibid: note-ibid, note-repeat-reset: note-repeat-reset,
    custom-marks: custom-marks, custom-drivers: custom-drivers, custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids, custom-languages: custom-languages, warn-missing-title: warn-missing-title,
  )

  if rest.pos().len() == 0 {
    let _validate() = none
    let _ = _validate(..rest)
    let shell-config = { let c = config; c.insert("style", style); c }
    return body => gb7714(body, ..shell-config)
  }
  let _extract(first) = first
  let first = _extract(..rest)
  if _std-type(first) != content {
    _raise("shell.bib-source-positional")
  }
  let body = first
  state("gb7714-config", (:)).update(config)
  state("gb7714-latex-strict-command", true).update(latex-strict-command)
  state("gb7714-latex-strict-char", true).update(latex-strict-char)

  let _cite-config() = config
  let _build-instance() = {
    let sources = state("gb7714-sources", (:)).final()
    if sources.len() == 0 { return none }

    let merged-config = _cite-config()
    if "cite-completion" in merged-config { let _ = merged-config.remove("cite-completion") }

    let _seen-k = ()
    let _has-dup = false
    for (_, v) in sources {
      for k in _bib-keys(v) {
        if k in _seen-k { _has-dup = true; break }
        _seen-k.push(k)
      }
      if _has-dup { break }
    }
    if _has-dup {

      let merged = sources.values().join("\n")
      let entry-matches = merged.matches(_BIB-ENTRY-RE)
      let _kept-keys = ()
      let _out = ""
      for (i, m) in entry-matches.enumerate() {
        let k = m.captures.at(1)
        let segment-end = if i + 1 < entry-matches.len() { entry-matches.at(i + 1).start } else { merged.len() }
        let segment = merged.slice(m.start, segment-end)
        if k not in _kept-keys { _kept-keys.push(k); _out += segment }
      }
      return _create-instance((merged: _out), cite-completion: false, ..merged-config)
    }
    _create-instance(sources, cite-completion: false, ..merged-config)
  }

  show _std-bibliography: it => context {
    let flag = state("gb7714-lsp-bib-active", false).at(it.location())
    if flag == "visible" { return it }
    if flag == "render" {
      let idx = query(selector(_std-bibliography).before(it.location(), inclusive: false))
        .filter(b => state("gb7714-lsp-bib-active", false).at(b.location()) == "render").len()
      return state("gb7714-render-payloads", ()).final().at(idx, default: none)
    }
    if flag == true { return }
    _raise("shell.native-bibliography-called")
  }

  show _std-cite: it => context {
    let bibs = state("gb7714-bib-list", ()).final()

    if _typst-version < _std-version(0, 15, 0) and bibs.len() > 1 and bibs.any(b => b.native-style) {
      _raise("shell.native-014-single-bib")
    }

    if bibs.any(b => b.native-style) and bibs.any(b => b.label != none) {
      _raise("shell.native-with-label")
    }
    let native-mode = _is-native-mode(bibs)
    if native-mode {

      if state("gb7714-config", (:)).final().at("note", default: none) != none and bibs.any(b => b.native-style) {
        _raise("shell.footnote-with-native")
      }

      if bibs.any(b => b.native-style) { return it }
      if it.form == none { return it }

      let instance = _build-instance()
      if instance == none { return it }
      return (instance.handle-cite-native)(it)
    }
    let instance = _build-instance()
    if instance == none { return it }
    let f = instance.handle-cite
    f(it)
  }

  show regex(_MB): _ => []

  let _global-super = if cite-form == auto { eff-style-cite != "author-date" } else { cite-form == "super" }
  let _eat-leading-spaces = _global-super or (note != none)
  let _cjk = _CJK-ADJ
  let _sp = "[ \u{00A0}\t]+"
  let _never = "\u{E7FF}"
  let _lead-pat = if cite-adjacent-space == false or _eat-leading-spaces { _sp + "\u{2060}" }
    else if cite-adjacent-space == auto { _cjk + _sp + "\u{2060}" }
    else { _never }
  let _trail-pat = if cite-adjacent-space == false { _MSP + _sp }
    else if cite-adjacent-space == auto { _MSP + _sp + _cjk }
    else { _never }
  show regex(_MSP): _ => []
  let _lead-keeps-char = cite-adjacent-space == auto and not _eat-leading-spaces
  let _trail-keeps-char = cite-adjacent-space == auto
  show regex(_lead-pat): it => if _lead-keeps-char { [#it.text.clusters().first()#sym.wj] } else { sym.wj }
  show regex(_trail-pat): it => if _trail-keeps-char { [#it.text.clusters().last()] } else { [] }
  let _between-pat = if cite-adjacent-space == auto { _MSP + _sp + _cjk + _sp + "\u{2060}" } else { _never }
  show regex(_between-pat): it => [#it.text.clusters().filter(c => c != "\u{2060}" and c.trim() != "" and not _MSP.contains(c)).join()#sym.wj]
  show regex(_M + "(?s:.+?)" + _M + "((?:[^\\S\\n]|\u{2060}|" + _MSP + ")*" + _M + "(?s:.+?)" + _M + ")*"): m => context {
    let instance = _build-instance()
    if instance == none { return m }
    let f = instance.handle-cite-group
    f(m)
  }
  if _typst-version < _std-version(0, 15, 0) {
    show ref: it => context {
      let instance = _build-instance()
      if instance == none { return it }
      let bib-data = instance.bib-data
      if str(it.target) not in bib-data { return it }
      let supplement = it.fields().at("supplement", default: none)
      if supplement == auto { supplement = none }
      let c = _std-cite(it.target, supplement: supplement)

      let cite-merge = state("gb7714-config", (:)).get().at("cite-merge", default: true)
      [#state("gb7714-cite-nomerge", false).update(not cite-merge)#sym.wj#c#_MSP#state("gb7714-cite-nomerge", false).update(false)]
    }
    _emit-body(body)
  } else {

    show ref: it => context {
      let config = state("gb7714-config", (:)).get()
      let leading-wj = sym.wj
      let _bibs = state("gb7714-bib-list", ()).final()
      if _is-native-mode(_bibs) and _bibs.any(b => b.native-style) {

        return it
      } else if _is-native-mode(_bibs) {

        let instance = _build-instance()
        if instance == none { return it }
        if str(it.target) not in instance.bib-data { return it }
        let supplement = it.fields().at("supplement", default: none)
        if supplement == auto { supplement = none }
        let c = _std-cite(it.target, supplement: supplement)
        let cite-merge = config.at("cite-merge", default: true)
        [#leading-wj#state("gb7714-cite-nomerge", false).update(not cite-merge)#c#_MSP#state("gb7714-cite-nomerge", false).update(false)]
      } else {
        let instance = _build-instance()
        if instance == none { return it }
        if str(it.target) not in instance.bib-data { return it }
        let supplement = it.fields().at("supplement", default: none)
        if supplement == auto { supplement = none }
        let c = _std-cite(it.target, supplement: supplement)
        let cite-merge = config.at("cite-merge", default: true)
        [#leading-wj#state("gb7714-cite-nomerge", false).update(not cite-merge)#c#_MSP#state("gb7714-cite-nomerge", false).update(false)]
      }
    }
    _emit-body(body)
  }
}

/// 生成参考文献表。接口与 Typst 原生 `bibliography` 相近；第一个位置参数接受文献数据
/// （`read("refs.bib")` 的结果；多这一层 `read()` 是 Typst 包沙箱的限制），
/// `title` / `full` / `style` / `target` / `group` 与原生同名同义。
///
/// 在此之上扩展：`label` 命名列表、按类型 / 关键词 / 自定义函数过滤、排序与布局的逐表覆盖。
/// **多次调用即多个独立列表**，编号自动全局连续。
///
/// ```typ
/// #bibliography(read("refs.bib"))                      // 单表
/// #bibliography(read("ch1.bib"), label: "ch1")         // 命名列表，配合 set-bib-label 分区
/// #bibliography(read("refs.bib"), filter: e => e.entry_type == "book")
/// ```
#let bibliography(
  /// bib 内容：read("refs.bib") 的结果（str / bytes），或它们的数组
  source,
  /// 列表标题：auto 按文档语言（参考文献 / Bibliography 等，与原生 typst 本地化一致）/ none 不输出 / 自定义 content
  title:          auto,
  /// true 时除已引用条目外追加全部条目（与原生同名）；auto 跟随全局 gb7714(full: ..)
  full:           auto,
  /// 本列表样式："numeric" / "author-date" 使用本包实现；其他 CSL 样式名或 CSL 数据由 Typst 原生引擎渲染；none 跟随全局设置
  style:          none,
  /// 本列表国标版本：2015 / 2025；auto 跟随全局；与 style 国标全名锁定矛盾时报错（名实一致）
  version:        auto,
  /// 本列表的注释模式："foot" 使用脚注，"end" 生成尾注，none 使用行内标注，auto 跟随全局设置
  note:           auto,
  /// Typst 0.15 的原生 cite 选择器，如 selector(std.cite).within(<ch1>)
  target:         auto,
  /// typst 0.15 原生编号分组；auto 全文档连续编号；需 typst 0.15+
  group:          auto,
  /// 命名列表：配合 set-bib-label("x") / cite(bib-label: "x") 归属引用（0.14 可用的多列表方案）。
  /// *也用于隔离子列表*：给一个（哪怕无 cite 归属的）label，本表即独立编号、从 [1] 起（命名列表 offset 恒 0）。
  label:          none,
  /// 按 bib 条目类型过滤，如 "book" 或 ("book", "article")
  entry-type:     none,
  /// 自定义过滤函数 entry => bool
  filter:         none,
  /// 仅渲染指定条目：传内容块 [@k1@k2]，按书写顺序
  keys:           none,
  /// 按 keywords 字段子串匹配过滤
  keyword:        none,
  /// 按文献类型标识过滤，如 "M" / "J" / ("C", "G")
  mark:           none,
  /// 自定义排序：auto 继承全局 gb7714(sort-keys:) / [@k1@k2] 优先排列，其余追加 / none 不排
  sort-keys:      auto,
  /// 消歧后缀：auto 继承全局 / true 一律加 / false 一律不加
  disambiguate:   auto,
  /// 单个参考文献表的排序键：auto 继承全局 bib-sort-by / none 保持引用顺序 / 数组，元素为键名（"name" "date" "title"，默认升序）或带方向的字典 ("date": "descending")
  sort-by:        auto,
  /// 单个参考文献表的中文姓名排序方式：auto 继承全局 bib-sort-zh-by / "pinyin" / "bihua"
  sort-zh-by:     auto,
  /// 紧邻同责任者替代串：auto 继承全局 creator-idem / none 关 / 字符串
  creator-idem:   auto,
  /// 姓名前缀 van/von/de 是否参与排序与行内标注（对齐 biblatex useprefix）；auto 跟随全局
  sort-use-prefix:     auto,
  /// 同 gb7714 同名参数；auto 跟随全局
  emphasis: auto,
  /// 页码范围连字符；auto 跟随全局
  page-range-separator:       auto,
  /// 日期区间连接符；auto 跟随全局
  date-range-separator:       auto,
  page-range-style:    auto,
  /// 同 gb7714 同名参数；auto 跟随全局
  show-end-period:     auto,
  /// 「等 / et al」触发阈值；auto 跟随全局
  et-al-min:           auto,
  /// 截断后保留前 N 位；auto 跟随全局
  et-al-use-first:     auto,
  /// 截断后在省略号之后再保留末尾 N 位（0 = 关）；auto 跟随全局
  et-al-use-last:      auto,
  /// 条目余行（悬挂）缩进量；auto 跟随全局
  entry-hanging-indent:     auto,
  /// 条目首行缩进量；auto 跟随全局
  entry-first-line-indent:  auto,
  number-placement:    auto,
  /// URL / DOI 超链接；auto 跟随全局
  hyperlink:           auto,
  /// 题名超链接；auto 跟随全局
  hyperlink-title:     auto,
  /// 西文断字；auto 跟随全局
  hyphenate:           auto,
  /// 是否按条目语言设置 text(lang:)；auto 跟随全局设置
  entry-localized-glyphs:   auto,
  /// 条目间距；auto 跟随全局
  entry-spacing:            auto,
  /// 编号与正文之间的列间距（「编号后那道间隔」）；auto 跟随全局
  number-gutter:    auto,
  /// 编号样式："bracket" / "paren" / "dot" / "plain" / "fullwidth-bracket" ［1］ / "fullwidth-paren" / "shell" 〔1〕 / "circled"（可展开 (circled: "quan") 选绘制引擎）/ none；auto 跟随全局
  bib-numbering-style:        auto,
  /// 语种分组顺序；auto 跟随全局
  entry-lang-order:          auto,
  /// 西文姓名格式：auto 跟随全局 / 八维字典（order / family-case / given-form / given-initial-separator / given-separator / given-case / family-given-separator / given-family-separator）
  name-style:         auto,
  /// 无责任者显示「佚名 / Anon」；auto 跟随全局
  show-anon:           auto,
  /// 截断后是否添加「等 / et al」；auto 跟随全局设置
  show-et-al:           auto,
  /// 析出文献编者与本条作者为同一人时去重省略；auto 跟随全局
  dedup-author-editor:      auto,
  /// 编号对齐："right" / "left" / "center"；auto 跟随全局
  number-align:        auto,
  /// 编号列宽；auto 跟随全局
  number-width:        auto,
  number-punct-width:  auto,
  /// 作者后句点；auto 跟随全局
  period-after-creator: auto,
  /// 双语关联条目第二行缩进：none 无
  related-indent:      none,
  /// 用 shortjournal 替代期刊名；auto 跟随全局
  short-journal:       auto,
  /// 显示文献类型标识；auto 跟随全局
  show-mark:           auto,
  /// 显示载体标识；auto 跟随全局
  show-medium:         auto,
  /// 出版地缺失时是否添加 [S.l.] 或「出版地不详」；auto 跟随全局设置
  show-sine-loco:      auto,
  /// 出版者缺失时是否添加 [s.n.] 或「出版者不详」；auto 跟随全局设置
  show-sine-nomine:    auto,
  show-sine-anno:      auto,
  /// 专利国显示；auto 跟随全局
  show-patent-country: auto,
  /// 多卷书卷号与分卷名之间的间距 gutter；auto 跟随全局
  volume-title-gutter: auto,
  /// 双语关联条目渲染；auto 跟随全局
  show-related:        auto,
  /// 显示 URL；auto 跟随全局
  show-url:            auto,
  /// 显示引用日期；auto 跟随全局
  show-urldate:        auto,
  /// 类型标识前空格；auto 跟随全局
  space-before-mark:   auto,
  /// 类型标识方括号半/全角（"half" / "full"）；auto 跟随全局
  mark-medium-bracket-style: auto,
  /// 页码前空格；auto 跟随全局
  space-before-pages:  auto,
  /// 注释前空格；auto 跟随全局
  space-before-annotation: auto,
  /// 编号反向跳转；auto 跟随全局
  back-ref:            auto,
  /// 学位级别注记；auto 跟随全局
  show-degree:         auto,
  /// 自定义条目模板；auto 跟随全局
  custom-drivers:    auto,
  /// 用户自定义本地化字面量 token；auto 跟随全局
  custom-terms:        auto,
  /// 用户自定义字段 token；auto 跟随全局
  custom-fields:       auto,
  /// 用户自定义永久标识符；auto 跟随全局
  custom-pids:         auto,
  /// 标点（同 punct-style）："half-with-space" / "half" / "full" / "by-doc-*" / "by-entry-*"；auto 跟随全局
  punct-style:         auto,
  /// PID 冒号风格（同 pid-colon-style）；auto 跟随全局
  pid-colon-style:     auto,
  /// 符号精确覆盖；auto 跟随全局
  custom-punct:     auto,
  /// URL 断点密度；auto 跟随全局
  url-break-every:     auto,
  /// URL 断点是否显示连字符；auto 跟随全局
  url-break-hyphen:    auto,
  /// 显连字符时 URL 分隔符断点算不算在内；auto 跟随全局
  url-break-hyphen-at-delimiters: auto,
  /// 永久标识符显示控制；auto 跟随全局
  show-pid:            auto,
  /// 永久标识符优先级；auto 跟随全局
  pid-priority:           auto,
  /// URL 与永久标识符去重；auto 跟随全局
  dedup-url-pid:       auto,
  /// 条目末尾追加注释字段；auto 跟随全局
  show-annotation:     auto,
) = context {
  import std: type as _std-type, version as _std-version, bibliography as _std-bibliography, cite as _std-cite
  import std: label as _std-label
  import "src/errors.typ": check-circled-dict as _check-circled-dict, check-enum as _check-enum, raise as _raise
  import "src/elements/creators.typ": validate-name-style as _validate-name-style
  import "src/parse/csl-json.typ": looks-like-json as _looks-like-json, to-bibtex as _json-to-bibtex, keys as _json-keys
  import "src/style.typ": normalize as _normalize-style
  import "src/elements/imprint/date.typ": validate-range-separator as _validate-date-range-separator
  import "src/api.typ": bib-keys as _bib-keys, gb7714 as _create-instance, _is-native-mode
  import sys: version as _typst-version
  if _std-type(bib-numbering-style) == dictionary {
    _check-circled-dict("bib-numbering-style", bib-numbering-style)
  } else { _check-enum("bib-numbering-style", bib-numbering-style, extra: (auto,)) }
  _check-enum("number-align", number-align, extra: (auto,))
  _check-enum("number-punct-width", number-punct-width, extra: (auto,))
  _check-enum("mark-medium-bracket-style", mark-medium-bracket-style, extra: (auto,))
  _validate-name-style(name-style)
  _validate-date-range-separator(date-range-separator)
  if _std-type(punct-style) != dictionary { _check-enum("bib-punct-style", punct-style, extra: (auto,), alias: "punct-style") }

  let to-bytes(s) = {
    if _std-type(s) == bytes { str(s) }
    else if _std-type(s) == str { s }
    else if _std-type(s) == array {
      let buffer = ""
      for it in s { buffer = buffer + to-bytes(it) }
      buffer
    } else {
      _raise("shell.bad-source-type")
    }
  }
  let bib-str = to-bytes(source)

  let _is-json = _looks-like-json(bib-str)
  let _native-bib-str = if _is-json { _json-to-bibtex(bib-str) } else { bib-str }
  {
    let s = bib-str.trim()
    if not s.contains("@") and not s.contains("\n") and s.len() < 256 and (
      s.ends-with(".bib") or s.ends-with(".bibtex") or s.ends-with(".yaml") or s.ends-with(".yml") or s.ends-with(".json") or s.ends-with(".toml")
    ) {
      _raise("shell.source-looks-like-path", path: s)
    }
  }

  let full = if full == auto { state("gb7714-config", (:)).get().at("full", default: false) } else { full }
  let sort-keys = if sort-keys == auto { state("gb7714-config", (:)).get().at("sort-keys", default: none) } else { sort-keys }

  let current-bib-index = state("gb7714-bib-seq", 0).at(here())

  let normalized-style = _normalize-style(style)
  let gb-style-cite = normalized-style.cite
  let gb-style-bib = normalized-style.bib
  let list-style-axes = (cite: gb-style-cite, bib: gb-style-bib)
  let gb-version = normalized-style.version

  let gb-footnote = if normalized-style.note == "foot" { true } else { auto }
  let is-native-style = normalized-style.native
  let footnote = if note == auto { auto } else { note != none }

  if gb-version != auto and version != auto and gb-version != version {
    _raise("shell.style-version-conflict", style-version: str(gb-version), version: str(version))
  }
  if gb-footnote == true and footnote == false {
    _raise("shell.style-footnote-conflict")
  }
  let eff-footnote = if footnote != auto { footnote } else { gb-footnote }
  let auto-key = if label != none { str(label) }
    else if current-bib-index == 0 { "main" }
    else { "bib" + str(current-bib-index + 1) }

  state("gb7714-sources", (:)).update(d => {
    let r = d
    let dup = false
    for (_, v) in r { if v == bib-str { dup = true; break } }
    if not dup { r.insert(auto-key, bib-str) }
    r
  })
  let _src-keys = if _is-json { _json-keys(bib-str) } else { _bib-keys(bib-str) }

  let _numeric-csl = ("american-chemical-society", "american-institute-of-aeronautics-and-astronautics", "american-institute-of-physics", "american-medical-association", "american-physics-society", "american-physiological-society", "american-society-for-microbiology", "american-society-of-mechanical-engineers", "angewandte-chemie", "annual-reviews", "association-for-computing-machinery", "biomed-central", "bmj", "british-medical-journal", "cell", "council-of-science-editors", "cse-citation-sequence-brackets-8th-edition", "current-opinion", "elsevier-vancouver", "elsevier-with-titles", "future-medicine", "future-science", "gb-7714-2005-numeric", "gb-7714-2015-numeric", "gost-r-705-2008-numeric", "ieee", "institute-of-electrical-and-electronics-engineers", "institute-of-physics-numeric", "iso-690-numeric", "karger", "mary-ann-liebert-vancouver", "multidisciplinary-digital-publishing-institute", "nature", "nlm-citation-sequence", "nlm-citation-sequence-superscript", "plos", "public-library-of-science", "royal-society-of-chemistry", "sage-vancouver", "sist02", "spie", "springer-basic", "springer-fachzeitschriften-medizin-psychologie", "springer-lecture-notes-in-computer-science", "springer-mathphys", "springer-vancouver", "taylor-and-francis-national-library-of-medicine", "the-institution-of-engineering-and-technology", "the-lancet", "thieme", "trends", "vancouver", "vancouver-superscript")
  let counts-number = if is-native-style {
    if _std-type(style) == str { style in _numeric-csl } else { true }
  } else if eff-footnote == true {
    false
  } else {
    let eff = if gb-style-cite != none { gb-style-cite } else { state("gb7714-config", (:)).get().at("style", default: (:)).at("cite", default: "numeric") }
    eff == "numeric"
  }
  let _list-date-range-separator = if date-range-separator == auto {
    state("gb7714-config", (:)).get().at("date-range-separator", default: auto)
  } else { date-range-separator }
  state("gb7714-bib-list", ()).update(array => {
    let r = array
    r.push((target: target, group: group, full: full, native-style: is-native-style, counts-number: counts-number, footnote: eff-footnote, source-keys: _src-keys, auto-key: auto-key, label: label,
      date-range-separator: _list-date-range-separator))
    r
  })
  if label == none and gb-style-cite != none and not is-native-style {
    state("gb7714-main-list-style", none).update(gb-style-cite)
  }

  let _norm-date = bib-src => bib-src.replace(
    regex("\\b(year|date)\\s*=\\s*\\{([^}]*)\\}"),
    m => {
      let v = m.captures.at(1)
      let digits = v.find(regex("\\d{4}"))
      if digits != none and v.trim().first() not in ("0","1","2","3","4","5","6","7","8","9") {
        m.captures.at(0) + " = {" + digits + "}"
      } else { m.text }
    },
  )
  let _sanitize = bib-src => _norm-date(bib-src).replace(regex("\\b\\w+\\s*=\\s*\\{\\s*\\}\\s*,?"), "")

  if _typst-version < _std-version(0, 15, 0) and (target != auto or group != auto) {
    _raise("shell.target-needs-015")
  }
  if is-native-style {

    state("gb7714-lsp-bib-active", false).update("visible")
    if _typst-version >= _std-version(0, 15, 0) {
      _std-bibliography(bytes(_sanitize(_native-bib-str)), title: title, full: full, style: style, target: target, group: group)
    } else {
      _std-bibliography(bytes(_sanitize(_native-bib-str)), title: title, full: full, style: style)
    }
    state("gb7714-lsp-bib-active", false).update(false)
  } else if _typst-version >= _std-version(0, 15, 0) {

    let g-style = state("gb7714-config", (:)).get().at("style", default: (:)).at("cite", default: "numeric")
    let eff-style = if gb-style-cite != none { gb-style-cite } else { g-style }
    let csl-style = if eff-style == "author-date" { "gb-7714-2015-author-date" } else { "gb-7714-2015-numeric" }

    state("gb7714-lsp-bib-active", false).update("render")
    _std-bibliography(bytes(_sanitize(_native-bib-str)), title: none, full: full, style: csl-style, target: target, group: group)
    state("gb7714-lsp-bib-active", false).update(false)
  } else {
    context {
      if state("gb7714-stdbib-emitted", false).get() {} else {
        state("gb7714-stdbib-emitted", false).update(true)
        let all = state("gb7714-sources", (:)).final()
        let combined = ""
        for (_, v) in all { combined = combined + (if _looks-like-json(v) { _json-to-bibtex(v) } else { v }) + "\n" }
        state("gb7714-lsp-bib-active", false).update(true)
        _std-bibliography(bytes(_sanitize(combined)), title: none)
        state("gb7714-lsp-bib-active", false).update(false)
      }
    }
  }

  let config = state("gb7714-config", (:)).get()
  if "cite-completion" in config { let _ = config.remove("cite-completion") }
  let single-source = (:)
  single-source.insert(auto-key, bib-str)
  let instance = if is-native-style { none } else { _create-instance(single-source, cite-completion: false, ..config) }

  let all-bibs-final = state("gb7714-bib-list", ()).final()
  let native-mode = _is-native-mode(all-bibs-final)
  let number-offset = 0
  let routed-keys = none
  let routed-empty = false
  if is-native-style {
  } else if native-mode {
    let timeline = query(selector(_std-cite).or(_std-bibliography))
    let cite-infos = ()
    let bibs-seen = 0
    for e in timeline {
      if e.func() == _std-bibliography { bibs-seen += 1 }
      else { cite-infos.push((key: str(e.key), loc: e.location(), before: bibs-seen)) }
    }
    let t-hits = all-bibs-final.map(b => {
      if b.target == auto { none } else { query(b.target) }
    })
    let per-bib = all-bibs-final.map(_ => ())
    for c in cite-infos {
      let routed = none
      for i in range(all-bibs-final.len()) {
        let target-hits = t-hits.at(i)
        if target-hits != none and target-hits.any(hit-cite => hit-cite.location() == c.loc) { routed = i; break }
      }
      if routed == none {
        for i in range(c.before, all-bibs-final.len()) {
          let b = all-bibs-final.at(i)
          if b.target == auto and c.key in b.source-keys { routed = i; break }
        }
      }
      if routed == none {
        let i = c.before - 1
        while i >= 0 {
          let b = all-bibs-final.at(i)
          if b.target == auto and c.key in b.source-keys { break }
          i -= 1
        }
        if i >= 0 { routed = i }
      }
      if routed != none {
        let array = per-bib.at(routed)
        if c.key not in array { array.push(c.key); per-bib.at(routed) = array }
      }
    }
    let _bib-count(j) = {
      let bib-at-index-j = all-bibs-final.at(j)
      if bib-at-index-j.full {
        let u = per-bib.at(j)
        for k in bib-at-index-j.source-keys { if k not in u { u.push(k) } }
        u.len()
      } else { per-bib.at(j).len() }
    }
    let mine = per-bib.at(current-bib-index)

    routed-empty = mine.len() == 0 and not full and keys == none
    if full {
      let current-entry = all-bibs-final.at(current-bib-index)
      for k in current-entry.source-keys { if k not in mine { mine.push(k) } }
    }
    routed-keys = mine
    let current-group = all-bibs-final.at(current-bib-index).group
    if current-group != none {
      for j in range(current-bib-index) {
        let bib-at-index-j = all-bibs-final.at(j)
        if bib-at-index-j.group == current-group and bib-at-index-j.at("counts-number", default: true) { number-offset += _bib-count(j) }
      }
    }
  } else if label == none {
    let cited = query(_std-cite).map(c => str(c.key))
    for previous-index in range(current-bib-index) {
      let previous-bib = all-bibs-final.at(previous-index)
      if previous-bib.label != none { continue }
      if not previous-bib.at("counts-number", default: true) { continue }
      let dedup = ()
      for k in cited { if k in previous-bib.source-keys and k not in dedup { dedup.push(k) } }
      number-offset += dedup.len()
    }
  }

  let effective-keys = if keys != none { keys }
    else if native-mode and routed-keys != none {
      let buffer = []
      for k in routed-keys { buffer = buffer + ref(_std-label(k)) }
      buffer
    }
    else { none }
  let title = if title == auto { state("gb7714-config", (:)).get().at("title", default: auto) } else { title }
  let eff-title = if title == auto {
    import "src/terms/built-in.typ": bib-title
    bib-title(text.lang, text.region)
  } else { title }

  let _bib-note = if note != auto { note }
    else if gb-footnote == true { "foot" }
    else if config.at("note", default: none) == "end" { "end" }
    else { auto }
  let common-args = (
    title: if _bib-note == "end" { title } else { eff-title },
    full: full,
    style: list-style-axes,
    target: target,
    group: group,
    version: if gb-version != auto { gb-version } else { version },
    note: _bib-note,
    entry-type: entry-type,
    filter: filter,
    keys: effective-keys,
    keyword: keyword,
    mark: mark,
    sort-keys: sort-keys,
    disambiguate: disambiguate, sort-by: sort-by, sort-zh-by: sort-zh-by, creator-idem: creator-idem,
    sort-use-prefix: sort-use-prefix,
    emphasis: emphasis,
    page-range-separator: page-range-separator,
    date-range-separator: date-range-separator,
    page-range-style: page-range-style,
    show-end-period: show-end-period,
    et-al-min: et-al-min,
    et-al-use-first: et-al-use-first,
    et-al-use-last: et-al-use-last,
    entry-hanging-indent: entry-hanging-indent, entry-first-line-indent: entry-first-line-indent, number-placement: number-placement, number-punct-width: number-punct-width,
    hyperlink: hyperlink,
    hyperlink-title: hyperlink-title,
    hyphenate: hyphenate,
    entry-localized-glyphs: entry-localized-glyphs,
    entry-spacing: entry-spacing,
    number-gutter: number-gutter,
    bib-numbering-style: bib-numbering-style,
    entry-lang-order: entry-lang-order,
    name-style: name-style,
    show-anon: show-anon,
    show-et-al: show-et-al,
    dedup-author-editor: dedup-author-editor,
    number-align: number-align,
    number-width: number-width,
    period-after-creator: period-after-creator,
    related-indent: related-indent,
    short-journal: short-journal,
    show-mark: show-mark,
    show-medium: show-medium,
    show-sine-loco: show-sine-loco, show-sine-nomine: show-sine-nomine, show-sine-anno: show-sine-anno,
    show-patent-country: show-patent-country, volume-title-gutter: volume-title-gutter,
    show-related: show-related,
    show-url: show-url,
    show-urldate: show-urldate,
    space-before-mark: space-before-mark,
    mark-medium-bracket-style: mark-medium-bracket-style,
    space-before-pages: space-before-pages,
    space-before-annotation: space-before-annotation,
    back-ref: back-ref,
    show-degree: show-degree,
    custom-drivers: custom-drivers,
    custom-terms: custom-terms,
    custom-fields: custom-fields,
    custom-pids: custom-pids,
    punct-style: punct-style,
    pid-colon-style: pid-colon-style,
    custom-punct: custom-punct,
    url-break-every: url-break-every,
    url-break-hyphen: url-break-hyphen,
    url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters,
    show-pid: show-pid,
    pid-priority: pid-priority,
    dedup-url-pid: dedup-url-pid,
    show-annotation: show-annotation,
  )

  if is-native-style {
  } else if _typst-version >= _std-version(0, 15, 0) {

    let payload = if native-mode and routed-empty {
      if eff-title != none { heading(level: 1, numbering: none, eff-title) } else { none }
    } else {
      let f = instance.print-bib

      let _nbi = if native-mode { current-bib-index } else { none }
      if label == none { f(bib-file: auto-key, number-offset: number-offset, native-bib-index: _nbi, ..common-args) }
      else { f(bib-file: auto-key, label: str(label), number-offset: number-offset, native-bib-index: _nbi, ..common-args) }
    }
    state("gb7714-render-payloads", ()).update(ps => ps + (payload,))
  } else {

    let f = instance.print-bib
    if label == none { f(bib-file: auto-key, number-offset: number-offset, ..common-args) }
    else { f(bib-file: auto-key, label: str(label), number-offset: number-offset, ..common-args) }
  }

  state("gb7714-bib-seq", 0).update(n => n + 1)
}

/// 手动引用，是 `@key` 原生语法的增强版：可一次合并多条、附加 `supplement` 页码或补充信息、
/// 可临时切换文献表（`bib-label`），或为单次引用覆盖样式、正文标注形式和标点；也可生成脚注式完整著录。
///
/// 位置参数可混写若干 `<label>` 与若干 content（content 内可含任意数量 `@key`），按顺序合并。
///
/// ```typ
/// #cite(<zhang2020>)                        // 单条，等价于 @zhang2020
/// #cite(<a>, <b>, <c>)                      // 合并为 [1-3]
/// #cite(<zhang2020>, supplement: [45-47])   // 带引文页码
/// #cite(<zhang2020>, form: "prose")         // 叙事式：张三（2020）
/// ```
#let cite(
  /// 位置参数：label（<key>）与 content（含 @key）任意混合，按出现顺序合并
  ..refs,
  /// 将本次引用归入指定的命名列表；auto 沿用当前 set-bib-label 作用域
  bib-label:       auto,
  /// 附加页码 / 补充说明：单 content 作用于首位引用；数组逐一对应
  supplement:      none,
  /// 本次引用样式："numeric" / "author-date"；auto 跟随列表或全局
  style:           auto,
  /// 正文标注形式：auto / "super" / "inline" / "normal" / "prose" / "author" / "year" / "full"（原位显示完整条目）/ none（单次覆盖 cite-form）
  form:            auto,
  /// 西文姓名格式：auto 跟随全局 / 八维字典（order / family-case / given-form / given-initial-separator / given-separator / given-case / family-given-separator / given-family-separator）
  name-style:     auto,
  /// 标注内部标点："by-doc-and-style"（默认） / "...-no-space" / "...-with-space" / "by-entry-*" / "half" / "half-with-space" / "full"；auto 跟随全局
  punct-style:     auto,
  /// supplement 显示格式："compact" / "split"；auto 跟随全局
  supplement-style:     auto,
  /// 是否与相邻引用合并为一组；auto 跟随全局 cite-merge
  merge:           auto,
  /// 注释模式："foot" 使用脚注，"end" 使用尾注，none 使用行内标注，auto 跟随全局设置
  note:            auto,
  /// 脚注模式下双语关联条目第二行缩进；auto 与首行首字对齐（实测注号前缀宽）
  footnote-related-indent:  auto,
  /// 自定义条目模板；仅 note: "foot" 时生效
  custom-drivers: auto,
  /// 用户自定义本地化字面量 token；仅 note: "foot" 时生效
  custom-terms:    auto,
  /// 用户自定义字段 token；仅 note: "foot" 时生效
  custom-fields:   auto,
  /// 用户自定义永久标识符；仅 note: "foot" 时生效
  custom-pids:     auto,
  /// 永久标识符显示控制；仅 note: "foot" 时生效
  show-pid:        auto,
  /// 永久标识符优先级；仅 note: "foot" 时生效
  pid-priority:       auto,
  /// URL 与永久标识符去重；仅 note: "foot" 时生效
  dedup-url-pid:   auto,
  /// 条目末尾追加注释字段；仅 note: "foot" 时生效
  show-annotation: auto,
  /// 「等 / et al」触发阈值（单次覆盖 cite-et-al-min；999 临时全列作者）
  et-al-min:       auto,
  /// 截断后保留前 N 位（单次覆盖 cite-et-al-use-first）
  et-al-use-first: auto,
  /// 截断后在省略号之后再保留末尾 N 位（单次覆盖 cite-et-al-use-last）
  et-al-use-last:  auto,
  /// 「等 / et al」截断词语言（单次覆盖 cite-terms-lang）：auto / "by-entry" / "zh"/"ja"/…
  terms-lang:      auto,
  /// ≥ N 个连续编号压缩为范围（单次覆盖 cite-compress-min）
  compress-min:    auto,
  /// 引文区间起讫号连接符（单次覆盖 cite-range-separator）
  range-separator: auto,
  /// 本次合并引用内的排序（单次覆盖 cite-sort-by）：auto / none 保持书写顺序 / 键数组（"name" / "date"）
  sort-by:         auto,
  /// 组内排序的中文排序方案（单次覆盖 cite-sort-zh-by）：auto / "pinyin" / "bihua"
  sort-zh-by:      auto,
  /// 本组年份折叠（单次覆盖 cite-collapse-date）：auto / true / false
  collapse-date:   auto,
  /// 脚注里 bib 条目的标点（同 punct-style）："half-with-space" / "half" / "full" / "by-doc-*" / "by-entry-*"；仅 note: "foot" 时生效
  footnote-punct-style:     auto,
  /// 脚注里符号精确覆盖；仅 note: "foot" 时生效
  footnote-custom-punct: auto,
  /// 脚注里 URL 断点密度；仅 note: "foot" 时生效
  footnote-url-break-every: auto,
) = context {
  import "src/api.typ" as _api
  import "src/errors.typ" as _errors
  import "src/style.typ" as _style
  import "src/elements/creators.typ" as _creators
  import "src/parse/csl-json.typ" as _csl-json
  _errors.check-enum("cite-form", form, extra: (auto,), alias: "form")
  _creators.validate-name-style(name-style)
  if std.type(punct-style) != dictionary { _errors.check-enum("punct-style", punct-style, extra: (auto,)) }
  _errors.check-enum("supplement-style", supplement-style, extra: (auto,))
  if std.type(footnote-punct-style) != dictionary { _errors.check-enum("punct-style", footnote-punct-style, extra: (auto,), alias: "footnote-punct-style") }
  _errors.check-enum("sort-zh-by", sort-zh-by, extra: (auto,))
  if sort-by != auto and sort-by != none {
    import "src/bibliography/sort.typ" as _sort
    let _ = _sort.normalize-sort-by(sort-by, keys: _sort.cite-sort-by-keys, param: "sort-by")
  }
  if collapse-date not in (auto, true, false) {
    _errors.raise("collapse-date.bad-value", param: "collapse-date", allowed: "auto / true / false", got: repr(collapse-date))
  }
  if refs.named().len() > 0 {
    _errors.raise("shell.cite-unexpected-argument", name: refs.named().keys().first())
  }
  let sources = state("gb7714-sources", (:)).final()
  if sources.len() == 0 {
    _errors.raise("shell.cite-before-init")
  }

  let _bibs = state("gb7714-bib-list", ()).final()
  let native-mode-flag = _api._is-native-mode(_bibs)
  if native-mode-flag and note == "foot" and _bibs.any(b => b.native-style) {
    _errors.raise("shell.cite-footnote-with-native")
  }

  let config = state("gb7714-config", (:)).at(here())
  if "cite-completion" in config { let _ = config.remove("cite-completion") }
  let instance = _api.gb7714(sources, cite-completion: false, ..config)
  let f = instance.cite
  f(
    ..refs.pos(),
    bib-label: bib-label,
    supplement: supplement,
    style: style,
    form: form,
    name-style: name-style,
    punct-style: punct-style,
    supplement-style: supplement-style,
    merge: merge,
    note: note,
    footnote-related-indent: footnote-related-indent,
    custom-drivers: custom-drivers,
    custom-terms: custom-terms,
    custom-fields: custom-fields,
    custom-pids: custom-pids,
    show-pid: show-pid,
    pid-priority: pid-priority,
    dedup-url-pid: dedup-url-pid,
    show-annotation: show-annotation,
    et-al-min: et-al-min,
    et-al-use-first: et-al-use-first,
    et-al-use-last: et-al-use-last,
    terms-lang: terms-lang,
    compress-min: compress-min,
    range-separator: range-separator,
    sort-by: sort-by,
    sort-zh-by: sort-zh-by,
    collapse-date: collapse-date,
    footnote-punct-style: footnote-punct-style,
    footnote-custom-punct: footnote-custom-punct,
    footnote-url-break-every: footnote-url-break-every,
  )
}

/// 把后续的 `@key` 与 `#cite()` 引用归属到指定的参考文献列表，配合
/// `#bibliography(.., label: "..")` 做多列表分区排版（如分章参考文献表）。
///
/// 传 `none` 恢复到主列表。可以在任何 `#bibliography(..)` 调用之前先设置。
///
/// ```typ
/// #set-bib-label("ch1")
/// 本章引用 @a @b
/// #bibliography(read("ch1.bib"), label: "ch1")
/// ```
#let set-bib-label(label) = {
  import "src/citation/aux-omni.typ": set-active-list
  set-active-list(label)
}

#let gb7714-frozen-states = (state("gb7714-bib-list", ()), state("gb7714-bib-seq", 0))
