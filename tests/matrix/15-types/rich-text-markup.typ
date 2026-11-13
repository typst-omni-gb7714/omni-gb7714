//! param: CSL JSON 富文本标记（Zotero 导出字段值里的 HTML 子集）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "富文本标记", controls: "citeproc 的富文本标记是固定有限的 HTML 子集——`<i>` 斜体、`<b>` 粗体、`<sup>` 上标、`<sub>` 下标、`<sc>` 小型大写、`<span class=\"nocase\">` 大小写保护。Zotero 导出的 `.bib` 字段值可能带这些标记,omni 进 citegeist 前归一为对应的 LaTeX 命令 / 花括号组,由 `to-typst` 渲染。标签名大小写不敏感（Zotero 有时导出 `<Span>`）。",
  expect: [进 citegeist 前 `normalize-html` 把标记转换:`<i>`→`\textit`、`<b>`→`\textbf`、`<sup>`→`\textsuperscript`、`<sub>`→`\textsubscript`、`<sc>`→`\textsc`(五者复用 `to-typst` 已有映射→emph/strong/super/sub/smallcaps);`<span class="nocase">…</span>`→`{…}`(复用 citegeist brace-group=大小写保护+原样输出,等义于 CSL `nocase`)。

    - *默认*(不 title-case):五个样式标记各自渲染;`nocase` 段原样输出(`DNA`)。标记本身不漏进版面。
    - *开 title-case*(`titles-text-case: (title: "title")`):`nocase` 段大小写受保护——`<span class="nocase">DNA</span>` 保持 `DNA`,而同句非 nocase 的 `rna` 被 title-case 转成 `Rna`。])

#let eb = bytes("@article{styles, author={X}, title={The genome of <i>Eucalyptus grandis</i>, <b>bold</b>, E=mc<sup>2</sup>, H<sub>2</sub>O, <sc>unesco</sc>}, journaltitle={Nature}, date={2020}, langid={english}}
@article{nocase, author={Y}, title={study of <span class=\"nocase\">DNA</span> and rna in cells}, journaltitle={Science}, date={2020}, langid={english}}")

// Zotero *builtin* BibTeX 的导出：`<` `>` 被转义成 `{\textless}` `{\textgreater}`，斜体是真 `\textit{}`。
#let builtin = bytes("@article{builtin, author={Z}, title={The genome of \\textit{{\\textless}span class=\"nocase\"{\\textgreater}Eucalyptus grandis{\\textless}/span{\\textgreater}}}, journaltitle={Nature}, date={2014}, langid={english}}")

#case("五个样式标记 + nocase(默认不 title-case)", gb7714.with(version: 2025), bib: eb, cites: (<styles>, <nocase>), full: true)
#case("nocase 大小写保护(开 title-case)", gb7714.with(version: 2025, titles-text-case: (title: "title")), bib: eb, cites: (<nocase>,), full: true)
#case("Zotero builtin：`{\\textless}span…{\\textgreater}` 转义 HTML 不漏进版面", gb7714.with(version: 2025), bib: builtin, cites: (<builtin>,), full: true)
