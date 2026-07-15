//! param: LaTeX 语料（latex.bib 全表）
//! values: 命令 / 符号 / 重音 / 转义 / 花括号 / 数学 / 换行 / verbatim / CJK 紧贴 / noopsort
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "LaTeX 词法全表", controls: "`latex.bib` 整表——字段里的 LaTeX 命令怎么落地。",
  expect: [字体命令（`\textit` / `\textbf` / `\emph`）转成 Typst 样式；
    符号（`\LaTeX` / `\TeX` / `\S` / `\P` / `\copyright` / `\textregistered`）转成对应字符；
    重音（`\"{u}` / `\'{e}` / `\c{c}`）合成带音标字符；
    转义（`\&` `\_` `\#` `\%` `\$` `\{` `\}` `\textasciitilde` `\textbackslash` `\textasciicircum`）出字面字符；
    花括号保护大小写；数学环境按 Typst 数学渲染；`\\` 换行；
    *verbatim 字段*（`url` / `doi` / `eprint`）*不做* LaTeX 转换（`a_b~c` 原样）；
    CJK 紧贴命令（`\textbf 中文`）与 `\noopsort` 是*未定义命令*——本文件开 `latex-strict-command: false` 才编得过。])
#case("宽松模式（strict-command / strict-char 都关）", gb7714.with(latex-strict-command: false, latex-strict-char: false), bib: LATEX, full: true)
#case("宽松 + 著者-出版年制（\\noopsort 作排序代理）", gb7714.with(latex-strict-command: false, latex-strict-char: false, style: "author-date"), bib: LATEX, full: true)
