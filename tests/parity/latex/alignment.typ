// ============================================================
// LaTeX 命令 / 转义行为 —— 与 biblatex (gb7714-2015.bbx) 对齐测试
// ============================================================
// 基准：每条右侧注释为 biblatex 实测输出（pdflatex + biber + gb7714-2015）。
// 编译：typst compile --root ../../.. latex-cmd-alignment.typ
// 期望：编译通过；每条渲染与注释中的 biblatex 输出一致。
//
// 容错对齐（2026-06 改）：
//   - 未定义命令 \foobar      → 优雅降级（丢命令、保留其后内容、继续；对齐 biblatex nonstopmode）；
//   - 紧贴 CJK \textbf中       → 整条成未知命令 → 丢弃（CJK 吞进命令名，对齐 ctex catcode 11）；
//   - 未配对数学定界符 $       → 仍 panic（结构错，biblatex: ! Missing $ inserted.）。
#import "/lib.typ": gb7714, bibliography

#let bib = "
@misc{esc1, title={Esc pct 50\\% off},          author={A}, year={2020}}
@misc{esc2, title={Esc amp R\\&D dept},          author={A}, year={2020}}
@misc{esc3, title={Esc hash C\\#sharp},          author={A}, year={2020}}
@misc{esc4, title={Esc under file\\_name},       author={A}, year={2020}}
@misc{esc5, title={Esc brace \\{x\\} here},      author={A}, year={2020}}
@misc{esc6, title={Esc dollar \\$5 fee},         author={A}, year={2020}}
@misc{acc1, title={Accent caf\\'e na\\\"ive},    author={A}, year={2020}}
@misc{acc2, title={Accent \\v{C}esk\\'a},        author={A}, year={2020}}
@misc{let1, title={Letter \\oe uvre caesar \\ae},author={A}, year={2020}}
@misc{let2, title={Letter \\o re W\\l ad Wei\\ss},author={A}, year={2020}}
@misc{sym1, title={Sym \\dag and \\ddag and \\P},author={A}, year={2020}}
@misc{sym2, title={Sym Brand\\texttrademark x},  author={A}, year={2020}}
@misc{sym3, title={Sym \\S 5 \\copyright 2020 \\pounds 50}, author={A}, year={2020}}
@misc{dot1, title={Ellipsis a \\ldots z end},    author={A}, year={2020}}
@misc{tilde,title={Tilde \\textasciitilde and back \\textbackslash and caret \\textasciicircum}, author={A}, year={2020}}
@misc{dash1,title={Dash 1--5 and yes---no},      author={A}, year={2020}}
@misc{quo1, title={Quote ``double'' and `single'}, author={A}, year={2020}}
@misc{quo2, title={Apostrophe O'Brien don't},    author={A}, year={2020}}
@misc{math1,title={Math $E=mc^2$ equation},      author={A}, year={2020}}
@misc{font1,title={Font \\textbf{bold} \\emph{italic} \\textsc{sc} \\texttt{tt}}, author={A}, year={2020}}
@misc{url1, title={Link \\url{http://example.com} done}, author={A}, year={2020}}
@misc{tie1, title={Raw~tie becomes nbsp},        author={A}, year={2020}}
"

#show: gb7714.with(full: true, cite-completion: false)

= LaTeX 命令对齐测试

#bibliography(bib)

/*
─────────────────────────────────────────────────────────────────
biblatex 实测基准（应逐条与上方渲染一致）：

[esc1]  Esc pct 50% off
[esc2]  Esc amp R&D dept
[esc3]  Esc hash C#sharp
[esc4]  Esc under file_name
[esc5]  Esc brace {x} here
[esc6]  Esc dollar $5 fee
[acc1]  Accent café naïve
[acc2]  Accent Česká
[let1]  Letter œuvre caesar æ
[let2]  Letter øre Wład Weiß
[sym1]  Sym †and ‡and ¶                 （字母符号命令吞尾空格）
[sym2]  Sym Brand™x
[sym3]  Sym §5 ©2020 £50
[dot1]  Ellipsis a … z end              （\ldots 保留尾空格，语义 …）
[tilde] Tilde ~and back \and caret ^    （\textbackslash 吞尾空格 → \and）
[dash1] Dash 1–5 and yes—no             （-- → 短破折号，--- → 长破折号）
[quo1]  Quote “double” and ‘single’     （TeX 引号连字）
[quo2]  Apostrophe O’Brien don’t        （' 恒为右单引号 ’）
[math1] Math 𝐸 = 𝑚𝑐2 equation          （$...$ 经 mitex 渲染）
[font1] Font bold italic sc tt          （字体命令：加粗/斜体/小型大写/等宽）
[url1]  Link http://example.com done    （\url{} 去壳为裸 URL）
[tie1]  Raw tie becomes nbsp            （~ → 不间断空格）

─────────────────────────────────────────────────────────────────
负向（报错）对齐 —— 单独手工验证，不能进可编译测试：

  bib: @misc{x, title={Has \foobar undefined}, ...}
  → panic: "omni-gb7714: bib 字段含未定义的 LaTeX 命令 "\foobar"
           （biblatex 下等价错误："! Undefined control sequence."）"

  bib: @misc{y, title={Price is $5 only}, ...}      （裸未配对 $）
  → panic: "omni-gb7714: bib 中存在未配对的数学定界符 `$`
           （biblatex 下等价错误："! Missing $ inserted."）"

─────────────────────────────────────────────────────────────────
已知 citegeist 内部限制（非本包可控）：
  \dots（无前导 l）：citegeist 自身转 … 并吞尾空格；biblatex 保留空格。
  语义 … 正确，仅尾空格细微差异。\ldots 由本包接管，行为与 biblatex 一致。
*/
