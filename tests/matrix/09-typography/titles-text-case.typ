//! param: titles-text-case
//! values: none, "sentence", "title", dictionary（逐字段 + rest）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "titles-text-case", controls: "长标题类字段的大小写转换。",
  expect: [标量作用于全部白名单字段；字典按字段分设、`rest` 兜底。
    `none`（缺省）：不转换，按 `.bib` 原样（`raw(theme: none)` 同款「关处理、内容照显」语义）。
    `"sentence"`：句首大写、其余小写。
    `"title"`：实词大写、小词小写、首末词与冒号后的词恒大写（CSL `text-case="title"` 同款冒号规则）。
    *词保护（两档共用）*：词内首个字母之后还有大写、或含数字的词原样不动——mRNA、pH、DNA、iPhone、
    FLUENT、3D、COVID-19 都保得住，对齐 CSL「mixed / uppercase 词 stays the same」；判据分不出
    「大写的普通词」与缩写（STUDY 与 DNA 同形），CSL 原文就是全放过。*整串全大写*的字段值先按
    CSL 的 uppercase 分支整体重排（RESEARCH ON ... -> Research on ...），否则每个词都触发保护、全串冻结。
    纯小写（rna、von）与仅首位大写（Neumann）的专名保护不了，仍要 `{}`。
    CSL 原味的 sentence 对混排串只抬首词、其余全不动（整档已 deprecated）；本档比它激进
    （把 Title Case 数据规整回小写），词保护即激进档的保险。
    *白名单 12 字段*：`title` / `subtitle` / `titleaddon` / `maintitle` / `booktitle` / `booksubtitle` /
    `booktitleaddon` / `journaltitle`（`journal` 是别名键，真名静默胜）/ `journalsubtitle` /
    `journaltitleaddon` / `eventtitle` / `series`；其余键 panic。
    `shortjournal` *不受理*——缩写刊名的大小写即其规范。
    `{}` 保护的括号内两档都不动（biblatex 惯例）；*含 CJK 的字段值整体跳过*（大小写无意义，且内嵌的
    DNA 一类拉丁词不得被改）。转换在解析期由 citegeist（Rust）按字段应用。])
#let tc = bytes("@article{tc-a, author={Smith, John}, title={the STUDY of DNA and rna: a NEW approach}, subtitle={AN important SUBTITLE}, journaltitle={journal of EXAMPLES and things}, year={2020}, volume={1}, pages={1--10}, langid={english}}
@incollection{tc-b, author={Doe, Jane}, title={a chapter IN a book}, booktitle={THE great BOOK of examples}, editor={Roe, Rich}, address={NY}, publisher={P}, year={2021}, pages={5--9}, langid={english}}
@book{tc-brace, author={Poe, Pam}, title={protected {DNA} and {mRNA} in lowercase text}, address={NY}, publisher={P}, year={2022}, langid={english}}
@book{tc-cjk, author={张三}, title={中文题名 with DNA inside}, address={北京}, publisher={社}, year={2020}, langid={chinese}}
@article{tc-short, author={Roe, Rick}, title={short journal case}, journaltitle={Journal of Physical Chemistry}, shortjournal={J Phys Chem}, year={2023}, volume={2}, pages={1--5}, langid={english}}")
#case("none（缺省，原样）", gb7714.with(), bib: tc, full: true)
#case(`"sentence"`.text, gb7714.with(titles-text-case: "sentence"), bib: tc, full: true)
#case(`"title"`.text, gb7714.with(titles-text-case: "title"), bib: tc, full: true)
#case(`(title: "sentence", journaltitle: "title", rest: none)`.text, gb7714.with(titles-text-case: (title: "sentence", journaltitle: "title", rest: none)), bib: tc, full: true)
#case(`(rest: "title", title: none)`.text, gb7714.with(titles-text-case: (rest: "title", title: none)), bib: tc, full: true)
#case(`"title"`.text + " + short-journal: true（shortjournal 不受理，原样）", gb7714.with(titles-text-case: "title", short-journal: true), bib: tc, full: true)
// 报告者语料（2026-09 建议采纳时的实测四条）：保护判据的代表样本。
#let tc2 = bytes("@article{tc2-a, author={Ao, Al}, title={Study of mRNA and DNA in pH 7 buffer using FLUENT 3D models}, journaltitle={Journal of CFD}, year={2020}, volume={1}, pages={1--2}, langid={english}}
@article{tc2-b, author={Bo, Bill}, title={RESEARCH ON KEY TECHNOLOGIES OF POROUS BEARINGS}, journaltitle={Chinese Journal}, year={2021}, volume={2}, pages={3--4}, langid={english}}
@article{tc2-c, author={Cole, Carl}, title={The iPhone and the von Neumann architecture: a review}, journaltitle={Computing}, year={2022}, volume={3}, pages={5--6}, langid={english}}
@article{tc2-d, author={Do, Dan}, title={An {mRNA}-based {COVID}-19 vaccine}, journaltitle={Nature}, year={2023}, volume={4}, pages={7--8}, langid={english}}")
#case(`"sentence"`.text + " · 词保护语料（mRNA/pH/FLUENT/3D 原样；全大写串整体重排；iPhone 保、Neumann 失）", gb7714.with(titles-text-case: "sentence"), bib: tc2, full: true)
#case(`"title"`.text + " · 词保护语料（同上 + 冒号后 a -> A）", gb7714.with(titles-text-case: "title"), bib: tc2, full: true)
