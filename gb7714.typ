#import "@preview/citegeist:0.2.2": load-bibliography
#import "@preview/mitex:0.2.7": mi
#import "@preview/auto-pinyin:0.1.0" as _pinyin
#import "@preview/quan:0.1.0": quan as _quan-fn
#import "@preview/jurlstify:0.1.0": jurlstify as _jurlstify

// ============================================================
// 1. 文献类型标识映射
// ============================================================

#let _auto-type-mark = (
  article: "J",
  book: "M", mvbook: "M", inbook: "M", bookinbook: "M",
  inproceedings: "C", conference: "C",
  proceedings: "C", mvproceedings: "C",
  mastersthesis: "D", phdthesis: "D", thesis: "D",
  techreport: "R", report: "R",
  patent: "P",
  collection: "G", mvcollection: "G", incollection: "G",
  reference: "K", mvreference: "K", inreference: "K",
  online: "EB",
  software: "CP",
  dataset: "DS",
  manual: "A",
  periodical: "J",
  booklet: "M",
  unpublished: "Z", misc: "Z",
  suppbook: "Z", suppperiodical: "Z", suppcollection: "Z",
)

#let _subtype-mark = (newspaper: "N", news: "N", standard: "S")

#let _get-type-mark(entry) = {
  // usera 是 biblatex-gb7714-2015 (胡振震样式) 推荐的文献类型标识字段，优先级最高；
  // mark 仅作为非 biblatex 来源（自定义 / 部分工具导出）的回退。
  let usera = entry.fields.at("usera", default: none)
  if usera != none { return usera }
  let mark = entry.fields.at("mark", default: none)
  if mark != none { return mark }
  let subtype = entry.fields.at("entrysubtype", default: none)
  if subtype != none {
    let sub-mark = _subtype-mark.at(str(subtype), default: none)
    if sub-mark != none { return sub-mark }
  }
  // note = {standard} / {newspaper} / {news} 作为子类型标注
  let note = entry.fields.at("note", default: none)
  if note != none {
    let nt-mark = _subtype-mark.at(str(note).trim(), default: none)
    if nt-mark != none { return nt-mark }
  }
  _auto-type-mark.at(entry.entry_type, default: "Z")
}

// ============================================================
// 2. 载体标识
// ============================================================

/// 自动 OL 判定（与 biblatex-gb7714-2015 一致）：
///   show-url/show-doi 任一为 true：有 URL/DOI/eprint → 自动加 /OL
///   两者都为 false：仅 `@online` 类型或有 medium 字段时保留载体标识
#let _get-medium-mark(entry, show-url: true, show-doi: true) = {
  let medium = entry.fields.at("medium", default: none)
  if medium != none { return medium }
  let has-online = entry.fields.at("url", default: none) != none or entry.fields.at("doi", default: none) != none or entry.fields.at("eprint", default: none) != none
  if has-online {
    if show-url or show-doi { return "OL" }
    // 两者都关时，仅 @online 类型保留 /OL
    if entry.entry_type == "online" { return "OL" }
  }
  return none
}

#let _format-type-medium(entry, show-mark: true, show-medium: true, show-url: true, show-doi: true, space-before-mark: false) = {
  if not show-mark { return "" }
  let t = _get-type-mark(entry)
  if t == "" { return "" }  // mark={} 空字符串 → 完全隐藏标识
  let m = if show-medium { _get-medium-mark(entry, show-url: show-url, show-doi: show-doi) } else { none }
  let prefix = if space-before-mark { " " } else { "" }
  if m != none { prefix + "[" + t + "/" + m + "]" } else { prefix + "[" + t + "]" }
}

/// 将字符串中的 LaTeX 格式命令转换为 Typst content
/// 支持: \textbf{...} → strong, \textit{...}/\emph{...} → emph, \hspace{...} → h(...)
#let _latex-to-typst(s) = {
  if s == none { return none }
  let text = if type(s) == str { s } else { return s }  // 非字符串直接返回

  // 检查是否包含 LaTeX 命令，没有则直接返回（性能优化）
  if not text.contains("\\") and not text.contains("~") and not text.contains("$") {
    return text
  }

  // 兼容性强校验：字母命令（\quad/\qquad）在 LaTeX 里需空格或 {} 终止；紧贴字母 / CJK 字符会被拼进命令名。
  let _bad = text.match(regex("\\\\(qquad|quad)([a-zA-Z\u{4e00}-\u{9fff}\u{3040}-\u{309f}\u{30a0}-\u{30ff}\u{ac00}-\u{d7af}])"))
  if _bad != none {
    let cmd = _bad.captures.at(0)
    let follow = _bad.captures.at(1)
    panic("omni-gb7714: bib 字段含 LaTeX 非法写法 \\" + cmd + follow + "，请改为 \\" + cmd + " " + follow + " 或 \\" + cmd + "{}" + follow)
  }

  // 数学公式 $...$ → mitex 转换
  if text.contains("$") {
    let math-parts = ()
    let rest = text
    while rest.contains("$") {
      let start = rest.position("$")
      if start > 0 { math-parts.push(rest.slice(0, start)) }
      let after = rest.slice(start + 1)
      let end = after.position("$")
      if end == none { math-parts.push("$" + after); rest = ""; break }
      let formula = after.slice(0, end)
      math-parts.push(mi(formula))
      rest = after.slice(end + 1)
    }
    if rest.len() > 0 { math-parts.push(rest) }
    // 重组：对非数学部分继续处理 LaTeX 命令
    let result = []
    for p in math-parts {
      if type(p) == str { result += _latex-to-typst(p) } // 递归处理文本部分
      else { result += p } // 数学公式已是 content
    }
    return result
  }

  // LaTeX 规则：字母命令（\quad 等）以空格 / `{}` / 非字母字符终止，空格或 `{}` 不产生额外空白
  // 符号命令（\, \; 等）后的空格保留
  // 先处理显式 `{}` 终止：`\quad{}abc` → em-space + "abc"
  text = text.replace(regex("\\\\qquad\\s*\\{\\s*\\}"), "\u{2003}\u{2003}")
  text = text.replace(regex("\\\\quad\\s*\\{\\s*\\}"), "\u{2003}")
  // 再处理空格终止（兜底也吞掉紧贴的非法情形，配合上面的警告）
  text = text.replace(regex("\\\\qquad\\s?"), "\u{2003}\u{2003}") // 2em（先匹配长的）
  text = text.replace(regex("\\\\quad\\s?"), "\u{2003}")   // 1em
  text = text.replace(regex("\\\\,"), "\u{2009}")          // thin space (1/6 em)
  text = text.replace(regex("\\\\;"), "\u{2005}")          // medium space (4/18 em)
  text = text.replace("~", "\u{00A0}")                     // non-breaking space
  // \textbf{} \textit{} \emph{} 后的花括号已终止命令，空格保留（下面 regex 处理）

  // 用 regex 逐段处理
  let parts = ()
  let remaining = text

  while remaining.len() > 0 {
    // 匹配 \textbf{...}, \textit{...}, \emph{...}, \textsf{...}, \texttt{...}, \textsc{...}, \hspace{...}
    // 以及 {\itshape ...}, {\it ...}, {\bfseries ...}, {\bf ...}, {\sc ...}, {\tt ...}
    let m = remaining.match(regex("\\\\(textbf|textit|textsf|texttt|textsc|textsuperscript|textsubscript|emph|hspace)\{([^}]*)\}|\\{\\\\(itshape|it|bfseries|bf|sc|tt|sf)\\s+([^}]*)\\}"))
    if m == none {
      parts.push(remaining)
      break
    }
    // m.start 之前的普通文本
    if m.start > 0 {
      parts.push(remaining.slice(0, m.start))
    }
    // \command{arg} 形式：captures 0=cmd, 1=arg
    // {\switch arg} 形式：captures 2=switch, 3=arg
    let cmd = if m.captures.at(0) != none { m.captures.at(0) }
              else { m.captures.at(2) }
    let arg = if m.captures.at(1) != none { m.captures.at(1) }
              else { m.captures.at(3) }
    if cmd in ("textbf", "bfseries", "bf") {
      parts.push(strong(arg))
    } else if cmd in ("textit", "emph", "itshape", "it") {
      parts.push(emph(arg))
    } else if cmd in ("textsc", "sc") {
      parts.push(smallcaps(arg))
    } else if cmd in ("texttt", "tt") {
      parts.push(raw(arg))
    } else if cmd in ("textsf", "sf") {
      parts.push(text(font: "sans-serif", arg))
    } else if cmd == "textsuperscript" {
      parts.push(super(arg))
    } else if cmd == "textsubscript" {
      parts.push(sub(arg))
    } else if cmd == "hspace" {
      let len-match = arg.match(regex("([0-9.]+)(em|pt|cm|mm|in)"))
      if len-match != none {
        let val = float(len-match.captures.at(0))
        let unit = len-match.captures.at(1)
        let length = if unit == "em" { val * 1em }
          else if unit == "pt" { val * 1pt }
          else if unit == "cm" { val * 1cm }
          else if unit == "mm" { val * 1mm }
          else if unit == "in" { val * 1in }
          else { val * 1pt }
        parts.push(h(length))
      }
    }
    remaining = remaining.slice(m.end)
  }

  // 组合为 content
  if parts.len() == 1 and type(parts.first()) == str { return parts.first() }
  let result = []
  for p in parts {
    result += if type(p) == str { p } else { p }
  }
  result
}


// ============================================================
// 3. 格式类别判定
// ============================================================

/// 读取字段（原始值，不做 LaTeX 转换）
#let _f(entry, key) = entry.fields.at(key, default: none)

/// 读取文本展示字段并自动转换 LaTeX 命令（用于 title、booktitle、journal、note 等）
#let _ft(entry, key) = {
  let v = entry.fields.at(key, default: none)
  if v != none and type(v) == str { _latex-to-typst(v) } else { v }
}

#let _get-format-category(entry) = {
  let et = entry.entry_type
  let type-mark = _get-type-mark(entry)
  let analytic-types = ("inbook", "incollection", "inproceedings", "conference", "inreference", "suppbook", "suppcollection")
  if et in analytic-types { return "analytic" }
  // 已有专属渲染语义的类型即使带 booktitle 也不应被当作析出文献：
  //   D = thesis, P = patent, S = standard, N = newspaper, A = manual/archive
  // 这些类型的 booktitle 字段可能是用户写错或冗余信息，应一律忽略。
  let _has-dedicated-mark = type-mark in ("D", "P", "S", "N", "A")
  if not _has-dedicated-mark and _f(entry, "booktitle") != none {
    if et not in ("proceedings", "mvproceedings", "book", "collection", "mvbook", "mvcollection") { return "analytic" }
  }
  if type-mark == "N" { return "newspaper" }
  // arXiv 预印本：有 eprint/archiveprefix 字段，或 journal 含 "arxiv"
  if et == "article" {
    let eprint = _f(entry, "eprint")
    // biblatex 中 archiveprefix 是 eprinttype 的别名（real name 优先）
    let archive = _f(entry, "eprinttype")
    if archive == none { archive = _f(entry, "archiveprefix") }
    // biblatex 中 journal 是 journaltitle 的别名（real name 优先）
    let journal = _f(entry, "journaltitle")
    if journal == none { journal = _f(entry, "journal") }
    let is-arxiv = eprint != none and archive != none and lower(str(archive)).starts-with("arxiv")
    if not is-arxiv and journal != none {
      is-arxiv = lower(str(journal)).starts-with("arxiv")
    }
    if is-arxiv { return "preprint" }
    return "serial-article"
  }
  if et == "patent" or type-mark == "P" { return "patent" }
  if et == "online" { return "electronic" }
  if type-mark in ("EB", "DB", "CP", "DS") and _f(entry, "publisher") == none { return "electronic" }
  // 胡振震 sourcemap (gb7714-2015.bbx:1571-1661)：报告 / 学位论文 / 手册 / 档案等当 location 缺失且有网址时 → 转 online。
  // 简化：只判 location/address 缺失（与上游 sourcemap `\step[fieldsource=location,notmatch=\regexp{.}]` 等价语义）+ url/doi/eprint 任一存在。
  if type-mark in ("R", "D", "A") {
    let has-location = _f(entry, "location") != none or _f(entry, "address") != none
    let has-url = _f(entry, "url") != none or _f(entry, "doi") != none or _f(entry, "eprint") != none
    if not has-location and has-url { return "electronic" }
  }
  if et == "periodical" { return "serial" }
  return "monograph"
}

// ============================================================
// 4. 语言检测
// ============================================================

#let _is-cjk(s) = {
  for c in str(s) {
    let cp = str.to-unicode(c)
    if (cp >= 0x4E00 and cp <= 0x9FFF) or (cp >= 0x3400 and cp <= 0x4DBF) or (cp >= 0x3040 and cp <= 0x30FF) or (cp >= 0xAC00 and cp <= 0xD7AF) { return true }
  }
  false
}

/// 检测条目语言，返回语言代码
/// "zh" 中文 / "ja" 日文 / "ko" 韩文 / "ru" 俄文 / "en" 其他
#let _detect-lang(entry) = {
  // 优先 langid，其次 language
  let langid = _f(entry, "langid")
  if langid == none { langid = _f(entry, "language") }
  if langid != none {
    let l = lower(str(langid))
    // 支持三种写法：全称 (chinese)、ISO 639-1 (zh)、BCP 47 (zh-CN)
    if l == "chinese" or l.starts-with("zh") { return "zh" }
    if l == "japanese" or l.starts-with("ja") { return "ja" }
    if l == "korean" or l.starts-with("ko") { return "ko" }
    if l == "russian" or l.starts-with("ru") { return "ru" }
    if l in ("english", "american", "british") or l.starts-with("en") { return "en" }
    if l == "french" or l.starts-with("fr") { return "fr" }
  }
  // 自动检测：从作者和标题字符判断
  // 先收集所有文本，再按优先级检测（假名→谚文→西里尔→汉字）
  let check-text = ""
  let names = entry.parsed_names.at("author", default: ())
  if names.len() > 0 { check-text += names.first().at("family", default: "") }
  let title = _f(entry, "title")
  if title != none { check-text += str(title) }
  // 第一轮：检测假名/谚文/西里尔（优先于汉字，因为日文也用汉字）
  let has-cjk = false
  for c in check-text {
    let cp = str.to-unicode(c)
    if (cp >= 0x3040 and cp <= 0x309F) or (cp >= 0x30A0 and cp <= 0x30FF) { return "ja" }
    if (cp >= 0xAC00 and cp <= 0xD7AF) or (cp >= 0x1100 and cp <= 0x11FF) or (cp >= 0x3130 and cp <= 0x318F) { return "ko" }
    if cp >= 0x0400 and cp <= 0x04FF { return "ru" }
    if (cp >= 0x4E00 and cp <= 0x9FFF) or (cp >= 0x3400 and cp <= 0x4DBF) { has-cjk = true }
  }
  // 第二轮：只有汉字没有假名/谚文 → 中文
  if has-cjk { return "zh" }
  "en"
}

/// 兼容旧接口
#let _entry-is-cjk(entry) = {
  _detect-lang(entry) in ("zh", "ja", "ko")
}

// ============================================================
// 5. 姓名格式化
// ============================================================

#let _is-org-name(name) = {
  name.at("given", default: "") == "" and name.at("family", default: "").contains(" ")
}

// name-format 选项(对应 biblatex-gb7714-2015 gbnamefmt)：
//   "uppercase"   — FAMILY G        姓大写 + 名首字母（默认，符合 GB/T 7714-2015）
//   "lowercase"   — Family G        保留原始大小写 + 名首字母
//   "given-ahead" — G FAMILY        名首字母在前，姓大写
//   "fullname"    — FAMILY Given     姓大写 + 名全称
//   "pinyin"      — Yu-xin          连字符连接各拼音段
//   "quanpin"     — Yuxin           直接拼接，无分隔符
#let _format-one-name(name, uppercase: true, name-format: "uppercase") = {
  let family = name.at("family", default: "")
  let given = name.at("given", default: "")
  let prefix = name.at("prefix", default: "")
  let suffix = name.at("suffix", default: "")
  if family == "" and given == "" { return "" }
  if _is-org-name(name) { return family }
  if _is-cjk(family) or _is-cjk(given) { family + given }
  else {
    // 决定姓是否大写
    let do-upper = uppercase and name-format not in ("lowercase", "quanpin", "fullname")
    let fmt-family = if do-upper { upper(family) } else { family }
    let fmt-prefix = if prefix != "" {
      if do-upper { upper(prefix) + " " } else { prefix + " " }
    } else { "" }
    // 决定名的格式
    let fmt-given = if given != "" {
      if name-format == "pinyin" or name-format == "quanpin" {
        let pieces = given.split(regex("[ -]")).filter(p => p.len() > 0)
        let joined = pieces.enumerate().map(((i, p)) => {
          let cs = p.clusters()
          if cs.len() == 0 { "" }
          else if i == 0 { upper(cs.first()) + lower(cs.slice(1).join("")) }
          else { lower(p) }
        })
        if name-format == "pinyin" { joined.join("-") } else { joined.join("") }
      } else if name-format == "fullname" {
        given.split(regex("[ -]")).filter(p => p.len() > 0).map(p => {
          let cs = p.clusters()
          if cs.len() == 0 { "" }
          else { upper(cs.first()) + lower(cs.slice(1).join("")) }
        }).join("")
      } else {
        // uppercase / lowercase / given-ahead：首字母无点
        given.split(regex("[ -]")).map(g => {
          if g.len() > 0 { upper(g.first()) } else { "" }
        }).join(" ")
      }
    } else { "" }
    // 组合姓名
    let result = if name-format == "given-ahead" or name-format == "fullname" {
      // 名在前姓在后
      if fmt-given != "" { fmt-given + " " + fmt-prefix + fmt-family }
      else { fmt-prefix + fmt-family }
    } else {
      // 姓在前名在后（默认）
      let r = fmt-prefix + fmt-family
      if fmt-given != "" { r += " " + fmt-given }
      r
    }
    // 附加后缀 Jr. / Sr. 等（去掉尾部句点避免双句点）
    if suffix != "" { result += ", " + suffix.trim(".", at: end) }
    result
  }
}

#let _format-names(parsed-names, role: "author", entry: none, uppercase: true, et-al-min: 4, et-al-use-first: 3, no-others: false, name-format: "uppercase") = {
  let names = parsed-names.at(role, default: ())
  if names == () or names.len() == 0 { return none }
  // "and others" 处理：最后一个作者为 "others" 时强制截断
  let has-others = names.last().at("family", default: "") == "others" and names.last().at("given", default: "") == ""
  let real-names = if has-others { names.slice(0, -1) } else { names }
  let truncate = has-others or real-names.len() >= et-al-min
  let show-count = if truncate { calc.min(real-names.len(), et-al-use-first) } else { real-names.len() }
  let formatted = real-names.slice(0, show-count).map(n => _format-one-name(n, uppercase: uppercase, name-format: name-format))
  let result = formatted.join(", ")
  if truncate and not no-others {
    // 根据语言选择截断词
    let lang = if entry != none { _detect-lang(entry) } else { "en" }
    let etal = if lang == "zh" { ", 等" }
    else if lang == "ja" { ", 他" }
    else if lang == "ko" { ", 외" }
    else if lang == "ru" { ", и др" }
    else { ", et al" }
    result += etal
  }
  result
}

// ============================================================
// 6. 辅助函数
// ============================================================

#let _join-parts(parts, sep: ". ") = {
  let filtered = parts.filter(p => p != none and p != "" and p != [])
  let result = []
  for (i, p) in filtered.enumerate() {
    if i > 0 { result += sep }
    result += if type(p) == str { p } else { p }
  }
  result
}

// EDTF 不确定日期标记 → GB/T 7714 格式
// BibLaTeX: date={1936~}(circa) / {1976?}(uncertain) / {1723%}(both) → GB/T 7714: [1936]
// gbt7714: year={c1988} / {[1936]} / {1995印刷} → 直接原样输出
#let _edtf-year(s) = {
  if s.ends-with("~") or s.ends-with("?") or s.ends-with("%") {
    "[" + s.slice(0, -1) + "]"
  } else { s }
}
#let _format-year(entry) = {
  let d = _f(entry, "date"); let y = _f(entry, "year")
  if d != none { _edtf-year(str(d).split("-").first()) } else if y != none { str(y) } else { none }
}
#let _format-date(entry) = {
  let d = _f(entry, "date"); let y = _f(entry, "year")
  if d != none {
    let s = str(d)
    // EDTF 标记在整个日期末尾：1936-05-01~ → [1936-05-01]
    if s.ends-with("~") or s.ends-with("?") or s.ends-with("%") {
      "[" + s.slice(0, -1) + "]"
    } else { s }
  } else if y != none { str(y) } else { none }
}
#let _format-urldate(entry, show-urldate: true) = { if not show-urldate { return none }; let u = _f(entry, "urldate"); if u != none { "[" + str(u) + "]" } else { none } }
#let _format-pages(entry, dash-in-pages: "-") = { let p = _f(entry, "pages"); if p != none { str(p).replace("--", dash-in-pages).replace("\u{2013}", dash-in-pages).replace("-", dash-in-pages) } else { none } }

// useeditor / usetranslator 强制开启（与 biblatex 默认一致）：
//   author → editor → translator → 佚名占位（仅在 no-author 时）
// 顶替到作者位时直接用名字，不追加角色后缀（用户期望表现：替代后 bib / cite 都只显示替代字段本身）
#let _get-main-author(entry, uppercase: true, et-al-min: 4, et-al-use-first: 3, no-author: false, no-others: false, name-format: "uppercase") = {
  let a = _format-names(entry.parsed_names, role: "author", entry: entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  if a != none { return a }
  let e = _format-names(entry.parsed_names, role: "editor", entry: entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  if e != none { return e }
  let t = _format-names(entry.parsed_names, role: "translator", entry: entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  if t != none { return t }
  // @patent: 把 holder 当作 author 的别名（兜底回退）。
  // 设计取舍：胡振震样式严格区分 author（发明人）/ holder（专利权人），强制 author 必填、
  // 同时把 holder 渲染为尾部"专利权人：X"次要标注；本包认为这种双渲染收益不大，
  // 简化为"author 优先，缺失时 holder 顶替"，对 Zotero 等只导出 holder 的工作流也更友好。
  let h = _format-names(entry.parsed_names, role: "holder", entry: entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  if h != none { return h }
  // 著者-出版年制下，author/editor/translator 全无时插入本地化"佚名"（受 `no-author` 控制）
  if no-author {
    let lang = _detect-lang(entry)
    let anon-map = (
      zh: "佚名",
      ja: "著者不明",
      ko: "미상",
      fr: "Anon",
      ru: "Аноним",
    )
    anon-map.at(lang, default: "Anon")
  } else { none }
}

// 编者作为"其他责任者"渲染（专著中 author 与 editor 同时存在时使用）：
//   CJK 紧贴角色字 "X主编" / "X, 等主编"；西文沿用 ", ed" 模式。
#let _get-editor-as-other(entry, uppercase: true, et-al-min: 4, et-al-use-first: 3, no-others: false, name-format: "uppercase") = {
  let names = entry.parsed_names.at("editor", default: ())
  if names.len() == 0 { return none }
  let is-cjk = _entry-is-cjk(entry)
  let formatted = names.slice(0, calc.min(names.len(), et-al-use-first)).map(n => _format-one-name(n, uppercase: uppercase, name-format: name-format)).join(", ")
  let truncated = names.len() >= et-al-min
  if truncated and not no-others {
    if is-cjk { formatted + ", 等主编" } else { formatted + ", et al, ed" }
  } else {
    if is-cjk { formatted + "主编" } else { formatted + ", ed" }
  }
}

#let _get-translator(entry, uppercase: true, et-al-min: 4, et-al-use-first: 3, no-others: false, name-format: "uppercase") = {
  let names = entry.parsed_names.at("translator", default: ())
  if names.len() == 0 { return none }
  let is-cjk = _entry-is-cjk(entry)
  let formatted = names.slice(0, calc.min(names.len(), et-al-use-first)).map(n => _format-one-name(n, uppercase: uppercase, name-format: name-format)).join(", ")
  let truncated = names.len() >= et-al-min
  if truncated and not no-others {
    if is-cjk { formatted + ", 等, 译" } else { formatted + ", et al, trans" }
  } else {
    if is-cjk { formatted + ", 译" } else { formatted + ", trans" }
  }
}

#let _format-access(entry, show-url: true, show-doi: true, hyperlink: true, show-isbn: false, show-eprint: false) = {
  let parts = ()
  let url = _f(entry, "url"); let doi = _f(entry, "doi")
  if show-url and url != none {
    let u = _jurlstify(str(url))
    if hyperlink { parts.push(link(str(url), u)) } else { parts.push(u) }
  }
  if show-doi and doi != none {
    let d = _jurlstify(str(doi))
    if hyperlink { parts.push(link("https://doi.org/" + str(doi), [DOI:#d])) } else { parts.push([DOI:#d]) }
  }
  if show-eprint {
    let ep = _f(entry, "eprint")
    if ep != none { parts.push("eprint:" + str(ep)) }
  }
  if show-isbn {
    let isbn = _f(entry, "isbn")
    if isbn != none { parts.push("ISBN:" + str(isbn)) }
    let issn = _f(entry, "issn")
    if issn != none { parts.push("ISSN:" + str(issn)) }
  }
  if parts.len() > 0 { parts.join(". ") } else { none }
}

#let _get-publisher-name(entry) = {
  // 原则：biblatex 数据模型字段优先，其余按 bibtex 派 `gbt7714-numerical.bst:1820-1837` 的链路顺序补齐。
  // bibtex 派 format.publisher 链路：publisher > school > organization > institution。
  //
  // @periodical：biblatex 派 `gb7714-2015.bbx:3462-3491` 仅用 institution → 顶到最前；
  //              其余按 bibtex 顺序 publisher > school > organization。
  // type-mark = "A"（@manual / @archive 等"institution+location+date"路径）：
  //              biblatex-gb7714-2015 的 manual driver 用 institution，与 periodical 同种特化。
  // 其他条目类型（@book/@inbook 等）：biblatex 仅认 publisher，剩余字段照搬 bibtex 顺序。
  let _tm = _get-type-mark(entry)
  // type-mark "D"（thesis）与 "A"（manual / archive）共享 institution-first 链路：
  // 学位论文授予单位写在 institution / school；其行为与胡振震 manual driver 一致。
  let chain = if entry.entry_type == "periodical" or _tm in ("A", "D") {
    ("institution", "publisher", "school", "organization")
  } else {
    ("publisher", "school", "organization", "institution")
  }
  for field in chain {
    let v = _f(entry, field); if v != none { return v }
  }
  none
}

/// 判断条目渲染后是否以"缩写点"结尾（如 Inc./Ltd./Co.）
/// 用于避免在末尾追加句号时产生 ".."
/// 只识别单个点结尾（`Inc.`），省略号 `...` 或双点 `..` 不视为需要去重
#let _content-ends-with-abbrev-period(entry, skip-year: false, show-url: true, show-doi: true, show-isbn: false, show-eprint: false) = {
  // access 类字段（URL/DOI/ISBN/eprint）通常不以点结尾
  let has-access = ((show-url and _f(entry, "url") != none) or (show-doi and _f(entry, "doi") != none) or (show-isbn and _f(entry, "isbn") != none) or (show-eprint and _f(entry, "eprint") != none))
  if has-access { return false }
  // 有页码的（期刊/析出文献）页码不会以点结尾
  if _f(entry, "pages") != none {
    // 但 monograph/thesis 的出版项后面才是页码，pages 存在也可能在末尾
    // 简化：只要有 pages 就不是 publisher 结尾
    // 不适用于学位论文（格式是 publisher, year: pages）
  }
  // numeric 模式下 publisher 后接 ", 年份"，所以不是以缩写点结尾
  // 仅在 skip-year=true（著者-出版年制）且无 access 时，才可能是 publisher 结尾
  if not skip-year { return false }
  let pub = _get-publisher-name(entry)
  if pub != none {
    let p = str(pub).trim()
    if p.ends-with(".") and not p.ends-with("..") { return true }
  }
  false
}

// 识别用户手填的缺失占位符，视同空字段 ——
// 这样当 address/publisher 都是占位符时才能合并输出为 [S.l.: s.n.]
// 同时容忍带/不带方括号的所有常见大小写写法
#let _missing-placeholders = (
  "[S.l.]", "[s.l.]", "[S. l.]", "[S.L.]",
  "S.l.",   "s.l.",   "S. l.",   "S.L.",
  "[s.n.]", "[S.n.]", "[S.N.]",
  "s.n.",   "S.n.",   "S.N.",
  "[出版地不详]", "[出版者不详]",
  "出版地不详", "出版者不详",
  "[不详]", "不详",
)
#let _is-missing-placeholder(v) = {
  if v == none { return true }
  let s = str(v).trim()
  s == "" or s in _missing-placeholders
}

#let _format-publisher(entry, show-missing-pub: true, skip-year: false, use-full-date: false) = {
  // biblatex 中 address 是 location 的别名（real name 优先）
  let address = _f(entry, "location"); if address == none { address = _f(entry, "address") }
  let publisher = _get-publisher-name(entry)
  // 用户可能在 `bib` 里写了 `address = {[S.l.]}`/`publisher = {[s.n.]}` 作为占位符，
  // 归一化为 none，统一走下方"两者都缺 → [S.l.: s.n.]"合并分支
  if _is-missing-placeholder(address) { address = none }
  if _is-missing-placeholder(publisher) { publisher = none }
  // use-full-date：true 时使用完整日期（_format-date），适用于电子资源等可能精确到日的条目；
  //                false（默认）使用年份（_format-year），适用于书籍等以"出版年"为单位的条目
  let year = if skip-year { none }
    else if use-full-date { _format-date(entry) }
    else { _format-year(entry) }

  // 缺失出版地/出版者时的占位符（`show-missing-pub 控制是否显示）
  // 与 biblatex-gb7714-2015 (`gb7714-2015.bbx:1076-1078, 3462-3491, 3498-3526`) 一致：
  //   - book / inbook / incollection / proceedings / inproceedings / report / periodical → 走 publisher+location+date 宏，补占位符（即使带 URL 也照补，胡振震 book driver 不在 \pertype sourcemap 内）；
  //   - manual / archive / thesis 等"出版项缺失即省略"的类型（type-mark "A" / "D"）→ 走 institution+location+date 宏，不补；
  //   - standard（type-mark "S"）→ publisher+location+date 宏中专门 special-case 跳过（line 3502）；
  //   - online / dataset / software 等电子资源由 `_fmt-electronic` 显式传 `show-missing-pub: false` 跳过；R/D/A 在 `_get-format-category` 里通过 sourcemap 等价的路由转 electronic，亦不会到这里。
  let _type-mark = _get-type-mark(entry)
  let skip-placeholder-by-type = _type-mark in ("A", "D", "S")

  if show-missing-pub and not skip-placeholder-by-type {
    let is-cjk = _entry-is-cjk(entry)
    if address == none and publisher == none and year != none {
      // 两者都无：[S.l.: s.n.], 年
      let placeholder = if is-cjk { "[出版地不详: 出版者不详]" } else { "[S.l.: s.n.]" }
      return placeholder + ", " + year
    }
    if address == none and publisher != none {
      address = if is-cjk { "[出版地不详]" } else { "[S.l.]" }
    }
    if publisher == none and address != none {
      publisher = if is-cjk { "[出版者不详]" } else { "[s.n.]" }
    }
  }

  if address == none and publisher == none and year == none { return none }
  let pub-part = if address != none and publisher != none { address + ": " + publisher }
  else if publisher != none { publisher } else if address != none { address } else { none }
  if pub-part != none and year != none { pub-part + ", " + year }
  else if year != none { year } else { pub-part }
}

#let _format-edition(entry) = {
  // type-mark "R"（report）：版本项优先读 `version` 域（与 biblatex-gb7714-2015 report driver 一致：`\printfield{version}` 而非 `\printfield{edition}`），缺则回退 `edition`
  let _tm = _get-type-mark(entry)
  let edition = if _tm == "R" {
    let v = _f(entry, "version")
    if v != none { v } else { _f(entry, "edition") }
  } else { _f(entry, "edition") }
  if edition == none { return none }
  let ed = str(edition).trim()
  let m = ed.match(regex("^(\\d+)$"))
  if m != none {
    let n = int(m.captures.first()); if n <= 1 { return none }
    if _entry-is-cjk(entry) { str(n) + "版" } else {
      let s = if n == 2 { "nd" } else if n == 3 { "rd" } else { "th" }
      str(n) + s + " ed"
    }
  } else {
    if _entry-is-cjk(entry) { ed } else {
      if lower(ed).contains("ed") or lower(ed).contains("版") { ed } else { ed + " ed" }
    }
  }
}

#let _format-volume(entry) = {
  let v = _f(entry, "volume"); if v == none { return none }
  let cat = _get-format-category(entry)
  if cat in ("serial-article", "newspaper", "serial") { return none }
  if _entry-is-cjk(entry) { "第" + str(v) + "卷" } else { "vol. " + str(v) }
}

// ============================================================
// 7. LaTeX 命令转换 + 题名格式化
// ============================================================

// 按 biblatex 惯例追加 subtitle / titleaddon 到 title 后面：title: subtitle: titleaddon
// raw: 若为 true，直接用 _f 读取原始字符串（供自定义拼接）；否则走 _ft 做 LaTeX 转换
// subtitle-key / addon-key: 允许复用到 booktitle 场景，即 booktitle: booksubtitle: booktitleaddon
#let _append-title-addons(base, entry, raw: false, subtitle-key: "subtitle", addon-key: "titleaddon") = {
  if base == none { return none }
  let get = if raw { (e, k) => _f(e, k) } else { (e, k) => _ft(e, k) }
  let subtitle = get(entry, subtitle-key)
  let addon = get(entry, addon-key)
  let out = base
  if subtitle != none { out = [#out: #subtitle] }
  if addon != none { out = [#out: #addon] }
  out
}

#let _format-title-with-mark(entry, is-analytic: false, show-mark: true, show-medium: true, show-url: true, show-doi: true, space-before-mark: false, sentence-case-title: false, hyperlink-title: false) = {
  let title = _ft(entry, "title"); if title == none { return "" }
  title = _append-title-addons(title, entry)
  // hyperlink-title：标题文字链接到 URL 或 DOI
  if hyperlink-title {
    let url = _f(entry, "url"); let doi = _f(entry, "doi")
    let target = if url != none { str(url) }
    else if doi != none { "https://doi.org/" + str(doi) }
    else { none }
    if target != none { title = link(target, title) }
  }
  let mark = _format-type-medium(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark)
  let type-mark = _get-type-mark(entry)
  if is-analytic { title + mark }
  else if type-mark == "R" {
    // 胡振震 report driver (gb7714-2015.bbx:2745-2746)：[R] 之后接 type 与 number，仍位于 title cluster 内
    let tf = _ft(entry, "type")
    let number = _f(entry, "number")
    let suffix = ""
    if tf != none { suffix = suffix + ". " + str(tf) }
    if number != none { suffix = suffix + (if tf != none { " " + str(number) } else { ". " + str(number) }) }
    title + mark + suffix
  } else {
    let number = _f(entry, "number")
    if number != none and type-mark in ("S", "P") { title + ": " + str(number) + mark }
    else {
      let vol = _format-volume(entry)
      if vol != none { title + ": " + vol + mark } else { title + mark }
    }
  }
}

// ============================================================
// 8. 格式模板
// ============================================================

// 学位级别注记（show-degree 启用时使用）：
//   @mastersthesis 或 @thesis + type=mathesis  → 硕士级别
//   @phdthesis    或 @thesis + type=phdthesis → 博士级别
//   裸 @thesis（无 type 字段）→ 不输出，行为与 biblatex 标准 thesis driver 的 \printfield{type} 在缺 type 时一致
// 语言走 _detect-lang；中/英/日/韩/俄/法各自给本地化字符串，其他语言回退英文。
#let _format-degree(entry, show-degree: false) = {
  if not show-degree { return none }
  let et = entry.entry_type
  // 仅以下三种 entrytype 才考虑学位级别注记，其他类型（含 @report）即便写了 type=mathesis 也不输出。
  // - @phdthesis / @mastersthesis：entry_type 直接决定，忽略 type 字段；
  // - @thesis：因 entry_type 不区分学位级别，需依赖 type=mathesis / type=phdthesis 才能识别。
  let degree = if et == "mastersthesis" { "MA" }
    else if et == "phdthesis" { "PhD" }
    else if et == "thesis" {
      let tp = _f(entry, "type")
      let tp-str = if tp != none { str(tp) } else { "" }
      if tp-str == "mathesis" { "MA" }
      else if tp-str == "phdthesis" { "PhD" }
      else { return none }
    }
    else { return none }
  let lang = _detect-lang(entry)
  if degree == "MA" {
    if lang == "zh" { "硕士学位论文" }
    else if lang == "ja" { "修士論文" }
    else if lang == "ko" { "석사학위논문" }
    else if lang == "ru" { "магистерская диссертация" }
    else if lang == "fr" { "thèse de master" }
    else { "MA thesis" }
  } else {
    if lang == "zh" { "博士学位论文" }
    else if lang == "ja" { "博士論文" }
    else if lang == "ko" { "박사학위논문" }
    else if lang == "ru" { "докторская диссертация" }
    else if lang == "fr" { "thèse de doctorat" }
    else { "PhD thesis" }
  }
}

#let _fmt-monograph(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false, show-degree: false) = {
  // 检测 author 槽是否被 editor/translator 顶替；用于决定是否再把 editor/translator 渲染为"其他责任者"
  let raw-author = entry.parsed_names.at("author", default: ())
  let raw-editor = entry.parsed_names.at("editor", default: ())
  let has-real-author = raw-author.len() > 0
  // type-mark = "D"（thesis）走与胡振震 manual driver 一致的精简版：无 editor / translator / edition / series / italic 路径
  let _tm = _get-type-mark(entry)
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }
  let title = if italic-book-title and not _entry-is-cjk(entry) and _tm != "D" {
    // 斜体仅作用于标题文字，标识保持正体
    let t = _f(entry, "title")
    if t == none { t = "" }
    if sentence-case-title { t = _sentence-case(t) }
    t = _append-title-addons(t, entry, raw: true)
    let mark = _format-type-medium(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark)
    let type-mark = _get-type-mark(entry)
    let number = _f(entry, "number")
    let vol = _format-volume(entry)
    if type-mark == "R" {
      // 报告：[R] 之后输出 type + number（与 _format-title-with-mark 同步）
      let tf = _ft(entry, "type")
      let suffix = ""
      if tf != none { suffix = suffix + ". " + str(tf) }
      if number != none { suffix = suffix + (if tf != none { " " + str(number) } else { ". " + str(number) }) }
      [#emph[#t]#mark#suffix]
    } else {
      let title-text = if number != none and type-mark in ("S", "P") { t + ": " + str(number) }
      else if vol != none { t + ": " + vol }
      else { t }
      [#emph[#title-text]#mark]
    }
  } else {
    _format-title-with-mark(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark, sentence-case-title: sentence-case-title, hyperlink-title: hyperlink-title)
  }
  // 编者作为"其他责任者"：仅在真有 author 时渲染（否则编者已顶替到作者位）
  // no-same-editor：editor 与 author 是同一组人时省略
  // type-mark "D"：thesis 不渲染 editor-other（biblatex thesis driver 复用 manual，不调用 byeditor 宏链）
  let editor-other = if _tm != "D" and has-real-author and not (no-same-editor and raw-author == raw-editor) {
    _get-editor-as-other(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  } else { none }
  // 译者作为"其他责任者"：当 author 真有，或者 editor 顶替了 author（此时译者还未上场）才渲染；
  // 若 author 缺、editor 也缺，translator 已经顶替到作者位，不再重复
  // type-mark "D"：thesis 也不输出 translator
  let translator = if _tm != "D" and (has-real-author or raw-editor.len() > 0) {
    _get-translator(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  } else { none }
  // type-mark "D"：thesis 不输出版本项
  let edition = if _tm != "D" { _format-edition(entry) } else { none }
  let publisher = _format-publisher(entry, show-missing-pub: show-missing-pub, skip-year: skip-year)
  let pages = _format-pages(entry, dash-in-pages: dash-in-pages)
  let urldate = _format-urldate(entry, show-urldate: show-urldate)
  let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)
  let pp = if publisher != none and pages != none { publisher + ":" + (if space-before-pages { " " } else { "" }) + pages } else { publisher }
  if pp != none and urldate != none { pp = pp + urldate }
  // 丛书项（biblatex / bibtex 都用同一字段名 `series`）：
  //   - 单独有 series → "(系列名)"
  //   - 同时有 series 与 number 且 number 未被类型标识吃掉 → "(系列名, 卷号)"
  //   biblatex 标准驱动 series+number 宏渲染位置在 publisher-pages 之后；GB/T 7714 以括号丛书项收尾，二者一致。
  let series-part = {
    let series = _ft(entry, "series")
    let type-mark = _get-type-mark(entry)
    // 标准文献（S）/ 学位论文（D）/ 报告（R）/ 专利（P）/ 报纸（N）/ 期刊（J）等不输出丛书项：
    //   - S / D：GB/T 7714 标准与胡振震 driver 都不含丛书项；
    //   - R：胡振震 report driver (gb7714-2015.bbx:4237-4280) 不引用 series；
    //   - P / N / J：number 已被类型标识或卷期占用，对应 driver 也不渲染 series。
    if series == none or type-mark in ("S", "D", "R", "P", "N", "J") { none } else {
      let series-num = _f(entry, "number")
      if series-num != none {
        "(" + series + ", " + str(series-num) + ")"
      } else {
        "(" + series + ")"
      }
    }
  }
  // 学位级别注记：仅 type-mark "D" 进入 _format-degree；其他类型 degree-anno=none 自动被 _join-parts 过滤
  let degree-anno = _format-degree(entry, show-degree: show-degree)
  _join-parts((author, title, degree-anno, editor-other, translator, edition, pp, series-part, access))
}

#let _fmt-analytic(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false) = {
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }
  let title = _format-title-with-mark(entry, is-analytic: true, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark, sentence-case-title: sentence-case-title, hyperlink-title: hyperlink-title)
  let translator = _get-translator(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  // 专著主要责任者（`//` 之后那位）：bookauthor 优先（biblatex 风格），缺失则回退 editor（兼容 bibtex/李泽平样式）
  // 对应 biblatex-gb7714-2015 gb7714-2015.bbx:3822-3834 macro `bybookauthor`
  let bookauthor = _format-names(entry.parsed_names, role: "bookauthor", entry: entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  let editor = _format-names(entry.parsed_names, role: "editor", entry: entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  let book-resp = if bookauthor != none { bookauthor } else { editor }
  // `no-same-editor`：析出文献作者与专著主要责任者相同时省略
  if no-same-editor and book-resp != none and author != none and book-resp == author { book-resp = none }
  let booktitle = _ft(entry, "booktitle")
  // booktitle 也追加 booksubtitle / booktitleaddon，优先级同 title（先 subtitle 后 addon）
  booktitle = _append-title-addons(booktitle, entry, subtitle-key: "booksubtitle", addon-key: "booktitleaddon")
  let number = _f(entry, "number"); let type-mark = _get-type-mark(entry)
  let edition = _format-edition(entry)
  let publisher = _format-publisher(entry, show-missing-pub: show-missing-pub, skip-year: skip-year)
  let pages = _format-pages(entry, dash-in-pages: dash-in-pages); let urldate = _format-urldate(entry, show-urldate: show-urldate)
  let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)
  let ct = booktitle
  if ct != none and number != none and type-mark in ("S", "R") { ct = ct + ": " + str(number) }
  let container = ""
  if book-resp != none { container += book-resp + ". " }
  if ct != none { container += ct }
  let tp = if translator != none { title + ". " + translator } else { title }
  let tc = if container != "" { tp + "//" + container } else { tp }
  let pp = if publisher != none and pages != none { publisher + ":" + (if space-before-pages { " " } else { "" }) + pages }
  else if publisher != none { publisher }
  else if pages != none { let y = if skip-year { none } else { _format-year(entry) }; if y != none { y + ": " + pages } else { pages } }
  else { none }
  if pp != none and urldate != none { pp = pp + urldate }
  // 丛书项：仅当 number 未被类型标识 / 析出 booktitle 占用时（type-mark 不在 S/R 且 booktitle 没拼接 number）才一并输出
  let series-part = {
    let series = _ft(entry, "series")
    if series == none { none } else {
      let series-num = _f(entry, "number")
      let consumed-by-ct = series-num != none and type-mark in ("S", "R")
      if series-num != none and not consumed-by-ct and type-mark not in ("P", "J", "N") {
        "(" + series + ", " + str(series-num) + ")"
      } else {
        "(" + series + ")"
      }
    }
  }
  _join-parts((author, tc, edition, pp, series-part, access))
}

#let _fmt-serial-article(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false) = {
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }
  let title = _format-title-with-mark(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark, sentence-case-title: sentence-case-title, hyperlink-title: hyperlink-title)
  let journal = if short-journal { _ft(entry, "shortjournal") } else { none }
  let _used-short = journal != none
  // biblatex 中 journal 是 journaltitle 的别名（real name 优先）
  if journal == none { journal = _ft(entry, "journaltitle") }
  if journal == none { journal = _ft(entry, "journal") }
  // 长刊名才追加 journalsubtitle / journaltitleaddon；shortjournal 模式下保持紧凑
  if not _used-short {
    journal = _append-title-addons(journal, entry, subtitle-key: "journalsubtitle", addon-key: "journaltitleaddon")
  }
  let year = if skip-year { none } else { _format-year(entry) }; let volume = _f(entry, "volume")
  let number = _f(entry, "number"); let pages = _format-pages(entry, dash-in-pages: dash-in-pages)
  let urldate = _format-urldate(entry, show-urldate: show-urldate); let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)
  let src = []
  if journal != none {
    src += if italic-journal { emph(journal) } else { journal }
  }
  if year != none { src += [, #year] }
  if volume != none {
    let v = str(volume)
    src += if bold-journal-volume { [, *#v*] } else { [, #v] }
  }
  if number != none { src += "(" + str(number) + ")" }
  if pages != none {
    let sep = ":" + (if space-before-pages { " " } else { "" })
    src += sep + pages
  }
  if urldate != none { src += urldate }
  _join-parts((author, title, src, access))
}

#let _fmt-newspaper(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false) = {
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }
  let title = _format-title-with-mark(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark, sentence-case-title: sentence-case-title, hyperlink-title: hyperlink-title)
  // biblatex 中 journal 是 journaltitle 的别名（real name 优先）
  let journal = _ft(entry, "journaltitle"); if journal == none { journal = _ft(entry, "journal") }
  journal = _append-title-addons(journal, entry, subtitle-key: "journalsubtitle", addon-key: "journaltitleaddon")
  let date = if skip-year { none } else { _format-date(entry) }
  // 报纸中 pages 作为 number 的下位别名（用户用 pages 录版次时也能正常输出）
  let number = _f(entry, "number"); if number == none { number = _f(entry, "pages") }
  let urldate = _format-urldate(entry, show-urldate: show-urldate)
  let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)
  let src = []
  if journal != none {
    src += if italic-journal { emph(journal) } else { journal }
  }
  if date != none { src += ", " + date }
  if number != none { src += "(" + str(number) + ")" }
  if urldate != none { src += urldate }
  _join-parts((author, title, src, access))
}

#let _fmt-patent(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false) = {
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }

  // 专利题名：题名: [国家,]专利号[P]
  let title-text = _f(entry, "title")
  if title-text == none { title-text = "" }
  title-text = _append-title-addons(title-text, entry, raw: true)
  let mark = _format-type-medium(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark)
  let number = _f(entry, "number")
  let country = if show-patent-country {
    // biblatex 中 address 是 location 的别名（real name 优先）
    let addr = _f(entry, "location")
    if addr == none { addr = _f(entry, "address") }
    addr
  } else { none }
  let title = if number != none {
    let num-part = if country != none { str(country) + ", " + str(number) } else { str(number) }
    title-text + ": " + num-part + mark
  } else { title-text + mark }

  let date = if skip-year { none } else { _format-date(entry) }; let urldate = _format-urldate(entry, show-urldate: show-urldate)
  let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)
  let dp = ""; if date != none { dp += date }; if urldate != none { dp += urldate }
  if dp == "" { dp = none }
  _join-parts((author, title, dp, access))
}

#let _fmt-electronic(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false) = {
  let raw-author = entry.parsed_names.at("author", default: ())
  let raw-editor = entry.parsed_names.at("editor", default: ())
  let has-real-author = raw-author.len() > 0
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }
  let title = _format-title-with-mark(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark, sentence-case-title: sentence-case-title, hyperlink-title: hyperlink-title)
  // 译者 / 编者作为"其他责任者"：报告 / 学位论文等被 sourcemap 转 online 的条目不应丢这层信息
  // type-mark "D"（thesis）依胡振震 manual driver 习惯不输出
  let _tm = _get-type-mark(entry)
  let editor-other = if _tm != "D" and has-real-author and not (no-same-editor and raw-author == raw-editor) {
    _get-editor-as-other(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  } else { none }
  let translator = if _tm != "D" and (has-real-author or raw-editor.len() > 0) {
    _get-translator(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-others: no-others, name-format: name-format)
  } else { none }

  // 电子资源里 year / date 不再互为别名：
  //   year → 出版年（仅年份，str 直接输出）
  //   date → 更新或修改日期（完整日期，参与 EDTF 标记处理）
  let pub-year = if skip-year { none } else {
    let y = _f(entry, "year")
    if y != none { str(y) } else { none }
  }
  let modify-date = if skip-year { none } else {
    let d = _f(entry, "date")
    if d != none {
      let s = str(d)
      if s.ends-with("~") or s.ends-with("?") or s.ends-with("%") {
        "[" + s.slice(0, -1) + "]"
      } else { s }
    } else { none }
  }

  let pages = _format-pages(entry, dash-in-pages: dash-in-pages)
  let urldate = _format-urldate(entry, show-urldate: show-urldate)
  let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)

  // 含 year（出版年）也算"出版信息"，避免年份单独出现时落到无 publisher 分支
  let has-real-publisher = _get-publisher-name(entry) != none or _f(entry, "address") != none or _f(entry, "location") != none or _f(entry, "year") != none

  if has-real-publisher {
    // 出版地: 出版者, 出版年: 引文页码 (更新或修改日期)[引用日期]
    let address = _f(entry, "location"); if address == none { address = _f(entry, "address") }
    let publisher = _get-publisher-name(entry)
    if _is-missing-placeholder(address) { address = none }
    if _is-missing-placeholder(publisher) { publisher = none }
    let pub-part = if address != none and publisher != none { address + ": " + publisher }
      else if publisher != none { publisher }
      else if address != none { address }
      else { none }
    let yp = ""
    if pub-year != none {
      yp += ", " + pub-year
      if pages != none { yp += ":" + (if space-before-pages { " " } else { "" }) + pages }
    } else if pages != none {
      // 只有 pages 没有 year（少见）：直接附在 publisher 后
      yp += ", " + pages
    }
    if modify-date != none { yp += "(" + modify-date + ")" }
    if urldate != none { yp += urldate }
    let pp = if pub-part != none { pub-part + yp }
      else if yp != "" { yp.trim(", ", at: start) }
      else { none }
    _join-parts((author, title, editor-other, translator, pp, access))
  } else {
    // 纯电子资源（无 publisher）：年份 / 修改日期 / 引用日期组合
    let dp = ""
    if pub-year != none { dp += pub-year }
    if modify-date != none { dp += "(" + modify-date + ")" }
    if pages != none { dp += ": " + pages }  // 极罕见，但允许
    if urldate != none { dp += urldate }
    if dp == "" { dp = none }
    _join-parts((author, title, editor-other, translator, dp, access))
  }
}

// --- 预印本（arXiv 等）---
// 格式：责任者. 题名[A]. arXiv:XXXX, 年.
#let _fmt-preprint(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false) = {
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }

  // 题名：强制标识为 [A/OL]（现在的预印本都是在线的，简化一下逻辑）
  let title = _f(entry, "title")
  if title == none { title = "" }
  title = _append-title-addons(title, entry, raw: true)
  let medium = if _f(entry, "url") != none or _f(entry, "doi") != none or _f(entry, "eprint") != none { "OL" } else { none }
  let mark = if not show-mark { "" }
  else if medium != none and show-medium { "[A/" + medium + "]" }
  else { "[A]" }
  let title-mark = title + mark

  // arXiv 编号
  let eprint = _f(entry, "eprint")
  // biblatex 中 archiveprefix / journal 分别是 eprinttype / journaltitle 的别名（real name 优先）
  let archive = _f(entry, "eprinttype")
  if archive == none { archive = _f(entry, "archiveprefix") }
  let journal = _f(entry, "journaltitle")
  if journal == none { journal = _f(entry, "journal") }

  let arxiv-id = if eprint != none {
    let prefix = if archive != none { str(archive) } else { "arXiv" }
    prefix + ":" + str(eprint)
  } else if journal != none and lower(str(journal)).starts-with("arxiv") {
    // 从 `journal` 字段提取 arXiv ID
    let j = str(journal)
    // 匹配 "arXiv preprint arXiv:XXXX" 或 "arXiv:XXXX"
    let m = j.match(regex("(?i)arxiv[: ]*(?:preprint[: ]*)?(?:arxiv[: ]*)?(.+)"))
    if m != none { "arXiv:" + m.captures.first().trim() } else { j }
  } else { none }

  let year = if skip-year { none } else { _format-year(entry) }
  // biblatex 中 address 是 location 的别名（real name 优先）
  let address = _f(entry, "location")
  if address == none { address = _f(entry, "address") }
  let publisher = _get-publisher-name(entry)
  if publisher == none { publisher = _f(entry, "institution") }
  if publisher == none { publisher = _f(entry, "organization") }
  let pages = _format-pages(entry, dash-in-pages: dash-in-pages)
  let urldate = _format-urldate(entry, show-urldate: show-urldate)
  let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)

  let source = arxiv-id
  let pp = ""
  if address != none { pp += address + ": " }
  if publisher != none { pp += publisher }
  if year != none {
    if pp != "" { pp += ", " }
    pp += year
  }
  if pages != none {
    let sep = ":" + (if space-before-pages { " " } else { "" })
    if pp != "" { pp += sep + pages } else { pp = pages }
  }
  if urldate != none { pp += urldate }
  if pp == "" { pp = none }

  _join-parts((author, title-mark, source, pp, access))
}

// --- 4.3 连续出版物 ---
// 持续中：责任者. 题名[J]. 年, 卷(期)-. 出版地: 出版者, 起始年-.
// 已停刊：责任者. 题名[J]. 起始年, 卷(期)-终止年, 卷(期). 出版地: 出版者, 起始年-终止年.
#let _fmt-serial(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false) = {
  let author = if skip-author { none } else { _get-main-author(entry, uppercase: uppercase, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format) }
  let title = _format-title-with-mark(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, show-doi: show-doi, space-before-mark: space-before-mark, sentence-case-title: sentence-case-title, hyperlink-title: hyperlink-title)
  let volume = _f(entry, "volume")
  let number = _f(entry, "number")
  // biblatex 中 address 是 location 的别名（real name 优先）
  let address = _f(entry, "location")
  if address == none { address = _f(entry, "address") }
  let publisher = _get-publisher-name(entry)
  let urldate = _format-urldate(entry, show-urldate: show-urldate)
  let access = _format-access(entry, show-url: show-url, show-doi: show-doi, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint)

  // 解析年份：可能是 "1957" 或 "1957/1990"
  // biblatex 中 year 是 date 的旧版别名（real name 优先）
  let raw-year = if skip-year { none } else { _f(entry, "date") }
  if raw-year == none and not skip-year { raw-year = _f(entry, "year") }
  let start-year = none
  let end-year = none
  if raw-year != none {
    let yr = str(raw-year)
    if yr.contains("/") {
      let parts = yr.split("/")
      start-year = parts.first().trim()
      end-year = parts.last().trim()
    } else {
      start-year = yr.split("-").first() // 处理 date 格式 YYYY-MM-DD
    }
  }

  // 解析卷期范围：可能是 "1" 或 "1-15"
  let start-vol = none
  let end-vol = none
  if volume != none {
    let vs = str(volume)
    if vs.contains("-") {
      let ps = vs.split("-")
      start-vol = ps.first().trim()
      end-vol = ps.last().trim()
    } else { start-vol = vs }
  }
  let start-num = none
  let end-num = none
  if number != none {
    let ns = str(number)
    if ns.contains("-") {
      let ps = ns.split("-")
      start-num = ps.first().trim()
      end-num = ps.last().trim()
    } else { start-num = ns }
  }

  // 构建年卷期部分
  // 起始部分：起始年, 起始卷(起始期)
  let yvi-start = ""
  if start-year != none { yvi-start += start-year }
  if start-vol != none { yvi-start += ", " + start-vol }
  if start-num != none { yvi-start += "(" + start-num + ")" }

  let yvi = yvi-start

  if end-year != none {
    // 已停刊：起始年, 起始卷(起始期)-终止年, 终止卷(终止期)
    let yvi-end = end-year
    if end-vol != none { yvi-end += ", " + end-vol }
    if end-num != none { yvi-end += "(" + end-num + ")" }
    yvi += "-" + yvi-end
  } else {
    // 持续中：年, 卷(期)-
    yvi += "-"
  }

  // 出版项
  let pub-part = none
  if address != none and publisher != none { pub-part = address + ": " + publisher }
  else if publisher != none { pub-part = publisher }
  else if address != none { pub-part = address }

  // 组合
  let parts = (author, title)
  if yvi != "" { parts.push(yvi) }
  if pub-part != none {
    // 出版年范围
    let pub-year = if start-year != none and end-year != none {
      start-year + "-" + end-year
    } else if start-year != none {
      start-year + "-"
    } else { none }
    if pub-year != none { parts.push(pub-part + ", " + pub-year) }
    else { parts.push(pub-part) }
  }
  if urldate != none { parts.push(urldate) }
  if access != none { parts.push(access) }

  _join-parts(parts)
}

#let _format-entry(entry, uppercase: true, show-missing-pub: true, et-al-min: 4, et-al-use-first: 3, show-url: true, show-doi: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, show-isbn: false, show-eprint: false, sentence-case-title: false, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, dash-in-pages: "-", period-after-author: true, number-width: auto, number-align: "right", after-number-sep: 0.5em, item-sep: auto, hanging: true, show-related: true, title: auto, no-author: false, no-others: false, name-format: "uppercase", hyperlink-title: false, no-same-editor: false, skip-year: false, skip-author: false, show-degree: false) = {
  let cat = _get-format-category(entry)
  if cat == "analytic" { _fmt-analytic(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author) }
  else if cat == "preprint" { _fmt-preprint(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author) }
  else if cat == "serial-article" { _fmt-serial-article(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author) }
  else if cat == "newspaper" { _fmt-newspaper(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author) }
  else if cat == "patent" { _fmt-patent(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author) }
  else if cat == "electronic" { _fmt-electronic(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author) }
  else if cat == "serial" { _fmt-serial(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author) }
  else { _fmt-monograph(entry, uppercase: uppercase, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, skip-author: skip-author, show-degree: show-degree) }
}

// ============================================================
// 排序辅助函数
// ============================================================

/// 语言排序权重（6组）
/// lang-order: 语言顺序，如 ("zh", "ja", "ko", "en", "fr", "ru")（默认中文在前）
#let _lang-sort-key(entry, lang-order: ("zh", "ja", "ko", "en", "fr", "ru")) = {
  let lang = _detect-lang(entry)
  let idx = lang-order.position(l => l == lang)
  if idx != none { str(idx + 1) } else { str(lang-order.len() + 1) }
}

/// 规范化排序键：去除非字母数字字符并小写。
/// 与 bibtex 的 `purify$` + `change.case$ "l"` 对齐 ——
///   "Ma3 Ke4 Si1 & En1 Ge2 Si1"  →  "ma3ke4si1en1ge2si1"
/// 保留音调数字（1–5），用户手写 sortkey 时可标注多音字的具体读音。
#let _normalize-sort-key(s) = {
  lower(str(s)).replace(regex("[^a-z0-9]"), "")
}

/// 把字符串转成拼音排序键（中文字符转拼音，其他字符保留）
/// 使用 auto-pinyin 的 "tone-num-end" 风格（音调数字置于音节末，如 "han4"）
/// —— 用户手写 sortkey 的 "ma3 ke4 si1" 与自动派生的 "ma3ke4si1" 音调一致，
///   排序结果可比，并且对多音字可通过 sortkey 手动区分。
#let _to-pinyin-key(s) = {
  if s == none or s == "" { return "" }
  let text = str(s)
  let parts = _pinyin.to-pinyin(text, style: "tone-num-end")
  _normalize-sort-key(parts.join(""))
}

/// 排序用的作者名
/// 优先级（与 biblatex/bibtex 一致）：
///   1. sortkey 字段（biblatex 标准字段，用户手写）
///   2. key 字段（BibTeX/gbt7714 惯例）
///   3. 作者姓名 → 编者 → 题名（中文自动转拼音，含音调数字）
/// sortkey / key 均按 bibtex `purify$` 去掉非字母数字字符，支持音调后缀：
///   `sortkey = {ma3 ke4 si1 & en1 ge2 si1}` → `ma3ke4si1en1ge2si1`
///   `sortkey = {zhang san}`                 → `zhangsan`
/// 多音字可通过 sortkey 明确指定读音，如 `重庆 → "chong2 qing4"`。
#let _sort-author(entry, uppercase: true) = {
  let sk = _f(entry, "sortkey")
  if sk != none { return _normalize-sort-key(sk) }
  let k = _f(entry, "key")
  if k != none { return _normalize-sort-key(k) }
  let a = _format-names(entry.parsed_names, role: "author", entry: entry, uppercase: uppercase, et-al-min: 999, et-al-use-first: 999)
  if a != none { return _to-pinyin-key(a) }
  let e = _format-names(entry.parsed_names, role: "editor", entry: entry, uppercase: uppercase, et-al-min: 999, et-al-use-first: 999)
  if e != none { return _to-pinyin-key(e) }
  // 无作者无编者：用标题排序
  let t = _f(entry, "title")
  if t != none { _to-pinyin-key(str(t)) } else { "" }
}

/// 排序用的年份（安全提取）
#let _sort-year(entry) = {
  let y = _format-year(entry)
  if y != none { y.split("/").first() } else { "9999" }
}

// ============================================================
// 著者-出版年制辅助函数
// ============================================================

/// 获取引用处显示的短作者名（仅第一作者 + 等/et al）
#let _cite-author-short(entry, cite-et-al-min: 2, cite-et-al-use-first: 1, uppercase: true, name-format: "uppercase", no-etal: false) = {
  // useeditor / usetranslator 顶替链与 _get-main-author 一致，保证 author-year 引用与 bib 渲染对齐
  let names = entry.parsed_names.at("author", default: ())
  if names.len() == 0 { names = entry.parsed_names.at("editor", default: ()) }
  if names.len() == 0 { names = entry.parsed_names.at("translator", default: ()) }
  if names.len() == 0 { names = entry.parsed_names.at("holder", default: ()) }
  if names.len() == 0 { return none }
  let has-others = names.last().at("family", default: "") == "others" and names.last().at("given", default: "") == ""
  let real-names = if has-others { names.slice(0, -1) } else { names }
  let truncate = has-others or real-names.len() >= cite-et-al-min
  let show-count = if truncate { calc.min(real-names.len(), cite-et-al-use-first) } else { real-names.len() }
  let formatted = real-names.slice(0, show-count).map(n => _format-one-name(n, uppercase: uppercase, name-format: name-format))
  let result = formatted.join(", ")
  if truncate and not no-etal {
    let lang = _detect-lang(entry)
    let etal = if lang == "zh" { "等" }
    else if lang == "ja" { "他" }
    else if lang == "ko" { "등" }
    else if lang == "ru" { " и др" }
    else { ", et al" }
    result += etal
  }
  result
}

/// 预计算消歧后缀：同作者同年 → a/b/c
/// 双语条目（related+lanversion）视为同一条目，不单独消歧
#let _compute-disambiguation(bib-data, cite-et-al-min: 2, cite-et-al-use-first: 1, uppercase: true, name-format: "uppercase", sort-keys: none, scope-keys: none) = {
  // scope-keys 非 none 时只在这些 key 范围内消歧，避免 bib 里其他未使用条目污染后缀
  let active-keys = if scope-keys != none { scope-keys.filter(k => k in bib-data) } else { bib-data.keys() }
  // 收集被 related 关联的条目（这些条目是双语版本，不独立参与消歧）
  let related-targets = ()
  let related-pairs = (:) // key → related-key
  for key in active-keys {
    let entry = bib-data.at(key)
    let rel = entry.fields.at("related", default: none)
    let rel-type = entry.fields.at("relatedtype", default: none)
    if rel != none and rel-type != none and lower(str(rel-type)) == "lanversion" {
      let rk = str(rel)
      related-targets.push(rk)
      related-pairs.insert(key, rk)
    }
  }

  let cite-labels = (:)
  // dis-key → list of keys（消歧分组键：仅第一作者 + 年，不含等/et al）
  let keys-by-dis = (:)
  for key in active-keys {
    // 跳过被关联的双语目标条目（它们随主条目一起处理）
    if key in related-targets { continue }
    let entry = bib-data.at(key)
    // 完整引用标签（含等/et al）
    let author = _cite-author-short(entry, cite-et-al-min: cite-et-al-min, cite-et-al-use-first: cite-et-al-use-first, uppercase: uppercase, name-format: name-format)
    if author == none { author = "" }
    let year = _format-year(entry)
    if year == none { year = "" }
    cite-labels.insert(key, author + ", " + year)
    // 消歧键：仅取第一作者名，不含等/et al（has-others 时也不附加）
    let first-author = _cite-author-short(entry, cite-et-al-min: 999, cite-et-al-use-first: 1, uppercase: uppercase, name-format: name-format, no-etal: true)
    if first-author == none { first-author = author }
    // dis-key 用作 dict 键，必须是 str（避免 first-author/author 为 content 时失败）
    let first-key = if std.type(first-author) == str { first-author } else { repr(first-author) }
    let dis-key = first-key + "|" + year
    if dis-key not in keys-by-dis { keys-by-dis.insert(dis-key, ()) }
    keys-by-dis.at(dis-key).push(key)
  }
  let cite-suffixes = (:)
  for (_, keys) in keys-by-dis {
    if keys.len() > 1 {
      // 同作者同年组内的 a/b/c 分配：
      //   - 若用户提供了 sort-keys，组内任何出现在 sort-keys 里的条目按其位置排；
      //     未出现在 sort-keys 里的条目退化为按标题排，列在显式排序者之后。
      //   - 否则按标题升序。
      let sorted-keys = if sort-keys != none {
        keys.sorted(key: k => {
          let pos = sort-keys.position(sk => sk == k)
          if pos != none {
            (0, pos, "")
          } else {
            let e = bib-data.at(k, default: none)
            let title = if e != none { lower(str(e.fields.at("title", default: k))) } else { k }
            (1, 0, title)
          }
        })
      } else {
        keys.sorted(key: k => {
          let e = bib-data.at(k, default: none)
          if e == none { return k }
          lower(str(e.fields.at("title", default: k)))
        })
      }
      for (i, key) in sorted-keys.enumerate() {
        let s = str.from-unicode(97 + i)
        cite-suffixes.insert(key, s)
        // 双语关联条目共享同一后缀
        if key in related-pairs {
          cite-suffixes.insert(related-pairs.at(key), s)
        }
      }
    }
  }
  (cite-labels: cite-labels, cite-suffixes: cite-suffixes)
}

// ============================================================
// 9. 参考文献表渲染（替换 Hayagriva 输出）
// ============================================================

/// show bibliography 处理函数
/// 内部实现，用户无需直接调用。通过 `show bibliography` 规则接管参考文献渲染。
// 写入 <gb7714…key> / <gb7714…list…key> 标签供 cite 跳转。
// 注意：同一个 key 若在 #bibliography 和 print-bib 里同时渲染会触发 label 重复错误，自行取舍（典型用法二选一）。
// 段分隔符使用私有区字符 U+E001，保证 bib key / list-label 永远不会与之冲突：
// 否则 main 列表 key="a-1" 与 named 列表 list="a" key="1" 会生成相同 label "gb7714-a-1"。
#let _LSEP = "\u{E001}"
#let _emit-bib-label(key, list-label: none) = {
  if list-label == none {
    [#metadata("gb7714")#std.label("gb7714" + _LSEP + key)]
  } else {
    [#metadata("gb7714" + _LSEP + list-label)#std.label("gb7714" + _LSEP + list-label + _LSEP + key)]
  }
}

#let _gb7714-show-bibliography(bib-data, bib-key-order, full, uc, gp, ea-min, ea-first, s-url, s-doi, s-mark, s-medium, s-patent, s-short-j, s-urldate, s-endperiod, s-hyperlink, s-isbn, s-eprint, s-sentence, s-italic-j, s-bold-vol, s-italic-book, s-space-mark, s-space-pages, s-dash-pages, s-period-author, s-num-width, s-num-align, s-after-number-sep, s-item-sep, s-hanging, s-show-related, s-title, s-no-author, s-no-others, s-name-format, s-hyperlink-title, s-label-style, s-no-same-editor, s-skip-year, s-lang-order, s-hyphenate, s-sort-keys, s-back-ref, s-show-degree, it) = context {
    // 只统计主列表（active-list == none）的 refs
    let active-list-state = state("gb7714-active-list", none)
    let all-refs = query(ref).filter(r => active-list-state.at(r.location()) == none)
    let cited-keys = ()
    for r in all-refs {
      let key = str(r.target)
      if key not in cited-keys and key in bib-data {
        cited-keys.push(key)
      }
    }

    // full 模式：已引用 + 未引用（未引用按 bib 原始顺序追加）
    let ordered-keys = cited-keys
    if full {
      for key in bib-key-order {
        if key not in ordered-keys {
          ordered-keys.push(key)
        }
      }
    }

    // 著者-出版年制：按语言→作者→年[消歧后缀]→标题排序（而非引用顺序）
    if s-skip-year {
      let _dis = _compute-disambiguation(bib-data, cite-et-al-min: ea-min, cite-et-al-use-first: ea-first, uppercase: uc, name-format: s-name-format, sort-keys: s-sort-keys)
      ordered-keys = ordered-keys.sorted(key: k => {
        let e = bib-data.at(k, default: none)
        if e == none { return "zzz" }
        let lang = _lang-sort-key(e, lang-order: s-lang-order)
        let author = _sort-author(e, uppercase: uc)
        let year = _sort-year(e)
        let suffix = _dis.cite-suffixes.at(k, default: "")
        let title = lower(str(e.fields.at("title", default: "")))
        lang + author + year + suffix + title
      })
    }

    // 自定义排序：指定 key 顺序优先，其余追加
    if s-sort-keys != none {
      let in-order = s-sort-keys.filter(k => k in ordered-keys)
      let rest = ordered-keys.filter(k => k not in s-sort-keys)
      ordered-keys = in-order + rest
    }

    // 收集已被 related 关联的条目（避免重复输出）
    let related-keys = ()
    if s-show-related {
      for key in ordered-keys {
        let entry = bib-data.at(key, default: none)
        if entry == none { continue }
        let rel = entry.fields.at("related", default: none)
        let rel-type = entry.fields.at("relatedtype", default: none)
        if rel != none and rel-type != none and lower(str(rel-type)) == "lanversion" {
          related-keys.push(str(rel))
        }
      }
    }

    let _fmt(entry) = _format-entry(entry, uppercase: uc, show-missing-pub: gp, et-al-min: ea-min, et-al-use-first: ea-first, show-url: s-url, show-doi: s-doi, show-mark: s-mark, show-medium: s-medium, show-patent-country: s-patent, short-journal: s-short-j, show-urldate: s-urldate, hyperlink: s-hyperlink, show-isbn: s-isbn, show-eprint: s-eprint, sentence-case-title: s-sentence, italic-journal: s-italic-j, bold-journal-volume: s-bold-vol, italic-book-title: s-italic-book, space-before-mark: s-space-mark, space-before-pages: s-space-pages, dash-in-pages: s-dash-pages, period-after-author: s-period-author, no-author: s-no-author, no-others: s-no-others, name-format: s-name-format, hyperlink-title: s-hyperlink-title, no-same-editor: s-no-same-editor, skip-year: s-skip-year, show-degree: s-show-degree)

    // 计算编号列宽度：测量最宽编号
    let total-entries = ordered-keys.filter(k => k not in related-keys).len()
    // 用于测量的最大编号标签（需考虑标签样式）
    let _max-label = {
      let n = str(total-entries)
      if s-label-style == "paren" { "(" + n + ")" }
      else if s-label-style == "dot" { n + "." }
      else if s-label-style == "plain" { n }
      else if s-label-style == "fullwidth-bracket" { "〔" + n + "〕" }
      else if s-label-style == "fullwidth-paren" { "（" + n + "）" }
      else if s-label-style == "none" { "" }
      else { "[" + n + "]" }
    }
    let num-width = if s-label-style == "none" { 0pt }
    else if s-num-width != auto { s-num-width }
    else {
      measure(_max-label).width
    }

    if s-title != none {
      if s-title == auto {
        // 根据文档语言自动选择标题
        let t = context {
          let l = text.lang
          let r = text.region
          if l == "zh" {
            if r == "TW" or r == "HK" { "參考文獻" } else { "参考文献" }
          }
          else if l == "ja" { "参考文献" }  // 日文汉字写法同简中
          else if l == "ko" { "참고문헌" }
          else if l == "fr" { "Références" }
          else if l == "ru" { "Список литературы" }
          else { "References" }
        }
        heading(level: 1, numbering: none, t)
      } else if type(s-title) == str {
        heading(level: 1, numbering: none, s-title)
      } else { s-title }
    }
    // 编号标签格式化
    // number-style: "bracket" [1] | "paren" (1) | "dot" 1. | "plain" 1
    //   | "fullwidth-bracket" 〔1〕 | "fullwidth-paren" （1）
    //   | "circled" ①（Unicode 原生字形，>50 退化为 (N)）
    //   | "quan" ①（通过 @preview/quan 渲染，支持字形回退与样式定制）
    let _label(num) = {
      if s-label-style == "paren" { "(" + num + ")" }
      else if s-label-style == "dot" { num + "." }
      else if s-label-style == "plain" { num }
      else if s-label-style == "fullwidth-bracket" { "〔" + num + "〕" }
      else if s-label-style == "fullwidth-paren" { "（" + num + "）" }
      else if s-label-style == "circled" { _circled-num(int(num)) }
      else if s-label-style == "quan" { _quan-fn(int(num)) }
      else if s-label-style == "none" { [] }
      else { "[" + num + "]" }  // "bracket" 默认
    }

    // 预计算消歧后缀（著者-出版年制需要）；sort-keys 优先决定组内 a/b/c 顺序
    let _ay-suffixes = if s-skip-year {
      _compute-disambiguation(bib-data, sort-keys: s-sort-keys).cite-suffixes
    } else { (:) }

    let num-counter = 0
    for key in ordered-keys {
      if key in related-keys { continue }
      let entry = bib-data.at(key, default: none)
      if entry == none { continue }
      num-counter += 1
      let formatted = _fmt(entry)

      // 著者-出版年制：年份插入到作者后面
      if s-skip-year {
        let author = _get-main-author(entry, uppercase: uc, et-al-min: ea-min, et-al-use-first: ea-first, no-author: s-no-author, no-others: s-no-others, name-format: s-name-format)
        let year = _format-year(entry)
        let suffix = _ay-suffixes.at(key, default: "")
        if year != none { year = year + suffix }
        // 格式：Author, Year. Title...（无编号）
        let author-year-prefix = if author != none and year != none { author + ", " + year }
        else if author != none { author }
        else if year != none { year }
        else { "" }
        // formatted 已经包含 author 但没有 year（skip-year=true）
        // 需要把 formatted 中的 author 部分替换为 author+year
        // 由于 formatted 是 content，无法简单操作
        // 方案：直接组合 author-year-prefix + 去掉 author 的剩余部分
        // 更实际的方案：重新格式化，year 手动插在 _join-parts 的 author 后
        // 简化方案：直接输出 formatted（已有 author 无 year），然后在显示层面把 year 补上
        // 最简化：formatted 的第一个 ". " 分隔符前是 author，在其后插入 year
        // 终极简化：直接让 formatted 包含 author（已有），然后手动在条目最前面加 ", year"
        // ... 实际上 formatted = "Author. Title..." 的 content
        // 我们在渲染时手动构建：Author, Year. [formatted without author]
        // 由于无法从 content 中去掉 author，我们重新构建完整内容
        let rest = _format-entry(entry, uppercase: uc, show-missing-pub: gp, et-al-min: ea-min, et-al-use-first: ea-first, show-url: s-url, show-doi: s-doi, show-mark: s-mark, show-medium: s-medium, show-patent-country: s-patent, short-journal: s-short-j, show-urldate: s-urldate, hyperlink: s-hyperlink, show-isbn: s-isbn, show-eprint: s-eprint, sentence-case-title: s-sentence, italic-journal: s-italic-j, bold-journal-volume: s-bold-vol, italic-book-title: s-italic-book, space-before-mark: s-space-mark, space-before-pages: s-space-pages, dash-in-pages: s-dash-pages, period-after-author: s-period-author, no-author: true, no-others: s-no-others, name-format: s-name-format, hyperlink-title: s-hyperlink-title, no-same-editor: s-no-same-editor, skip-year: true, skip-author: true, show-degree: s-show-degree)
        // rest = 无作者无年份的条目（以题名开头）
        let full-entry = [#author-year-prefix. #rest]

        // related
        let rel-content = if s-show-related {
          let r = entry.fields.at("related", default: none)
          let rt = entry.fields.at("relatedtype", default: none)
          if r != none and rt != none and lower(str(rt)) == "lanversion" {
            let re = bib-data.at(str(r), default: none)
            if re != none {
              let rel-author = _get-main-author(re, uppercase: uc, et-al-min: ea-min, et-al-use-first: ea-first, no-author: s-no-author, no-others: s-no-others, name-format: s-name-format)
              let rel-year = _format-year(re)
              let rel-suffix = _ay-suffixes.at(str(r), default: "")
              if rel-year != none { rel-year = rel-year + rel-suffix }
              let rel-prefix = if rel-author != none and rel-year != none { rel-author + ", " + rel-year }
              else if rel-author != none { rel-author } else if rel-year != none { rel-year } else { "" }
              let rel-rest = _format-entry(re, uppercase: uc, show-missing-pub: gp, et-al-min: ea-min, et-al-use-first: ea-first, show-url: s-url, show-doi: s-doi, show-mark: s-mark, show-medium: s-medium, show-patent-country: s-patent, short-journal: s-short-j, show-urldate: s-urldate, hyperlink: s-hyperlink, show-isbn: s-isbn, show-eprint: s-eprint, sentence-case-title: s-sentence, italic-journal: s-italic-j, bold-journal-volume: s-bold-vol, italic-book-title: s-italic-book, space-before-mark: s-space-mark, space-before-pages: s-space-pages, dash-in-pages: s-dash-pages, period-after-author: s-period-author, no-author: true, no-others: s-no-others, name-format: s-name-format, hyperlink-title: s-hyperlink-title, no-same-editor: s-no-same-editor, skip-year: true, skip-author: true, show-degree: s-show-degree)
              let rel-ends-abbrev = _content-ends-with-abbrev-period(re, skip-year: true, show-url: s-url, show-doi: s-doi, show-isbn: s-isbn, show-eprint: s-eprint)
              [#rel-prefix. #rel-rest#if s-endperiod and not rel-ends-abbrev [.]]
            } else { none }
          } else { none }
        } else { none }

        // 检查条目内容是否以缩写点（Inc./Ltd.）结尾，避免 ".."
        let ends-abbrev = _content-ends-with-abbrev-period(entry, skip-year: true, show-url: s-url, show-doi: s-doi, show-isbn: s-isbn, show-eprint: s-eprint)
        let blk-sp = if s-item-sep != auto { (spacing: s-item-sep) } else { (:) }
        let _lang = _detect-lang(entry)
        let _ay-inner = {
          _emit-bib-label(key)
          set par(hanging-indent: 2em, first-line-indent: 0pt)
          [#full-entry#if s-endperiod and not ends-abbrev [.]]
          if rel-content != none { linebreak(); rel-content }
        }
        let _ay-wrapped = if _lang not in ("zh", "ja", "ko") { text(lang: _lang, hyphenate: s-hyphenate, _ay-inner) } else { _ay-inner }
        block(..blk-sp, _ay-wrapped)
      } else {
        // ---- 顺序编码制 ----
        let num = str(num-counter)
        let lbl = _label(num)
        // back-ref：把编号包成 link 跳到正文中首次引用该 key 的位置
        // 主参考文献表只匹配 active-list-state == none 的 cites
        if s-back-ref and s-label-style != "none" {
          let cites = query(std.cite).filter(c =>
            str(c.key) == key and active-list-state.at(c.location()) == none
          )
          if cites.len() > 0 { lbl = link(cites.first().location(), lbl) }
        }

        // related 内容（受 show-related 控制）
        let rel-content = if s-show-related {
          let r = entry.fields.at("related", default: none)
          let rt = entry.fields.at("relatedtype", default: none)
          if r != none and rt != none and lower(str(rt)) == "lanversion" {
            let re = bib-data.at(str(r), default: none)
            if re != none { [#_fmt(re)#if s-endperiod [.]] } else { none }
          } else { none }
        } else { none }

        // block spacing
        let blk-sp = if s-item-sep != auto { (spacing: s-item-sep) } else { (:) }
        let _lang = _detect-lang(entry)

        let _wrap(body) = if _lang not in ("zh", "ja", "ko") { text(lang: _lang, hyphenate: s-hyphenate, body) } else { body }
        if s-label-style == "none" {
          // 无编号：只输出条目本体，保留悬挂缩进（若启用）
          let _inner = {
            _emit-bib-label(key)
            set par(hanging-indent: if s-hanging { 2em } else { 0em }, first-line-indent: 0pt)
            [#formatted#if s-endperiod [.]]
            if rel-content != none { parbreak(); rel-content }
          }
          block(..blk-sp, _wrap(_inner))
        } else if not s-hanging {
          let _inner = {
            _emit-bib-label(key)
            set par(first-line-indent: 0pt)
            [#lbl#h(s-after-number-sep)#formatted#if s-endperiod [.]]
            if rel-content != none {
              linebreak()
              h(measure(lbl).width + s-after-number-sep)
              rel-content
            }
          }
          block(..blk-sp, _wrap(_inner))
        } else {
          let num-align = if s-num-align == "left" { left } else if s-num-align == "center" { center } else { right }
          let _inner = {
            _emit-bib-label(key)
            grid(
              columns: (num-width, 1fr),
              column-gutter: s-after-number-sep,
              row-gutter: par.leading,
              align(num-align, lbl),
              [#formatted#if s-endperiod [.]],
              ..if rel-content != none { ([], rel-content) } else { () },
            )
          }
          block(..blk-sp, _wrap(_inner))
        }
      }
    }
  }
}


// 带圈数字 ①–⑳（U+2460–U+2473）㉑–㉟（U+3251–U+325F）㊱–㊿（U+32B1–U+32BF）
#let _circled-num-table = (
  "①","②","③","④","⑤","⑥","⑦","⑧","⑨","⑩",
  "⑪","⑫","⑬","⑭","⑮","⑯","⑰","⑱","⑲","⑳",
  "㉑","㉒","㉓","㉔","㉕","㉖","㉗","㉘","㉙","㉚",
  "㉛","㉜","㉝","㉞","㉟","㊱","㊲","㊳","㊴","㊵",
  "㊶","㊷","㊸","㊹","㊺","㊻","㊼","㊽","㊾","㊿",
)
#let _circled-num(n) = {
  if n >= 1 and n <= 50 { _circled-num-table.at(n - 1) }
  else { "(" + str(n) + ")" }  // >50 退化为 (N)
}

// 标记字符：用零宽 word joiner 包裹数字，区分普通文本中的数字
// 格式：⁠N⁠（无补充）或 ⁠N⁡SUPP⁠（有补充，⁡ = U+2061 分隔符）
#let _M  = "\u{E000}"   // 标记边界（私有区，避免与 jurlstify/URL 中的 word joiner 冲突）
#let _MS = "\u{2061}"   // 补充分隔符（function application）
#let _ML = "\u{2062}"   // 命名列表分隔符（invisible times）
// 主列表标记格式：  ⁠N⁠  或  ⁠N⁡supp⁠
// 命名列表标记格式：⁠⁢list⁢N⁠  或  ⁠⁢list⁢N⁡supp⁠

// 从 content 中提取纯文本（用于将 it.supplement 编码到标记中）
#let _supp-to-str(c) = {
  if c == none or c == auto { return none }
  if type(c) == str { return c }
  let f = c.fields()
  if "text" in f { return str(f.text) }
  if "children" in f {
    let parts = f.children.map(ch => {
      let cf = ch.fields()
      if "text" in cf { str(cf.text) } else { "" }
    })
    return parts.join("")
  }
  none
}

// ============================================================
// 10. 公共 API
// ============================================================

/**
= `gb7714` — 初始化函数 <gb7714-fn>

解析 `.bib` 文件，返回含以下键的字典（可按需解构）：

- `init-gb7714`: 必须以 `show` 规则应用任何引用前——```typ #show: init-gb7714```；
- `bibliography`: 打印主参考文献列表（别名 `gb7714-bibliography`）；
- `print-bib`: 打印自定义参考文献列表（支持过滤、排序、多列表，亦可用 `keys:` 原位渲染指定条目）；
- `cite`: ```typ @key``` 语法的增强版，例如使用配置项 `footnote: true` 可实现脚注引用（在脚注中打印参考文献）；
- `set-bib-label`: 切换后续 ```typ <key>``` 所归属的参考文献列表。
**/
#let gb7714(
  path,                          /// <- string | array | dictionary <required>
    /// `read()` 返回的 bib 内容。三种形式：\
    /// - 单个内容：`gb7714(read("refs.bib"))`；
    /// - 数组：`gb7714((read("ref/a.bib"), read("ref/b.bib")))`；
    /// - 带标签字典：`gb7714(("label-a": read("a.bib"), "label-b": read("b.bib")))`：
    ///     - 标签作为 ```typ #print-bib(bib-file: "..")``` 的匹配值，用于打印指定文件中的条目，方式一、二下 ```typ #print-bib(..)``` 无标签可用，过滤会返回空。|
  // ── 整体样式 ──
  full:                false,     /// <- boolean
    /// - `false`：参考文献表仅输出引用过的条目；
    /// - `true`：参考文献表输出全部条目，未引用的追加在已引用的之后：
    ///   - 对于顺序编码制，其余条目默认按照 `.bib` 文件中的顺序追加；\
    ///   - 对于著者-出版年制，默认按照著者姓名拼音排序。|
  style:               "numeric", /// <- string
    /// 引用格式。\
    /// - `"numeric"`：顺序编码制，如#super[[1]]；
    /// - `"author-year"`：著者-出版年制，如 (张三，2020)。|
  // ── 作者格式 ──
  et-al-min:           4,         /// <- integer
    /// $>=N$ 位作者时触发“等 / et al”截断。|
  et-al-use-first:     3,         /// <- integer
    /// 截断后保留前 $N$ 位作者。|
  name-format:         "uppercase", /// <- string
    /// 西文姓名格式（中文姓名不受影响），以 `Zhao, Yu Xin` 为例：\
    /// - `"uppercase"`（默认）：符合 GB/T 7714-2015，姓全大写、名取首字母无点，输出 `ZHAO Y X`；
    /// - `"lowercase"`：保留输入大小写，名取首字母，输出 `Zhao Y X`；
    /// - `"given-ahead"`：名前姓后，类 IEEE 风格，输出 `Y X ZHAO`；
    /// - `"fullname"`：英文全拼模式，名以驼峰式拼接、名在前姓在后，姓保留输入大小写，输出 `YuXin Zhao`；
    /// - `"pinyin"`：名拼音首词首字母大写其余小写、姓全大写、连字符连接，输出 `ZHAO Yu-xin`；
    /// - `"quanpin"`：名拼音直接拼接无分隔，姓保留输入大小写，输出 `Zhao Yuxin`。|
  no-author:           false,     /// <- boolean
    /// 控制责任者缺失时的占位符。\
    /// - `false`：作者位置留空；
    /// - `true`：无作者条目显示“佚名”/“Anon”/ 对应语言描述：
    /// #table( columns: 6,
    ///   [*语言代码*], [`zh`], [`ja`], [`ko`], [`ru`], [`en`、`fr` 及其他],
    ///   [*标题*], [佚名], [#text(font: "MS Mincho")[著者不明]], [#text(font: "Batang")[미상]], [Аноним], [Anon],
    /// )|
  no-others:           false,     /// <- boolean
    /// - `false`：多作者超阈值时截断；
    /// - `true`：不截断，显示全部作者。|
  no-same-editor:      false,     /// <- boolean
    /// - `false`：析出文献的编者正常输出；
    /// - `true`：析出文献的编者与上条相同时省略编者行。|
  // ── 正文引用标注 ──
  cite-compress-min:   2,         /// <- integer
    /// 顺序编码制中，$>=N$ 个连续编号时压缩为范围。|
  cite-et-al-min:      2,         /// <- integer
    /// 正文引用中，$>=N$ 位作者时触发截断。|
  cite-et-al-use-first: 1,        /// <- integer
    /// 正文引用中，截断后保留前 $N$ 位作者。|
  cite-super:          true,      /// <- boolean
    /// - `true`：顺序编码制引用标注以上标方括号输出；
    /// - `false`：以正文大小方括号输出，不上标。\
    /// 单次可通过 #arg-ref("cite", "super")[ ```typ #cite()``` 的 `super` 参数]覆盖。|
  cite-name-format:    auto,      /// <- auto | "uppercase" | "lowercase" | "given-ahead" | "fullname" | "pinyin" | "quanpin"
    /// 著者-出版年制正文引用中的姓名格式。可选值同 #arg-ref("gb7714", "name-format")[`name-format`配置项]。\
    /// - `auto`（默认）：跟随 #arg-ref("gb7714", "name-format")[`name-format`配置项]。\
    /// 这里解释一下 #arg-ref("gb7714", "name-format")[`name-format`] 和 #arg-ref("gb7714", "cite-name-format")[`cite-name-format`]的区别：
    /// - #arg-ref("gb7714", "name-format")[`name-format`] 是指在参考文献条目中西文姓名格式，如：\
    ///   - #text(fill: red)[CRANE D], 1972. Invisible College[M]. Chicago: Univ. of Chicago Press.
    /// - #arg-ref("gb7714", "cite-name-format")[`cite-name-format`] 是指引用处的西文姓名格式，如：
    ///   - The notion of an invisible college has been explored in the sciences (#text(fill: red)[CRANE D], 1972).\
    /// *其他 `xxx` 与 `cite-xxx` 配置项的关系大抵如此，如无例外，后续不再赘述。*
  // ── 参考文献表布局 ──
  hanging:         true,      /// <- boolean
    /// - `true`：悬挂缩进排版——编号列对齐，正文悬挂；
    /// - `false`：编号与条目文字作为整体排版，无特殊格式。|
  hyphenate:       true,      /// <- boolean
    /// - `true`：参考文献表内允许西文断字；
    /// - `false`：禁用西文断字。|
  item-sep:        auto,      /// <- auto | length
    /// 条目间距。`auto` 继承当前段落间距。|
  after-number-sep:       0.5em,     /// <- length
    /// 编号之后与条目文字的间距。|
  number-style:     "bracket", /// <- string
    /// 编号标签样式：\
    /// - `"bracket"`：[1]；
    /// - `"paren"`：(1)；
    /// - `"dot"`：1.；
    /// - `"plain"`：1；
    /// - `"fullwidth-bracket"`：〔1〕；
    /// - `"fullwidth-paren"`：（1）；
    /// - `"circled"`：①，直接取 Unicode U+2460–U+32BF，超过㊿以(N)形式显示；
    /// - `"quan"`：①，由 ```typ quan``` 包渲染，可避免所用字体不支持全部 Unicode 带圈数字，可在主文档 ```typ #import "@preview/quan:0.1.0": quan-init, quan-style``` 后调用配置；
    /// - `"none"`：不显示编号。|
  number-align:    "right",   /// <- string
    /// 编号对齐方式：\
    /// - `"right"`：右对齐；
    /// - `"left"`：左对齐；
    /// - `"center"`：居中。|
  number-width:    auto,      /// <- auto | length
    /// 编号列宽度。`auto` 自动测量最宽编号。|
  title:           auto,      /// <- auto | none | content
    /// 参考文献表标题。\
    /// - `auto`：根据文档语言决定：
    /// #table( columns: 8,
    ///   [*语言代码*], [`zh`], [`zh`], [`ja`], [`ko`], [`fr`], [`ru`], [`en` 及其他],
    ///   [*地区*], [—], [`tw` / `hk`], [—], [—], [—], [—], [—],
    ///   [*标题*], [参考文献], [#text(font: "PMingLiU")[參考文獻]], [#text(font: "MS Mincho")[参考文献]], [#text(font: "Batang")[참고문헌]], [Références], [Список литературы], [References],
    /// )
    /// - `none`：不显示标题；
    /// - `content`：传入自定义内容作为标题。|
  // ── 排序 ──
  lang-order: ("zh", "ja", "ko", "en", "fr", "ru"), /// <- array
    /// 多语言混排时的语种分组顺序，靠前的语种排在前面。|
  sort-keys:           none,      /// <- none | content
    /// 自定义排序：\
    /// - `none`（默认）：按样式排序；
    /// - `content`：传入内容块，内部用 ```typ @key``` 引用指定的条目，按书写顺序优先排列，其余追加在后：\
    ///   - `sort-keys: [@key1]` → ```typ <key1>``` 对应条目将在主参考文献列表（```typ #bibliography```）中最先展示；\
    ///   - `sort-keys: [@key1@key2@key3]` → 三个 ```typ <key>``` 对应条目将依次优先展示；
    ///   - 追加在后面的条目依然按照当前所采用的排列方式追加，未引用条目的追加方式同 #arg-ref("gb7714", "full")[`full` 配置项]所述。|
  // ── 显示项目 ──
  hyperlink:           true,      /// <- boolean
    /// - `true`：URL / DOI 渲染为可点击超链接；
    /// - `false`：渲染为纯文本。|
  short-journal:       false,     /// <- boolean
    /// - `false`：使用 `journal` 字段作为期刊名；
    /// - `true`：使用 `shortjournal` 字段代替。|
  show-doi:            true,      /// <- boolean
    /// - `true`：显示 DOI，条目自动标为 /OL；
    /// - `false`：隐藏 DOI，同时禁用 /OL 自动载体判定。|
  show-eprint:         false,     /// <- boolean
    /// - `false`：隐藏 eprint；
    /// - `true`：显示 eprint（arXiv 号等）。|
  show-isbn:           false,     /// <- boolean
    /// - `false`：隐藏 ISBN；
    /// - `true`：在书目中显示 ISBN。|
  show-mark:           true,      /// <- boolean
    /// - `true`：显示文献类型标识（如 J）；
    /// - `false`：隐藏。|
  show-medium:         true,      /// <- boolean
    /// - `true`：显示载体标识（如/OL）；
    /// - `false`：隐藏。|
  show-missing-pub:    true,      /// <- boolean
    /// - `true`：缺失出版地 / 出版者时显示占位符；
    /// - `false`：留空。|
  show-patent-country: false,     /// <- boolean
    /// - `false`：不显示专利国；
    /// - `true`：专利条目显示专利国（取 `address` / `location` 字段）。|
  show-related:        true,      /// <- boolean
    /// - `true`：渲染双语关联条目：\
    /// - `false`：不渲染。\
    /// 用法如下：\
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
    /// 当 `show-related: true` 时，引用第一语言条目的键值 ```typ <primary-entry>```，则此条目将渲染为：\
    /// [1]#h(.5em)이병목. 도서관법규총람: 제 1 권[M]. 서울: 구미무역 출판부, 2005: 67-68.\
    /// #h(1.65em)李炳穆. 图书馆法规总览: 第1卷 [M]. 首尔: 九美贸易出版部, 2005: 67-68.|
  show-url:            true,      /// <- boolean
    /// - `true`：显示 URL，条目自动标为 /OL；
    /// - `false`：隐藏 URL，同时禁用 /OL 自动载体判定：\
    ///   - 当 `show-url: false` 时，如果仍想要显示 /OL 载体，可通过添加 `medium = {OL}` 字段强制显示，如：\
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
    /// 此条目将渲染为：\
    /// [1]#h(.5em)КОЧЕТКОВ А Я. Молибден-медно-золотопорфировое месторождение Рябиновсе\
    /// #h(1.65em) [J/OL]. Отечественная геология, 1993(7): 50-58.|
  show-urldate:        true,      /// <- boolean
    /// - `true`：显示引用日期（`urldate` 字段）；
    /// - `false`：隐藏。|
  hyperlink-title:          false,     /// <- boolean
    /// - `false`：条目题名为纯文本；
    /// - `true`：条目题名渲染为可点击的超链接（需有 `url` / `doi` 字段）。|
  // ── 格式化细节 ──
  bold-journal-volume: false,     /// <- boolean
    /// - `false`：期刊卷号正常字重；
    /// - `true`：期刊卷号加粗。|
  dash-in-pages:       "-",       /// <- string
    /// 页码范围连字符，可接受任意字符串，例如全角波浪线`"～"`。|
  end-with-period:     true,      /// <- boolean
    /// - `true`：条目不以缩写点结尾时自动追加句号 `.`；
    /// - `false`：不追加。|
  italic-book-title:   false,     /// <- boolean
    /// - `false`：西文专著 / 论文集题名（非析出）正体；
    /// - `true`：渲染为斜体。|
  italic-journal:      false,     /// <- boolean
    /// - `false`：期刊 / 报纸名正体；
    /// - `true`：渲染为斜体。|
  period-after-author: true,      /// <- boolean
    /// - `true`：作者字段后加 `.`；
    /// - `false`：改用空格分隔。|
  sentence-case-title: false,     /// <- boolean
    /// - `false`：保留西文题名原大小写；
    /// - `true`：转换为仅句首大写：\
    ///   - 例如 `title = {DNA Methylation Patterns in Aging Tissues}` 将被渲染为：
    ///     Dna methylation patterns in aging tissues；\
    ///   - 对于 DNA 这种应保持大写的专有名词，可用一对花括号保护，例如 `title = {{DNA} Methylation Patterns in Aging Tissues}` 将被渲染为：
    ///     DNA methylation patterns in aging tissues。|
  space-before-mark:   false,     /// <- boolean
    /// - `false`：文献类型标识 `[M]` 前无空格；
    /// - `true`：前加空格。|
  space-before-pages:  true,      /// <- boolean
    /// - `true`：页码前加空格（`: 123`）；
    /// - `false`：无空格（`:123`）。|
  // ── 脚注 ──
  footnote-style:      none,      /// <- none | "circled" | "quan"
    /// 脚注编号样式。仅控制编号外观，字号 / 缩进 / 对齐等请用户自行 `set footnote(...)` / `set footnote.entry(...)`：\
    /// - `none`（默认）：不改动，走用户文档的配置或 Typst 默认（Typst 原生 footnote 已自带正文↔条目双向跳转）；
    /// - `"circled"`：Unicode 原生带圈数字 ①–㊿（`_circled-num`，>50 退化为 `(N)`）；
    /// - `"quan"`：由 ```typ @preview/quan``` 包渲染，可避免字体不支持部分 Unicode 带圈数字。|
  back-ref:            false,     /// <- boolean
    /// 参考文献条目编号反向跳转。\
    /// - `false`（默认）：编号为纯文本，无链接；
    /// - `true`：点击参考文献表中的编号跳转到正文中*首次*引用该文献的位置。\
    /// 仅在条目实际带编号时生效（即 #arg-ref("gb7714", "number-style")[`number-style`] 不为 `"none"`、且非著者-出版年制）。|
  show-degree:         false,     /// <- boolean
    /// 学位论文条目附加学位级别注记（仅 type-mark = `D` 的条目生效）。\
    /// - `false`（默认）：不附加，`@thesis` / `@mastersthesis` / `@phdthesis` 渲染相同；
    /// - `true`：在题名标识 `[D]` 后插入学位级别字符串：
    ///   - `@mastersthesis`（或 `@thesis` + `type = {mathesis}`）：中文 *硕士学位论文* / 英文 *MA thesis* / 日文 *修士論文* / 韩文 *석사학위논문* / 俄文 *магистерская диссертация* / 法文 *thèse de master*；
    ///   - `@phdthesis`（或 `@thesis` + `type = {phdthesis}`）：中文 *博士学位论文* / 英文 *PhD thesis* / 日文 *博士論文* / 韩文 *박사학위논문* / 俄文 *докторская диссертация* / 法文 *thèse de doctorat*；
    ///   - 裸 `@thesis` 无 `type` 字段：不附加（与 biblatex 标准 `\printfield{type}` 在缺 type 时的行为一致）。|
) = {
  let uppercase-name = name-format not in ("lowercase", "quanpin", "fullname")
  let _cite-super-state = state("gb7714-cite-super-override", auto)
  let _cite-name-format-state = state("gb7714-cite-name-format-override", auto)

  let bib-file-keys = (:)  // label → entry keys，用于 print-bib(bib-file:) 过滤
  let bib-parts = ()        // bib 内容片段

  // 内容合理性检查：bib 内容里应当至少有一个 `@type{key, ...}` 条目
  // 若用户误把路径字符串直接传进来（如 `gb7714("refs.bib")` 或 `(read: "refs.bib")`），
  // 第一时间 panic，避免让用户对着一堆 "label not exist" 错误猜谜
  let _hint = "\n请确保通过 `read()` 读取内容再传入，如 gb7714(read(\"refs.bib\"))。"
  let _assert-bib-content(s, ctx) = {
    let str-s = str(s)
    if not str-s.contains(regex("@\\w+\\s*\\{")) {
      panic("gb7714: " + ctx + " 不是有效的 .bib 内容。" + _hint
        + "\n收到的值：" + (if str-s.len() > 60 { str-s.slice(0, 60) + "…" } else { str-s }))
    }
  }

  if type(path) == dictionary {
    for (label, content) in path {
      _assert-bib-content(content, "字典 key `" + label + "` 对应的值")
      let keys = content.matches(regex("@\\w+\\{([^,\\s]+)")).map(m => m.captures.first())
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
    panic("gb7714: path 必须是 read() 内容字符串、字符串数组或标签字典；不再支持直接路径字符串。" + _hint)
  }
  let bib-string = bib-parts.join("\n")

  let bib-data = load-bibliography(bib-string, keep-raw-names: true, sentence-case-titles: sentence-case-title)
  // 保留 .bib 文件中的条目顺序（字典无序，需从原始文本提取）
  let bib-key-order = bib-string.matches(regex("@\\w+\\{([^,\\s]+)")).map(m => m.captures.first())

  // 多参考文献列表支持：当前活动列表 state
  // none = 主参考文献表（gb7714-bibliography），字符串 = 指向 print-bib(label: 该字符串)
  let _active-list = state("gb7714-active-list", none)
  // 各命名列表的引用样式覆盖：dict，键为 list-label，值为 "numeric"/"author-year"
  let _list-style-map = state("gb7714-list-style-map", (:))
  // 列表名 → 纯数字 shortID（避免含点/连字符的列表名在标记中被断行）
  let _list-ids = state("gb7714-list-ids", (:))
  // 各命名列表的消歧后缀：dict，键为 list-label，值为 cite-suffixes dict
  let _list-suffix-map = state("gb7714-list-suffix-map", (:))
  /**
  = `set-bib-label` — 切换引用列表 <set-bib-label>

  将后续 ```typ @key```（或 ```typ #cite()```）引用归属到指定的参考文献列表，
  配合 ```typ #print-bib(label: "..")``` 可实现多参考文献列表分区排版。

  传入 `none` 则可恢复到主列表（```typ #bibliography```）。
  引用格式由对应的 ```typ #print-bib(label: "..", style: "..")``` 决定。

  ```typ
  #set-bib-label("sec2") // 切换到新的参考文献列表，此列表的标签为 "sec2"
  @zhang2020@li2021      // 这两条引用的格式由后续的 print-bib(style: "..") 决定

  = 第二节参考文献
  #print-bib(
    label: "sec2",       // 打印标签为 "sec-2" 的参考文献列表
    style: "author-year" // 引用格式在这里决定，如果不显式指定则使用全局的格式
  )

  #set-bib-label(none)   // 恢复主参考文献列表
  #bibliography
  ```
  **/
  let set-bib-label(
    list-label, /// <- string | none <required>
      /// 列表标签；`none` 恢复到主列表。|
  ) = {
    _active-list.update(list-label)
    if list-label != none {
      _list-ids.update(m => { if list-label not in m { m.insert(list-label, str(m.len() + 1)) }; m })
    }
  }

  // 递归提取 content 中的 ref 元素（供 cite 使用）
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
  // sort-keys 统一为内容块 `[@key1@key2 ...]`，内部归一化为字符串数组
  // 保留原内容以便 init-gb7714 中原样吐出无效 ref，让错误指向用户源码位置
  let _sort-keys-content = sort-keys
  let sort-keys = if sort-keys == none { none }
    else { _extract-refs(sort-keys).map(r => str(r.target)) }
  // cite-name-format 为 auto 时跟随全局 name-format；解析后供引用标签计算用
  let cite-name-format-eff = if cite-name-format != auto { cite-name-format } else { name-format }

  // 著者-出版年制：预计算消歧后缀（基于 cite 姓名格式，保证消歧分组键与渲染一致）
  let _cite-uppercase-eff = cite-name-format-eff not in ("lowercase", "quanpin", "fullname")
  let _ay-data = _compute-disambiguation(bib-data, cite-et-al-min: cite-et-al-min, cite-et-al-use-first: cite-et-al-use-first, uppercase: _cite-uppercase-eff, name-format: cite-name-format-eff, sort-keys: sort-keys)

  // 著者-出版年制：获取某条目的引用标签文本（含消歧后缀）
  // nf: 姓名格式，默认取全局 cite-name-format-eff
  let _ay-cite-label(key, nf: cite-name-format-eff, suffixes: none) = {
    let entry = bib-data.at(key, default: none)
    if entry == none { return key }
    let uc = nf not in ("lowercase", "quanpin", "fullname")
    let author = _cite-author-short(entry, cite-et-al-min: cite-et-al-min, cite-et-al-use-first: cite-et-al-use-first, uppercase: uc, name-format: nf)
    if author == none { author = key }
    let year = _format-year(entry)
    if year == none { year = "" }
    let suffix-table = if suffixes != none { suffixes } else { _ay-data.cite-suffixes }
    let suffix = suffix-table.at(key, default: "")
    author + ", " + year + suffix
  }

  let init-gb7714(body) = {
    // 顶层 `sort-keys` 里含 bib-data 外的 key → 原样吐出对应 ref，触发 `label does not exist`
    if _sort-keys-content != none {
      for r in _extract-refs(_sort-keys-content) {
        if str(r.target) not in bib-data { r }
      }
    }

    // 脚注编号样式：仅当指定了自定义样式时覆盖 numbering；否则保留用户/默认设置。
    // set 规则需与 `body` 同作用域才能生效，故封装为在每个 style 分支末尾调用的 _emit-body。
    let _emit-body() = {
      if footnote-style == "circled" {
        set footnote(numbering: n => _circled-num(n))
        body
      } else if footnote-style == "quan" {
        set footnote(numbering: n => _quan-fn(n))
        body
      } else {
        body
      }
    }

    show bibliography: _gb7714-show-bibliography.with(bib-data, bib-key-order, full, uppercase-name, show-missing-pub, et-al-min, et-al-use-first, show-url, show-doi, show-mark, show-medium, show-patent-country, short-journal, show-urldate, end-with-period, hyperlink, show-isbn, show-eprint, sentence-case-title, italic-journal, bold-journal-volume, italic-book-title, space-before-mark, space-before-pages, dash-in-pages, period-after-author, number-width, number-align, after-number-sep, item-sep, hanging, show-related, title, no-author, no-others, name-format, hyperlink-title, number-style, no-same-editor, style == "author-year", lang-order, hyphenate, sort-keys, back-ref, show-degree)

    // 公共辅助：解析 show regex 匹配文本中的标记
    // 返回 (num, supp-or-none, list-or-none) 列表
    // 主列表标记：⁠N⁠ 或 ⁠N⁡supp⁠  → list: none
    // 命名列表标记：⁠⁢listname⁢N⁠ 或 ⁠⁢listname⁢N⁡supp⁠ → list: listname
    let _parse-markers(text) = {
      text.matches(regex("\u{E000}[^\u{E000}]+\u{E000}")).map(m => {
        let inner = m.text.trim("\u{E000}")
        if inner.starts-with(_ML) {
          let parts = inner.split(_ML)  // ("", listname, "N[⁡supp]")
          let listname = parts.at(1, default: "")
          let subs = parts.at(2, default: "0").split(_MS)
          (num: int(subs.at(0)), supp: if subs.len() > 1 { subs.at(1) } else { none }, list: listname)
        } else {
          let subs = inner.split(_MS)
          (num: int(subs.at(0)), supp: if subs.len() > 1 { subs.at(1) } else { none }, list: none)
        }
      })
    }

    // 查询条目标签；缺失时给出比 Typst 原生 "label does not exist" 更人性化的提示。
    // 典型场景：用户忘了 `#bibliography` 或 `#print-bib()` 渲染对应列表，
    // 或者引用本应归属某命名列表却漏了 `#set-bib-label("xxx")` 切换。
    // 必须在 `context { ... }` 里调用（query 依赖 context）。
    let _bib-link(lbl-str, list-label, bib-key, body) = {
      let lbl = std.label(lbl-str)
      if query(lbl).len() == 0 {
        let hint = if list-label == none {
          "（当前引用属主参考文献列表）。请确认已用 `#bibliography` 渲染主列表；若该条目本应归属某命名列表，需在引用前调用 `#set-bib-label(\"列表名\")` 切换活动列表。"
        } else {
          "（当前引用属命名列表 `" + list-label + "`）。请确认已用 `#print-bib(label: \"" + list-label + "\")` 渲染该命名列表。"
        }
        panic("gb7714: 引用 key `" + bib-key + "` 找不到对应参考文献条目渲染位置" + hint)
      }
      link(lbl, body)
    }

    if style == "author-year" {
      // ---- 著者-出版年制引用 ----
      // @key → ref → 转发给 cite；#cite() 直接进入 cite 规则
      show ref: it => if str(it.target) in bib-data { std.cite(it.target, supplement: if it.supplement == auto { none } else { it.supplement }) } else { it }
      // 用数字索引做不可见标记；有 supplement 时追加 ⁡SUPP
      show std.cite: it => {
        let key = str(it.key)
        // 未在 bib-data 的 key 交还为 ref，触发 `label does not exist`（否则 std.cite 会报 "no bibliography"）
        if key not in bib-data { return std.ref(it.key) }
        let supp = _supp-to-str(it.supplement)
        context {
          let all-bib-refs = query(std.cite).filter(r => str(r.key) in bib-data)
          let seen = ()
          for r in all-bib-refs {
            let k = str(r.key)
            if k not in seen { seen.push(k) }
          }
          let idx = seen.position(k => k == key)
          if idx == none { return it }
          let marker-body = str(idx + 1) + if supp != none { _MS + supp } else { "" }
          _M + marker-body + _M
        }
      }
      // 匹配相邻标记（含可选 supplement），渲染为 (Author, Year: supp; ...)
      show regex("\u{E000}[^\u{E000}]+\u{E000}(\\s*\u{E000}[^\u{E000}]+\u{E000})*"): matched => context {
        let items = _parse-markers(matched.text)
        let all-bib-refs = query(std.cite).filter(r => str(r.key) in bib-data)
        let seen = ()
        for r in all-bib-refs {
          let k = str(r.key)
          if k not in seen { seen.push(k) }
        }
        // 判定当前 cite 所属列表：主列表 → gb7714<LSEP><key>；命名列表 → gb7714<LSEP><list><LSEP><key>
        let my-list = _active-list.at(here())
        let lbl-prefix = if my-list == none { "gb7714" + _LSEP } else { "gb7714" + _LSEP + my-list + _LSEP }
        // 命名列表用 print-bib 注册的消歧后缀；主列表用全局 _ay-data
        let suff-table = if my-list == none { _ay-data.cite-suffixes } else { _list-suffix-map.final().at(my-list, default: (:)) }
        // cite() 的 name-format 覆盖，否则用全局 cite-name-format
        let nf-ov = _cite-name-format-state.at(here())
        let eff-nf = if nf-ov != auto { nf-ov } else { cite-name-format-eff }
        if items.len() == 1 {
          let item = items.first()
          let k = seen.at(item.num - 1, default: "")
          let lbl = _bib-link(lbl-prefix + k, my-list, k, _ay-cite-label(k, nf: eff-nf, suffixes: suff-table))
          if item.supp != none { [(#lbl)#super[#item.supp]] } else { [(#lbl)] }
        } else {
          let labels = items.map(item => {
            let k = seen.at(item.num - 1, default: "")
            let lbl = _bib-link(lbl-prefix + k, my-list, k, _ay-cite-label(k, nf: eff-nf, suffixes: suff-table))
            if item.supp != none { lbl + [: #item.supp] } else { lbl }
          })
          [(#labels.join("; "))]
        }
      }
      _emit-body()
    } else {
      // ---- 顺序编码制引用 ----
      show ref: it => if str(it.target) in bib-data { std.cite(it.target, supplement: if it.supplement == auto { none } else { it.supplement }) } else { it }
      show std.cite: it => {
        let key = str(it.key)
        // 未在 bib-data 的 key 交还为 ref，触发 `label does not exist`（否则 std.cite 会报 "no bibliography"）
        if key not in bib-data { return std.ref(it.key) }
        let supp = _supp-to-str(it.supplement)
        context {
          let my-list = _active-list.at(here())
          let all-bib-refs = query(std.cite).filter(r => str(r.key) in bib-data and _active-list.at(r.location()) == my-list)
          let seen = ()
          for r in all-bib-refs {
            let k = str(r.key)
            if k not in seen { seen.push(k) }
          }
          let idx = seen.position(k => k == key)
          if idx == none { return it }
          let num = idx + 1
          // 主列表或命名列表，统一输出标记供 show regex 合并
          // 命名列表用纯数字 shortID 替代列表名，避免含点/横线的名称被断行
          let supp-part = if supp != none { _MS + supp } else { "" }
          if my-list == none {
            _M + str(num) + supp-part + _M
          } else {
            let sid = _list-ids.at(here()).at(my-list, default: my-list)
            _M + _ML + sid + _ML + str(num) + supp-part + _M
          }
        }
      }
      // 匹配相邻标记（主列表或命名列表），合并压缩后渲染
      show regex("\u{E000}[^\u{E000}]+\u{E000}(\\s*\u{E000}[^\u{E000}]+\u{E000})*"): matched => context {
        let items = _parse-markers(matched.text)
        let my-sid = items.first().at("list", default: none)  // shortID 或 none
        // shortID → 原始列表名（供构建标签和查询 _active-list）
        let id-map = _list-ids.final()
        let sid-to-label = (:)
        for (lbl, sid) in id-map { sid-to-label.insert(sid, lbl) }
        let my-list = if my-sid != none { sid-to-label.at(my-sid, default: my-sid) } else { none }

        // 构建 seen 数组：按引用顺序去重（对应 my-list）
        let all-bib-refs = query(std.cite).filter(r => str(r.key) in bib-data and _active-list.at(r.location()) == my-list)
        let seen = ()
        for r in all-bib-refs {
          let k = str(r.key)
          if k not in seen { seen.push(k) }
        }

        // 命名列表且 style = "author-year" → 渲染为著者-出版年制
        let named-ay = my-list != none and _list-style-map.final().at(my-list, default: "numeric") == "author-year"
        if named-ay {
          let list-suff = _list-suffix-map.final().at(my-list, default: (:))
          let nf-ov = _cite-name-format-state.at(here())
          let eff-nf = if nf-ov != auto { nf-ov } else { cite-name-format-eff }
          if items.len() == 1 {
            let item = items.first()
            let k = seen.at(item.num - 1, default: "")
            let lbl = _bib-link("gb7714" + _LSEP + my-list + _LSEP + k, my-list, k, _ay-cite-label(k, nf: eff-nf, suffixes: list-suff))
            if item.supp != none { [(#lbl)#super[#item.supp]] } else { [(#lbl)] }
          } else {
            let labels = items.map(item => {
              let k = seen.at(item.num - 1, default: "")
              let lbl = _bib-link("gb7714" + _LSEP + my-list + _LSEP + k, my-list, k, _ay-cite-label(k, nf: eff-nf, suffixes: list-suff))
              if item.supp != none { lbl + [: #item.supp] } else { lbl }
            })
            [(#labels.join("; "))]
          }
        } else {
          // 顺序编码制（主列表或命名列表 numeric）
          // link 目标：主列表用 gb7714<LSEP>key，命名列表用 gb7714<LSEP>list<LSEP>key
          // display: 显示文本，默认为 str(n)
          let _num-link(k, n, display: none) = {
            let txt = if display != none { display } else { str(n) }
            if my-list == none { _bib-link("gb7714" + _LSEP + k, none, k, txt) }
            else { _bib-link("gb7714" + _LSEP + my-list + _LSEP + k, my-list, k, txt) }
          }

          let sorted-items = items.sorted(key: item => item.num)
          let segments = ()
          let seg-s = none
          let seg-e = none
          for item in sorted-items {
            if item.supp != none {
              if seg-s != none { segments.push((seg-s, seg-e, none)); seg-s = none; seg-e = none }
              segments.push((item.num, item.num, item.supp))
            } else {
              if seg-s == none { seg-s = item.num; seg-e = item.num }
              else if item.num == seg-e + 1 { seg-e = item.num }
              else { segments.push((seg-s, seg-e, none)); seg-s = item.num; seg-e = item.num }
            }
          }
          if seg-s != none { segments.push((seg-s, seg-e, none)) }

          let parts = segments.map(seg => {
            let (s, e, supp) = seg
            let k = seen.at(s - 1, default: "")
            if supp != none {
              _num-link(k, s) + [:#supp]
            } else if s == e {
              _num-link(k, s)
            } else if e - s + 1 >= cite-compress-min {
              _num-link(k, s, display: str(s) + "-" + str(e))
            } else {
              range(s, e + 1).map(n => _num-link(seen.at(n - 1, default: ""), n)).join(",")
            }
          })
          let eff-super = {
            let ov = _cite-super-state.at(here())
            if ov != auto { ov } else { cite-super }
          }
          if items.len() == 1 and items.first().supp != none {
            let item = items.first()
            let k = seen.at(item.num - 1, default: "")
            if eff-super {
              super[\[#_num-link(k, item.num)\]#item.supp]
            } else {
              [\[#_num-link(k, item.num)\]#item.supp]
            }
          } else {
            if eff-super {
              super[\[#parts.join(",")\]]
            } else {
              [\[#parts.join(",")\]]
            }
          }
        }
      }
      _emit-body()
    }
  }

  // 直接渲染参考文献表内容（数据全部来自 read()，不经过 bibliography() 元素）
  let gb7714-bibliography = context _gb7714-show-bibliography(bib-data, bib-key-order, full, uppercase-name, show-missing-pub, et-al-min, et-al-use-first, show-url, show-doi, show-mark, show-medium, show-patent-country, short-journal, show-urldate, end-with-period, hyperlink, show-isbn, show-eprint, sentence-case-title, italic-journal, bold-journal-volume, italic-book-title, space-before-mark, space-before-pages, dash-in-pages, period-after-author, number-width, number-align, after-number-sep, item-sep, hanging, show-related, title, no-author, no-others, name-format, hyperlink-title, number-style, no-same-editor, style == "author-year", lang-order, hyphenate, sort-keys, back-ref, show-degree, [])

  /// 脚注式引用：在页下打印完整条目
  // 共享格式化函数
  let _fmt-one(entry, no-author: no-author, skip-year: false) = {
    _format-entry(entry, uppercase: uppercase-name, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: no-author, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: skip-year, show-degree: show-degree)
  }


  /// 获取 related 条目（如果有 lanversion 关联）
  let _get-related(entry) = {
    let rel = entry.fields.at("related", default: none)
    let rel-type = entry.fields.at("relatedtype", default: none)
    if rel != none and rel-type != none and lower(str(rel-type)) == "lanversion" {
      bib-data.at(str(rel), default: none)
    } else { none }
  }

  /// 著者-出版年制：格式化单条（Author, Year. rest）
  /// suffixes: 消歧后缀表覆盖（dict: key → "a"/"b"/...）。默认取全局 `_ay-data.cite-suffixes`；
  /// print-bib 等局部列表用自定义 sort-keys 时，传入其局部 `_compute-disambiguation` 结果，
  /// 保证渲染出的 a/b/c 与列表视觉顺序一致。
  let _fmt-one-ay(entry, suffix-key: none, no-author: no-author, suffixes: none) = {
    let author = _get-main-author(entry, uppercase: uppercase-name, et-al-min: et-al-min, et-al-use-first: et-al-use-first, no-author: no-author, no-others: no-others, name-format: name-format)
    let year = _format-year(entry)
    let suffix-table = if suffixes != none { suffixes } else { _ay-data.cite-suffixes }
    let dsuffix = if suffix-key != none { suffix-table.at(suffix-key, default: "") } else { "" }
    if year != none { year = year + dsuffix }
    let author-year = if author != none and year != none { author + ", " + year }
    else if author != none { author }
    else if year != none { year }
    else { "" }
    let rest = _format-entry(entry, uppercase: uppercase-name, show-missing-pub: show-missing-pub, et-al-min: et-al-min, et-al-use-first: et-al-use-first, show-url: show-url, show-doi: show-doi, show-mark: show-mark, show-medium: show-medium, show-patent-country: show-patent-country, short-journal: short-journal, show-urldate: show-urldate, hyperlink: hyperlink, show-isbn: show-isbn, show-eprint: show-eprint, sentence-case-title: sentence-case-title, italic-journal: italic-journal, bold-journal-volume: bold-journal-volume, italic-book-title: italic-book-title, space-before-mark: space-before-mark, space-before-pages: space-before-pages, dash-in-pages: dash-in-pages, period-after-author: period-after-author, no-author: true, no-others: no-others, name-format: name-format, hyperlink-title: hyperlink-title, no-same-editor: no-same-editor, skip-year: true, skip-author: true, show-degree: show-degree)
    [#author-year. #rest]
  }

  /**
  = `cite` — 手动引用 <cite-fn>

  此函数除了能实现 ```typ @key``` 语法下的全部功能，如合并多条、附加 `supplement` 页码/补充、临时覆盖 `bib-label` 或 `super`。参数 `refs` 是一个 content 块，内部可写任意数量的 ```typ @key``` 引用；函数会递归提取其中的 ref 元素。

  ```typ
  #cite[@zhang2020]                                           // 单条
  #cite[@zhang2020@li2021] 或 #cite[@zhang2020]#cite[@li2021] // 多条合并，两种写法等价
  #cite(supplement: [260])[@zhang2020]                        // 带页码
  #cite(supplement: [1--3])[@li2021@zhang2020]                // 补充信息作用于末位，即@zhang2020
  #cite(supplement: [第二章])[@li2021]#cite(supplement: [1--3])[@zhang2020] // 带补充信息的多条合并
  #cite(bib-label: "appendix")[@zhang2020]                    // 临时归属到其他文献列表
  #cite(super: false)[@zhang2020]                             // 不显示为上标
  #cite(footnote: true)[@zhang2020]                           // 在脚注里打印完整条目（双语时含关联条目）
  ```
  **/
  let cite(
    bib-label:   auto,            /// <- auto | string | none
      /// 临时把这些引用归属到指定文献列表；`auto` 沿用当前 `set-bib-label` 作用域。|
    refs,                         /// <- content <required>
      /// 包含一个或多个 ```typ @key``` 引用的内容块。|
    supplement:  none,            /// <- none | content
      /// 附加页码或补充说明，作用于末位引用。|
    super:       auto,            /// <- auto | boolean
      /// #arg-ref("gb7714", "cite-super")|
    name-format: auto,            /// <- auto | "uppercase" | "lowercase" | "given-ahead" | "fullname" | "pinyin" | "quanpin"
      /// #arg-ref("gb7714", "cite-name-format")|
    footnote:    false,           /// <- boolean
      /// `true`：在脚注里打印每条 ref 对应的完整条目（含双语关联条目），不再生成正文引用标记；其它参数（`bib-label` / `super` / `name-format` / `supplement`）此时被忽略。|
    related-indent: auto,         /// <- auto | none | length | content
      /// 脚注模式下双语关联条目第二行前的缩进；`auto` 取 `h(1em)`，`none` 无缩进。|
  ) = {
    let ref-elems = _extract-refs(refs)
    if ref-elems.len() == 0 { return }
    if footnote {
      let ind = if related-indent == auto { h(1em) }
        else if related-indent != none { related-indent }
        else { []}
      for r in ref-elems {
        let k = str(r.target)
        let entry = bib-data.at(k, default: none)
        // key 不在 bib-data 时原样吐出 ref，交给 Typst 报 `label <k> does not exist`
        if entry == none { r; continue }
        let skip-y = style == "author-year"
        let ends-abbrev = _content-ends-with-abbrev-period(entry, skip-year: skip-y, show-url: show-url, show-doi: show-doi, show-isbn: show-isbn, show-eprint: show-eprint)
        let suf = if end-with-period and not ends-abbrev { "." } else { "" }
        let fmt = if skip-y { _fmt-one-ay(entry, suffix-key: k) } else { _fmt-one(entry) }
        let rel = _get-related(entry)
        if rel != none {
          let rel-key = str(entry.fields.at("related", default: ""))
          let rel-ends = _content-ends-with-abbrev-period(rel, skip-year: skip-y, show-url: show-url, show-doi: show-doi, show-isbn: show-isbn, show-eprint: show-eprint)
          let rel-suf = if end-with-period and not rel-ends { "." } else { "" }
          let rel-fmt = if skip-y { _fmt-one-ay(rel, suffix-key: rel-key) } else { _fmt-one(rel) }
          std.footnote[#fmt#suf#linebreak()#ind#rel-fmt#rel-suf]
        } else {
          std.footnote[#fmt#suf]
        }
      }
      return
    }
    let cites = for (i, r) in ref-elems.enumerate() {
      let supp = if i == ref-elems.len() - 1 { supplement } else { none }
      // 未在 bib-data 的 key 原样吐出 ref，交给 Typst 报 `label does not exist`
      if str(r.target) not in bib-data { r }
      else { std.cite(r.target, supplement: supp) }
    }
    let with-list = if bib-label == auto {
      cites
    } else {
      context {
        let prev = _active-list.get()
        [#_active-list.update(bib-label)#cites#_active-list.update(prev)]
      }
    }
    let with-super = if super == auto {
      with-list
    } else {
      [#_cite-super-state.update(super)#with-list#_cite-super-state.update(auto)]
    }
    if name-format == auto {
      with-super
    } else {
      [#_cite-name-format-state.update(name-format)#with-super#_cite-name-format-state.update(auto)]
    }
  }

  let global-style = style  // 捕获外层 style 避免被参数遮挡
  // 捕获全局默认值，供 print-bib 等局部函数的 auto 参数回退使用
  let _g-hanging = hanging
  let _g-hyphenate = hyphenate
  let _g-item-sep = item-sep
  let _g-after-number-sep = after-number-sep
  let _g-number-style = number-style
  let _g-number-align = number-align
  let _g-number-width = number-width
  let _g-bold-journal-volume = bold-journal-volume
  let _g-dash-in-pages = dash-in-pages
  let _g-end-with-period = end-with-period
  let _g-et-al-min = et-al-min
  let _g-et-al-use-first = et-al-use-first
  let _g-hyperlink = hyperlink
  let _g-italic-book-title = italic-book-title
  let _g-italic-journal = italic-journal
  let _g-lang-order = lang-order
  let _g-name-format = name-format
  let _g-no-author = no-author
  let _g-no-others = no-others
  let _g-no-same-editor = no-same-editor
  let _g-period-after-author = period-after-author
  let _g-sentence-case-title = sentence-case-title
  let _g-short-journal = short-journal
  let _g-show-doi = show-doi
  let _g-show-eprint = show-eprint
  let _g-show-isbn = show-isbn
  let _g-show-mark = show-mark
  let _g-show-medium = show-medium
  let _g-show-missing-pub = show-missing-pub
  let _g-show-patent-country = show-patent-country
  let _g-show-related = show-related
  let _g-show-url = show-url
  let _g-show-urldate = show-urldate
  let _g-space-before-mark = space-before-mark
  let _g-space-before-pages = space-before-pages
  let _g-hyperlink-title = hyperlink-title
  let _g-back-ref = back-ref
  let _g-show-degree = show-degree

  /**
  = `print-bib` — 按条件打印参考文献（列表） <print-bib>

  支持按类型、关键词、自定义函数过滤，
  以及多种排序和布局覆盖。可打印多个独立分区，每个分区有独立标题和编号。

  ```typ
  // 打印主列表中所有图书
  #print-bib(type: "M", title: [参考图书])

  // 打印附录 bib 文件中被引用的所有标准（网络版除外）
  #print-bib(
    type: "S", // 打印所有文献标识为 S 的文献
    bib-file: "appx", // 需要 gb7714("appx": read("refs.bib")) 以提供可用文件标签
    full: true, // 打印 appx 中的全部文献
    filter: e => e.fields.at("url", default: none) == none, // 打印所有不含 URL 的文献
    title: [#heading(level: 2)[引用标准]], // 此列表的标题级别为二级，显示为“引用标准”
  )

  // 打印命名列表（配合 set-bib-label 使用）
  #print-bib(label: "sec2", title: [第二节参考文献])
  ```
  **/
  let print-bib(
    // ── 过滤 ──
    bib-file:      none,   /// <- none | string
      /// 仅打印指定文件标签对应的 `.bib` 文件中的条目。|
      /// 文件标签在 `gb7714()` 调用时确定，按字典形式传入，
      /// 如：
      /// ```typ
      /// #let (init-gb7714, ..) = gb7714(
      ///   "frontmatter": read("refs-1.bib"),
      ///   "appx": read("fefs-2.bib"),
      ///   ..
      /// )
      /// ```
      /// |
    entrytype:     none,   /// <- none | string | array
      /// 按实际 `entrytype` 过滤，如 `"book"`、`("book", "incollection")`。|
    filter:        none,   /// <- none | function
      /// 自定义过滤函数 `entry => bool`，可访问条目所有字段。|
    full:          false,  /// <- boolean
      /// - `true`：除已引用条目外，追加显示其他所有符合筛选条件的条目。|
    keys:          none,   /// <- none | content
      /// 指定要打印的条目键值（列表），此时忽略其他过滤条件；\|
      /// 应传入一个内容块，内部用 ```typ @key``` 引用：```typ keys: [@zhang2020@li2021]```；\
      /// 函数会从块里递归提取所有引用元素并打印。|
    keyword:       none,   /// <- none | string
      /// 对条目的 `keywords` 字段做*大小写敏感*的子串包含匹配，仅打印含该关键词的条目；\
      /// 如需要更精准灵活的正则匹配需使用 `filter` 自行构建。|
    type:          none,   /// <- none | string | array
      /// 按文献标识过滤，如 `"M"`、`"J"`、`("C", "G")`；\|
      /// 匹配逻辑：条目的标识等于该值，且带有载体不影响匹配，如：`"EB"` 可以匹配到 EB/OL。|
    // ── 标题与标签 ──
    label:         none,   /// <- none | string
      /// 打印指定标签的参考文献列表。
      /// - `none`：打印主列表；
      /// - `"xxx"`：打印 ```typ #set-bib-label("xxx")``` 归属的引用：|
      /// 每条条目自动生成 `<gb7714-xxx-key>` 标签供 `#cite` 跳转。|
    title:         none,   /// <- none | content
      /// 列表标题；`none` 不输出标题。|
    // ── 排序 ──
    sort-keys:     none,   /// <- none | content
      /// 自定义排序：传入内容块，内部用 ```typ @key``` 引用指定的条目，按书写顺序优先排列，其余追加，例：```typ sort-keys: [@key1@key2]```。|
    sorting:       auto,   /// <- auto | string
      /// 排序方式。`auto` 时著者-出版年制默认 `"nyt"`，顺序编码制默认 `"none"`。|
      /// 可用值：`"none"` 引用/bib 顺序；`"nyt"` 姓名→年→标题；|
      /// `"ynt"` 年升序→姓名；`"yntd"` 年降序→姓名。|
    // ── 样式覆盖（auto 时跟随全局）──
    bold-journal-volume: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "bold-journal-volume")。|
    dash-in-pages: auto,   /// <- auto | string
      /// #arg-ref("gb7714", "dash-in-pages")。|
    end-with-period: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "end-with-period")。|
    et-al-min:     auto,   /// <- auto | integer
      /// #arg-ref("gb7714", "et-al-min")。|
    et-al-use-first: auto, /// <- auto | integer
      /// #arg-ref("gb7714", "et-al-use-first")。|
    hanging:       auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "hanging")。|
    hyperlink:     auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "hyperlink")。|
    hyphenate:     auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "hyphenate")。|
    italic-book-title: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "italic-book-title")。|
    italic-journal: auto,  /// <- auto | boolean
      /// #arg-ref("gb7714", "italic-journal")。|
    item-sep:      auto,   /// <- auto | length
      /// #arg-ref("gb7714", "item-sep")。|
    after-number-sep:     auto,   /// <- auto | length
      /// #arg-ref("gb7714", "after-number-sep")。|
    number-style: auto, /// <- auto | string
      /// #arg-ref("gb7714", "number-style")。|
    lang-order:    auto,   /// <- auto | array
      /// #arg-ref("gb7714", "lang-order")。|
    name-format:   auto,   /// <- auto | string
      /// #arg-ref("gb7714", "name-format")。|
    no-author:     auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "no-author")。|
    no-others:     auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "no-others")。|
    no-same-editor: auto,  /// <- auto | boolean
      /// #arg-ref("gb7714", "no-same-editor")。|
    number-align:  auto,   /// <- auto | string
      /// #arg-ref("gb7714", "number-align")。|
    number-width:  auto,   /// <- auto | length
      /// #arg-ref("gb7714", "number-width")。|
    period-after-author: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "period-after-author")。|
    related-indent: none,  /// <- none | length | content
      /// 双语关联条目（related + `lanversion`）第二行前的缩进。`none` 无缩进。|
    sentence-case-title: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "sentence-case-title")。|
    short-journal: auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "short-journal")。|
    show-doi:      auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-doi")。|
    show-eprint:   auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-eprint")。|
    show-isbn:     auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-isbn")。|
    show-mark:     auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-mark")。|
    show-medium:   auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-medium")。|
    show-missing-pub: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "show-missing-pub")。|
    show-patent-country: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "show-patent-country")。|
    show-related:  auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-related")。|
    show-url:      auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-url")。|
    show-urldate:  auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-urldate")。|
    space-before-mark: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "space-before-mark")。|
    space-before-pages: auto, /// <- auto | boolean
      /// #arg-ref("gb7714", "space-before-pages")。|
    style:         none,   /// <- none | string
      /// #arg-ref("gb7714", "style")。|
    hyperlink-title:    auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "hyperlink-title")。|
    back-ref:      auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "back-ref")。|
    show-degree:   auto,   /// <- auto | boolean
      /// #arg-ref("gb7714", "show-degree")，仅临时覆盖本次 `print-bib` 调用，不影响主参考文献表与其它命名列表。|
  ) = context {
    let effective-style = if style != none { style } else { global-style }
    let list-label = label  // 避免与 Typst 内置 label() 冲突
    // keys / sort-keys 校验：原样吐出不在 bib-data 的 ref，触发 Typst `label does not exist` 错误
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
    // sort-keys 统一为内容块 `[@key1@key2 ...]`，内部归一化为字符串数组
    let sort-keys = if sort-keys == none { none }
      else { _extract-refs(sort-keys).map(r => str(r.target)) }
    // 把本次 print-bib 使用的 style 写入状态，供 cite show rule 决定命名列表的渲染格式
    if list-label != none {
      _list-style-map.update(m => { m.insert(list-label, effective-style); m })
    }
    // 获取当前列表的 refs（按引用顺序）
    let all-refs = query(ref).filter(r => _active-list.at(r.location()) == list-label)
    let cited-keys = ()
    for r in all-refs {
      let key = str(r.target)
      if key not in cited-keys and key in bib-data { cited-keys.push(key) }
    }
    let src-keys = if keys != none {
      // 从内容块中递归提取 ref 元素，按书写顺序转成 key 列表
      _extract-refs(keys).map(r => str(r.target)).filter(k => k in bib-data)
    }
    else if full {
      let ks = cited-keys
      for key in bib-key-order { if key not in ks { ks.push(key) } }
      ks
    } else { cited-keys }

    // 按 bib 文件过滤
    let src-keys = if bib-file != none {
      let file-keys = bib-file-keys.at(bib-file, default: ())
      src-keys.filter(k => k in file-keys)
    } else { src-keys }

    // 自定义类型名 → mark 标识映射（citegeist 中为 unknown，靠此映射匹配）
    let _type-alias = (
      newspaper: "N", standard: "S", archive: "A",
      map: "CM", database: "DB", legislation: "A",
    )

    // 过滤
    // type:      按 GB/T 7714 文献标识（如 "M"、"J"）或别名（如 "newspaper"）过滤，使用广义类型
    // entrytype: 按 Hayagriva 原始 entry type（如 "book"、"article"）过滤，精确匹配
    let filtered = src-keys.map(k => (k, bib-data.at(k))).filter(pair => {
      let entry = pair.at(1)
      if type != none {
        // (v,).flatten()：v 为字符串 → (v,)，v 为数组 → 展开为数组
        let types = (type,).flatten()
        let entry-mark = _get-type-mark(entry)
        let matched = types.any(t => {
          let alias-mark = _type-alias.at(t, default: none)
          // 精确匹配 或 "EB" 匹配 "EB/OL"（mark 字段显式含载体标识时）
          (entry-mark == t or entry-mark.starts-with(t + "/")
          or (alias-mark != none and (entry-mark == alias-mark or entry-mark.starts-with(alias-mark + "/"))))
        })
        if not matched { return false }
      }
      if entrytype != none {
        let entrytypes = (entrytype,).flatten()
        if entry.entry_type not in entrytypes { return false }
      }
      if keyword != none {
        let kw = entry.fields.at("keywords", default: none)
        if kw == none or not str(kw).contains(keyword) { return false }
      }
      if filter != none and not filter(entry) { return false }
      true
    })

    // 排序：auto 时著者-出版年制默认 nyt，顺序编码制默认 none
    let eff-sorting = if sorting != auto { sorting } else if effective-style == "author-year" { "nyt" } else { "none" }

    // 解析可覆盖的样式参数：auto 时回退到全局默认
    let eff-bold-journal-volume = if bold-journal-volume != auto { bold-journal-volume } else { _g-bold-journal-volume }
    let eff-dash-in-pages       = if dash-in-pages       != auto { dash-in-pages }       else { _g-dash-in-pages }
    let eff-end-with-period     = if end-with-period     != auto { end-with-period }     else { _g-end-with-period }
    let eff-et-al-min           = if et-al-min           != auto { et-al-min }           else { _g-et-al-min }
    let eff-et-al-use-first     = if et-al-use-first     != auto { et-al-use-first }     else { _g-et-al-use-first }
    let eff-hyperlink           = if hyperlink           != auto { hyperlink }           else { _g-hyperlink }
    let eff-italic-book-title   = if italic-book-title   != auto { italic-book-title }   else { _g-italic-book-title }
    let eff-italic-journal      = if italic-journal      != auto { italic-journal }      else { _g-italic-journal }
    let eff-lang-order          = if lang-order          != auto { lang-order }          else { _g-lang-order }
    let eff-name-format         = if name-format         != auto { name-format }         else { _g-name-format }
    let eff-no-author           = if no-author           != auto { no-author }           else { _g-no-author }
    let eff-no-others           = if no-others           != auto { no-others }           else { _g-no-others }
    let eff-no-same-editor      = if no-same-editor      != auto { no-same-editor }      else { _g-no-same-editor }
    let eff-period-after-author = if period-after-author != auto { period-after-author } else { _g-period-after-author }
    let eff-sentence-case-title = if sentence-case-title != auto { sentence-case-title } else { _g-sentence-case-title }
    let eff-short-journal       = if short-journal       != auto { short-journal }       else { _g-short-journal }
    let eff-show-doi            = if show-doi            != auto { show-doi }            else { _g-show-doi }
    let eff-show-eprint         = if show-eprint         != auto { show-eprint }         else { _g-show-eprint }
    let eff-show-isbn           = if show-isbn           != auto { show-isbn }           else { _g-show-isbn }
    let eff-show-mark           = if show-mark           != auto { show-mark }           else { _g-show-mark }
    let eff-show-medium         = if show-medium         != auto { show-medium }         else { _g-show-medium }
    let eff-show-missing-pub    = if show-missing-pub    != auto { show-missing-pub }    else { _g-show-missing-pub }
    let eff-show-patent-country = if show-patent-country != auto { show-patent-country } else { _g-show-patent-country }
    let eff-show-related        = if show-related        != auto { show-related }        else { _g-show-related }
    let eff-show-url            = if show-url            != auto { show-url }            else { _g-show-url }
    let eff-show-urldate        = if show-urldate        != auto { show-urldate }        else { _g-show-urldate }
    let eff-space-before-mark   = if space-before-mark   != auto { space-before-mark }   else { _g-space-before-mark }
    let eff-space-before-pages  = if space-before-pages  != auto { space-before-pages }  else { _g-space-before-pages }
    let eff-hyperlink-title          = if hyperlink-title          != auto { hyperlink-title }          else { _g-hyperlink-title }
    let eff-back-ref                 = if back-ref                 != auto { back-ref }                 else { _g-back-ref }
    let eff-show-degree              = if show-degree              != auto { show-degree }              else { _g-show-degree }
    let eff-uppercase-name      = eff-name-format not in ("lowercase", "quanpin", "fullname")

    // 本局部列表的消歧后缀（scope-keys 限定到 filtered，未打印的 bib 条目不参与消歧）
    let _dis = _compute-disambiguation(bib-data, cite-et-al-min: cite-et-al-min, cite-et-al-use-first: cite-et-al-use-first, uppercase: eff-uppercase-name, name-format: eff-name-format, sort-keys: sort-keys, scope-keys: filtered.map(p => p.at(0)))
    // 把消歧后缀写入状态，供 cite show rule 渲染命名列表 cite 标签时回看
    if list-label != none {
      _list-suffix-map.update(m => { m.insert(list-label, _dis.cite-suffixes); m })
    }

    if eff-sorting == "nyt" {
      // 语言→姓名→年[消歧后缀]→标题（与 biblatex gb7714-2015 一致）
      filtered = filtered.sorted(key: pair => {
        let k = pair.at(0)
        let e = pair.at(1)
        let suffix = _dis.cite-suffixes.at(k, default: "")
        _lang-sort-key(e, lang-order: eff-lang-order) + _sort-author(e, uppercase: eff-uppercase-name) + _sort-year(e) + suffix + lower(str(e.fields.at("title", default: "")))
      })
    } else if eff-sorting == "ynt" {
      // 语言→年升序→姓名→标题
      filtered = filtered.sorted(key: pair => {
        let e = pair.at(1)
        _lang-sort-key(e, lang-order: eff-lang-order) + _sort-year(e) + _sort-author(e, uppercase: eff-uppercase-name) + str(e.fields.at("title", default: ""))
      })
    } else if eff-sorting == "yntd" {
      // 语言→年降序→姓名→标题
      filtered = filtered.sorted(key: pair => {
        let e = pair.at(1)
        let yr = 9999 - int(_sort-year(e))
        _lang-sort-key(e, lang-order: eff-lang-order) + str(yr) + _sort-author(e, uppercase: eff-uppercase-name) + str(e.fields.at("title", default: ""))
      })
    }
    // eff-sorting == "none" 保持原序

    // 自定义排序：覆盖上述排序结果
    if sort-keys != none {
      let in-order = sort-keys.filter(k => filtered.map(p => p.at(0)).contains(k))
      let rest = filtered.filter(p => p.at(0) not in sort-keys)
      filtered = in-order.map(k => filtered.find(p => p.at(0) == k)) + rest
    }

    if filtered.len() == 0 { return }

    if title != none {
      heading(level: 1, numbering: none, title)
    }

    // 布局参数覆盖
    let eff-hanging    = if hanging      != auto { hanging }      else { _g-hanging }
    let eff-lsep       = if after-number-sep    != auto { after-number-sep }    else { _g-after-number-sep }
    let eff-isep       = if item-sep     != auto { item-sep }     else { _g-item-sep }
    let eff-num-align  = if number-align != auto { number-align } else { _g-number-align }
    let eff-lbl-style  = if number-style != auto { number-style } else { _g-number-style }
    let eff-hyphenate  = if hyphenate    != auto { hyphenate }    else { _g-hyphenate }

    // 用 eff-* 值构建本列表的格式化函数（取代闭包捕获的全局 _fmt-one / _fmt-one-ay）
    let _fmt-p(entry, no-author: eff-no-author, skip-year: false) = {
      _format-entry(entry, uppercase: eff-uppercase-name, show-missing-pub: eff-show-missing-pub, et-al-min: eff-et-al-min, et-al-use-first: eff-et-al-use-first, show-url: eff-show-url, show-doi: eff-show-doi, show-mark: eff-show-mark, show-medium: eff-show-medium, show-patent-country: eff-show-patent-country, short-journal: eff-short-journal, show-urldate: eff-show-urldate, hyperlink: eff-hyperlink, show-isbn: eff-show-isbn, show-eprint: eff-show-eprint, sentence-case-title: eff-sentence-case-title, italic-journal: eff-italic-journal, bold-journal-volume: eff-bold-journal-volume, italic-book-title: eff-italic-book-title, space-before-mark: eff-space-before-mark, space-before-pages: eff-space-before-pages, dash-in-pages: eff-dash-in-pages, period-after-author: eff-period-after-author, no-author: no-author, no-others: eff-no-others, name-format: eff-name-format, hyperlink-title: eff-hyperlink-title, no-same-editor: eff-no-same-editor, skip-year: skip-year, show-degree: eff-show-degree)
    }
    let _fmt-ay-p(entry, suffix-key: none, no-author: eff-no-author, suffixes: none) = {
      let author = _get-main-author(entry, uppercase: eff-uppercase-name, et-al-min: eff-et-al-min, et-al-use-first: eff-et-al-use-first, no-author: no-author, no-others: eff-no-others, name-format: eff-name-format)
      let year = _format-year(entry)
      let suffix-table = if suffixes != none { suffixes } else { _dis.cite-suffixes }
      let dsuffix = if suffix-key != none { suffix-table.at(suffix-key, default: "") } else { "" }
      if year != none { year = year + dsuffix }
      let author-year = if author != none and year != none { author + ", " + year }
      else if author != none { author }
      else if year != none { year }
      else { "" }
      let rest = _format-entry(entry, uppercase: eff-uppercase-name, show-missing-pub: eff-show-missing-pub, et-al-min: eff-et-al-min, et-al-use-first: eff-et-al-use-first, show-url: eff-show-url, show-doi: eff-show-doi, show-mark: eff-show-mark, show-medium: eff-show-medium, show-patent-country: eff-show-patent-country, short-journal: eff-short-journal, show-urldate: eff-show-urldate, hyperlink: eff-hyperlink, show-isbn: eff-show-isbn, show-eprint: eff-show-eprint, sentence-case-title: eff-sentence-case-title, italic-journal: eff-italic-journal, bold-journal-volume: eff-bold-journal-volume, italic-book-title: eff-italic-book-title, space-before-mark: eff-space-before-mark, space-before-pages: eff-space-before-pages, dash-in-pages: eff-dash-in-pages, period-after-author: eff-period-after-author, no-author: true, no-others: eff-no-others, name-format: eff-name-format, hyperlink-title: eff-hyperlink-title, no-same-editor: eff-no-same-editor, skip-year: true, skip-author: true, show-degree: eff-show-degree)
      [#author-year. #rest]
    }

    // 编号标签格式化（与主参考文献表一致，支持本次覆盖）
    let _plabel(num) = {
      if eff-lbl-style == "paren" { "(" + num + ")" }
      else if eff-lbl-style == "dot" { num + "." }
      else if eff-lbl-style == "plain" { num }
      else if eff-lbl-style == "fullwidth-bracket" { "〔" + num + "〕" }
      else if eff-lbl-style == "fullwidth-paren" { "（" + num + "）" }
      else if eff-lbl-style == "circled" { _circled-num(int(num)) }
      else if eff-lbl-style == "quan" { _quan-fn(int(num)) }
      else if eff-lbl-style == "none" { [] }
      else { "[" + num + "]" }
    }

    // 计算编号列宽（与主参考文献表逻辑一致）
    let eff-num-width = if eff-lbl-style == "none" { 0pt }
    else if number-width != auto { number-width }
    else if _g-number-width != auto { _g-number-width }
    else { measure(_plabel(str(filtered.len()))).width }

    let lbl-align = if eff-num-align == "left" { left }
                    else if eff-num-align == "center" { center }
                    else { right }
    let blk-extra = if eff-isep != auto { (spacing: eff-isep) } else { (:) }

    for (i, pair) in filtered.enumerate() {
      let key = pair.at(0)
      let entry = pair.at(1)
      let rel = if eff-show-related { _get-related(entry) } else { none }
      let skip-y = effective-style == "author-year"
      let ends-abbrev = _content-ends-with-abbrev-period(entry, skip-year: skip-y, show-url: eff-show-url, show-doi: eff-show-doi, show-isbn: eff-show-isbn, show-eprint: eff-show-eprint)
      let suffix = if eff-end-with-period and not ends-abbrev { "." } else { "" }
      let rel-ends-abbrev = if rel != none { _content-ends-with-abbrev-period(rel, skip-year: skip-y, show-url: eff-show-url, show-doi: eff-show-doi, show-isbn: eff-show-isbn, show-eprint: eff-show-eprint) } else { false }
      let rel-suffix = if eff-end-with-period and not rel-ends-abbrev { "." } else { "" }

      // 条目打上 <gb7714-...-key> 标签供 cite 跳转。_emit-bib-label 用共享 state 防止 #bibliography 与 print-bib 对同一个 key 双重渲染时重复报错。
      let entry-label-tag = _emit-bib-label(key, list-label: list-label)

      let _entry-lang = _detect-lang(entry)
      let _wrap(body) = if _entry-lang not in ("zh", "ja", "ko") { text(lang: _entry-lang, hyphenate: eff-hyphenate, body) } else { body }

      if effective-style == "author-year" {
        // 著者-出版年制：无编号，悬挂缩进
        let formatted = _fmt-ay-p(entry, suffix-key: key, suffixes: _dis.cite-suffixes)
        let rel-ind = if related-indent != none { related-indent } else { [] }
        let _inner = {
          entry-label-tag
          set par(hanging-indent: if eff-hanging { 2em } else { 0em }, first-line-indent: 0em)
          [#formatted#suffix]
          if rel != none {
            let rel-key = str(entry.fields.at("related", default: ""))
            parbreak()
            rel-ind
            [#_fmt-ay-p(rel, suffix-key: rel-key, suffixes: _dis.cite-suffixes)#rel-suffix]
          }
        }
        block(..blk-extra, _wrap(_inner))
      } else if eff-lbl-style == "none" {
        // 无编号
        let formatted = _fmt-p(entry)
        let rel-ind = if related-indent != none { related-indent } else { [] }
        let _inner = {
          entry-label-tag
          set par(hanging-indent: if eff-hanging { 2em } else { 0em }, first-line-indent: 0em)
          [#formatted#suffix]
          if rel != none { parbreak(); rel-ind; [#_fmt-p(rel)#rel-suffix] }
        }
        block(..blk-extra, _wrap(_inner))
      } else if eff-hanging {
        // 顺序编码制 + 悬挂（grid 对齐，与主参考文献表一致）
        let formatted = _fmt-p(entry)
        let lbl = _plabel(str(i + 1))
        // back-ref：编号回链到当前命名列表中首次引用该 key 的位置
        if eff-back-ref {
          let cites = query(std.cite).filter(c =>
            str(c.key) == key and _active-list.at(c.location()) == list-label
          )
          if cites.len() > 0 { lbl = link(cites.first().location(), lbl) }
        }
        let rel-ind = if related-indent != none { related-indent } else { [] }
        let rel-content = if rel != none { [#rel-ind#_fmt-p(rel)#rel-suffix] } else { none }
        let _inner = {
          entry-label-tag
          grid(
            columns: (eff-num-width, 1fr),
            column-gutter: eff-lsep,
            row-gutter: par.leading,
            align(lbl-align, lbl),
            [#formatted#suffix],
            ..if rel-content != none { ([], rel-content) } else { () },
          )
        }
        block(..blk-extra, _wrap(_inner))
      } else {
        // 顺序编码制 + 非悬挂（行内编号）
        let formatted = _fmt-p(entry)
        let lbl = _plabel(str(i + 1))
        if eff-back-ref {
          let cites = query(std.cite).filter(c =>
            str(c.key) == key and _active-list.at(c.location()) == list-label
          )
          if cites.len() > 0 { lbl = link(cites.first().location(), lbl) }
        }
        let rel-ind = if related-indent != none { related-indent } else { h(measure(lbl).width + eff-lsep) }
        let _inner = {
          entry-label-tag
          set par(first-line-indent: 0pt)
          [#lbl#h(eff-lsep)#formatted#suffix]
          if rel != none { linebreak(); rel-ind; [#_fmt-p(rel)#rel-suffix] }
        }
        block(..blk-extra, _wrap(_inner))
      }
    }
  }

  (
    init-gb7714: init-gb7714,
    // 兼容别名
    bibliography: gb7714-bibliography,
    "gb7714-bibliography": gb7714-bibliography,
    "print-bib": print-bib,
    cite: cite,
    "set-bib-label": set-bib-label,
  )
}
