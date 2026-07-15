//! param: latex-strict-char
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "latex-strict-char", controls: "`.bib` 字段里遇到*未转义的 LaTeX 特殊字符*时的行为。",
  expect: [管的是 `&` `_` `#` `%` `^` 五个裸特殊字符，以及*未配对*的 `\{` / `\}`。
    `true`（缺省）：严格——渲染期*报错*；这些字符在 LaTeX 文本模式下须写作 `\&` / `\_` / `\#` / `\%` /
    `\textasciicircum`，未配对花括号须改用 `\textbraceleft` / `\textbraceright`。
    `false`：宽松——裸特殊字符按*字面*输出、未配对 `\{` / `\}` 亦容忍（适合来不及规范化的旧库）。
    与 `latex-strict-command` *各自独立*。
    *不受本开关影响*：verbatim 字段（`url` / `doi` / `eprint` 里的 `&` `_` 恒原样）、数学环境
    （`$x_i$` 里的 `_` `^` 合法）、未配对 `$`（恒报错）、裸 `{` `}`（恒剥除为分组符）。
    *仅全局生效*。⚠️ `true` 那档报错停编译，在 `contract/panic/` 验证。])
#let clean = bytes("@book{lc-ok, author={甲}, title={规范转义 \\& \\_ \\# \\% 与数学 $x_i^2$}, url={https://e.com/a_b&c=1}, address={北京}, publisher={社}, year={2020}, langid={chinese}}")
#let bare = bytes("@book{lc-bare, author={乙}, title={裸特殊字符 A & B _ C # D % E}, address={北京}, publisher={社}, year={2020}, langid={chinese}}")
#case("true（缺省）· 转义规范 → 照常渲染（verbatim 字段里的 & _ 恒原样）", gb7714.with(), bib: clean, full: true)
#case("false · 转义规范 → 与 true 完全相同", gb7714.with(latex-strict-char: false), bib: clean, full: true)
#case("false · 裸特殊字符 → 按字面输出", gb7714.with(latex-strict-char: false), bib: bare, full: true)
#case("false · 内置 LaTeX 语料全量", gb7714.with(latex-strict-char: false, latex-strict-command: false), bib: LATEX, full: true)
