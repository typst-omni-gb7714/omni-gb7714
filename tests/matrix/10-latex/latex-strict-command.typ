//! param: latex-strict-command
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "latex-strict-command", controls: "`.bib` 字段里遇到*未定义 LaTeX 命令*时的行为。",
  expect: [`true`（缺省）：严格——渲染期*报错*，便于及早发现拼写错 / 漏写的命令。
    `false`：宽松——静默丢弃该命令、保留其后内容、继续渲染。
    典型的未定义命令：拼写错的 `\foobar`、`\noopsort{zzz}` 一类 bst 时代的排序代理、
    以及 CJK 紧贴吞掉命令名的 `\textbf 中文`（词法器把 `\textbf中文` 整体当成一个命令名）。
    与 `latex-strict-char` *各自独立*。verbatim 字段（`url` / `doi` / `eprint`）不做 LaTeX 转换、不受影响。
    *仅全局生效*（没有逐表 / 逐次覆盖）。
    ⚠️ `true` 遇到未定义命令就*报错停编译*，没法与 `false` 的宽松渲染并置于同一文档——
    报错那档在 `contract/panic/` 验证。])
#let clean = bytes("@book{lx-ok, author={甲}, title={定义良好的命令 \\textit{斜体} 与 \\textbf{粗体}}, address={北京}, publisher={社}, year={2020}, langid={chinese}}")
#let bad = bytes("@book{lx-undef, author={乙}, title={拼错的命令 \\foobar{内容} 后续文字}, address={北京}, publisher={社}, year={2020}, langid={chinese}}
@book{lx-noopsort, author={\\noopsort{zzz}丙}, title={noopsort 排序代理}, address={北京}, publisher={社}, year={2020}, langid={chinese}}
@book{lx-cjk-tight, author={丁}, title={CJK 紧贴 \\textbf 中文 命令}, address={北京}, publisher={社}, year={2020}, langid={chinese}}")
#case("true（缺省）· 命令定义良好 → 照常渲染", gb7714.with(), bib: clean, full: true)
#case("false · 命令定义良好 → 与 true 完全相同", gb7714.with(latex-strict-command: false), bib: clean, full: true)
#case("false · 未定义命令 → 丢弃命令、保留其后内容", gb7714.with(latex-strict-command: false), bib: bad, full: true)
#case("false · 内置 LaTeX 语料全量（含 \\noopsort 与 CJK 紧贴）", gb7714.with(latex-strict-command: false), bib: LATEX, full: true)
