//! param: titles-text-case
//! values: none, "sentence", "title", dictionary（逐字段 + rest）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "titles-text-case", controls: "长标题类字段的大小写转换。",
  expect: [标量作用于全部白名单字段；字典按字段分设、`rest` 兜底。
    `none`（缺省）：不转换，按 `.bib` 原样（`raw(theme: none)` 同款「关处理、内容照显」语义）。
    `"sentence"`：句首大写、其余小写（CSL `text-case="sentence"`）。
    `"title"`：实词大写、小词小写、首末词恒大写（CSL `text-case="title"`）。
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
