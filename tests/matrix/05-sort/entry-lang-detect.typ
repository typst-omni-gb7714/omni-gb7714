//! param: entry-lang-detect
//! values: "auto", "fast", "accurate"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "entry-lang-detect", controls: "条目缺 `langid` / `language` 域时的语言判定方式。",
  expect: [识别六种语言（zh / ja / ko / ru / fr / en，其余回落 `en`）。已显式标 `langid` 的条目*不受影响*。
    - `"auto"`（缺省）：预扫书目——含假名或日文独占字（経 / 戸 / 沢 / 辻 / 働 / 込）就用 `accurate`，否则 `fast`；
    - `"fast"`：纯字符脚本判定（假名→ja、谚文→ko、西里尔→ru，其余汉字→zh、拉丁→en），零额外开销；
    - `"accurate"`：中日独占字表 +《百家姓》白名单 + 法英辨识全套。
    语料 `lg-nolangid`（无 langid 的中文条目）与 `lg-mixed`（中西混排）是判定对象；
    三档的差异体现在*文种分组的落位*上（著者-出版年制才分组）。])
#let cs = (<lg-nolangid>, <lg-mixed>, <lg-zh>, <lg-en>, <lg-ja>, <lg-fr>)
#case(`"auto"`.text + "（缺省）", gb7714.with(style: "author-date"), bib: LANG, cites: cs, full: false)
#case(`"fast"`.text, gb7714.with(style: "author-date", entry-lang-detect: "fast"), bib: LANG, cites: cs, full: false)
#case(`"accurate"`.text, gb7714.with(style: "author-date", entry-lang-detect: "accurate"), bib: LANG, cites: cs, full: false)
