//! param: bib-et-al-min
//! values: 2, 4, 5, 999, 语言档, 角色档, 角色×语言两级
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-et-al-min", controls: "文献表里责任者数量*达到*此值就截断。",
  expect: [缺省 `4`（GB §7.1.2：≤3 全录，>3 录前 3 加「，等」——即「达到 4 位」就截断）。
    *语义与 CSL 的 `et-al-min` 逐字同义*——责任者数**达到**此数就截断（`>=`），CSL 样式里的
    ```xml et-al-min="4"``` 就是本项的 `4`，照搬即可、不必换算。（曾是「*超过*此数才截断」，默认值也因此
    小一位；语义等价，但每次跟 CSL 样式对照都要在脑子里 ±1，迁移样式时极易错位。）
    语料条目有 4 位责任者——缺省下正好触发截断。设 `5` 恰好不截，设 `999` 关闭截断。

    后三档是*字典取值*，语料换成 `roles.bib`（每条都让多个截断位置各站 4 位责任者，
    这样单独改一个位置的阈值就看得出来）：
    - *语言档* `(zh: 3, rest: 9)`：中文条目 3 位就截，西文条目 9 位才截（4 位全出）。按*条目语言*分设。
    - *角色档* `(principal: 9, host: 2, editor: 2, translator: 3, rest: 4)`：同一条目内，主责任者
      4 位全出（阈值 9），而母体责任者、译者、编者都截断——四个截断位置各用各的阈值。
    - *两级* `(editor: (en: 2, rest: 9), rest: 9)`：除编者外一律不截（`rest: 9`）；编者里只有*西文*
      条目截断（`en: 2`），中文编者走 `rest: 9` 不截。角色与语言两轴同时生效。

    角色分设的来路是真实需求：Zotero 中文社区语料里「中国政法大学」「中外法学」「法学引注手册」等
    样式给编者单设了比著者更宽的阈值（西文条目 `et-al-min="5"` 而著者是 `4`），日文条目又收到 `3`。])
#let cs = (<bm-zh>, <bm-en>)
#case("2", gb7714.with(bib-et-al-min: 2), cites: cs, full: false)
#case("4（缺省，GB §7.1.2）", gb7714.with(), cites: cs, full: false)
#case("5（> 责任者数，不截断）", gb7714.with(bib-et-al-min: 5), cites: cs, full: false)
#case("999（关闭截断）", gb7714.with(bib-et-al-min: 999), cites: cs, full: false)

#let rs = (<rl-part-en>, <rl-editor-en>, <rl-editor-zh>)
#case("对照：标量 4（roles 语料，四个位置同阈值）", gb7714.with(), bib: ROLES, cites: rs, full: false)
#case("语言档 (zh: 3, rest: 9)", gb7714.with(bib-et-al-min: (zh: 3, rest: 9)), bib: ROLES, cites: rs, full: false)
#case("角色档 (principal: 9, host: 2, editor: 2, translator: 3, rest: 4)",
  gb7714.with(bib-et-al-min: (principal: 9, host: 2, editor: 2, translator: 3, rest: 4)),
  bib: ROLES, cites: rs, full: false)
#case("角色×语言两级 (editor: (en: 2, rest: 9), rest: 9)",
  gb7714.with(bib-et-al-min: (editor: (en: 2, rest: 9), rest: 9)),
  bib: ROLES, cites: rs, full: false)
