//! param: custom-languages
//! values: 注册新语言码, langid 别名 / 码本身 / 区域后缀剥离, 点亮内置 de 兜底 + custom-terms 逐词补
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-languages", controls: "注册*新语言码*，让内置识别外的语种（德文等）能出自己的本地化术语。",
  expect: [GB 文献表主体恒为中文，本参只影响*西文条目的术语字面量*（`编`/`译`/`佚名` 等），不改标点字距。
    形态 `(<语言码>: (<langid 别名>, ...))`：键=自创码（不得撞内置 zh/ja/ko/ru/fr/en）；值=别名字符串或数组。
    条目 `langid` / `language` 域写这些别名（或*码本身*）即归到该码，*区域后缀自动剥离*（`de-DE` → `de`）。
    - 内置已为 `de` 预置「佚名 = o. A.」「无日期 = o. J.」——注册 `de` 即*点亮*这些兜底；其余术语用
      `custom-terms` 逐词补（`(editor: (de: "Hrsg."))`）。
    - 新码一律按*西文*处理（非 CJK，不触发全角标点 / 中文字距）；自动检测猜不出西文具体语种，
      故仅对*显式标注 `langid`* 的条目生效。缺 `langid` 的条目不受影响。])
#let cl = bytes("@book{cl-de1, author={Müller, Hans}, editor={Schmidt, Anna}, title={Deutsches Buch}, publisher={Verlag}, address={Berlin}, year={2020}, langid={german}}
@book{cl-de2, title={Anonymes Werk}, publisher={Verlag}, address={München}, year={2019}, langid={de-DE}}
@book{cl-de3, author={Weber, Karl}, title={Werk mit Code}, publisher={Verlag}, address={Bonn}, year={2018}, langid={de}}
@book{cl-en1, author={Smith, John}, editor={Doe, Jane}, title={English Book}, publisher={Press}, address={London}, year={2021}, langid={english}}")
#let one(name, cfg) = case(name, cfg, bib: cl, full: true)
#one("(:)（缺省：langid=german 不识别，落西文按 en 出术语 ed./Anon）", gb7714.with(show-anon: true))
#one("注册 de：(de: (\"german\", \"deu\"))（点亮内置兜底佚名 o. A.）", gb7714.with(
  custom-languages: (de: ("german", "deu")), show-anon: true))
#one("de + custom-terms 逐词补德文编者 Hrsg.", gb7714.with(
  custom-languages: (de: ("german", "deu")), custom-terms: (editor: (de: "Hrsg.")), show-anon: true))
#one("区域后缀剥离：langid=de-DE 命中 de（cl-de2 出 o. A.）", gb7714.with(
  custom-languages: (de: ("german",)), show-anon: true))
#one("码本身作 langid：langid=de 命中（无需列进别名）", gb7714.with(
  custom-languages: (de: ()), custom-terms: (editor: (de: "Hrsg.")), show-anon: true))
