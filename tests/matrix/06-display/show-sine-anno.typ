//! param: show-sine-anno
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-sine-anno", controls: "出版信息里缺出版年时，是否在出版年位补占位（`北京: 某社, [日期不详]`）。",
  expect: [`false`（缺省）：留空。`true`：补「[s.a.] / 日期不详」占位（占位词按*条目语言*取，
    可经 `custom-terms` 的 `sine-anno` 键覆写）。
    *与 `show-sine-loco` / `show-sine-nomine` 的地位不同*：GB 对无出版地（§7.5.2.3）、无出版者
    （§7.5.3.3）给了著录形式，对*出版日期缺失*一个字都没说，官方 compliant CSL 实测也不补
    （缺年就是干净的「北京: 某社.」）。它是**方言样式的需求**——326 个中文 CSL 样式里，15 个顺序
    编码制样式在著录位补它——所以默认关。
    西文取拉丁 `s.a.`（*小写*，同 `s.n.`）：GB 对前两项明确选了拉丁体系，第三项在国标体系内类推
    拉丁才自洽（CSL 的 `n.d.` 是英美体系的选择）。大小写不做位置感知——GB 的*条文*就把 `S.l.` 大写、
    `s.n.` 小写写死了，那是 ISBD 里两个固定位置沉淀下来的词形，不是活的「段首大写」规则。
    *只对顺序编码制有意义*：著者-出版年制把出版年移到责任者后（§8.1），著录位本来就没有年——
    那一侧的占位归 `show-no-date` 管。开着它也不会在两个地方各补一个日期。
    三项都缺且都补时，前两项合并成一对方括号、日期占位另起：`[出版地不详: 出版者不详], [日期不详]`。])
#let sa = bytes("@book{a1, author={张三}, title={中文缺出版年}, address={北京}, publisher={某社}, langid={chinese}}
@book{a2, author={Smith, John}, title={No Year At All}, address={London}, publisher={Some Press}, langid={english}}
@book{a3, author={李四}, title={三项全缺}, langid={chinese}}
@book{a4, author={王五}, title={有出版年不触发}, address={北京}, publisher={某社}, year={2020}, langid={chinese}}
@online{a5, author={赵六}, title={电子资源不补}, url={https://example.com/x}, urldate={2024-01-01}, langid={chinese}}")
#let cs = (<a1>, <a2>, <a3>, <a4>, <a5>)
#case("false（缺省）", gb7714.with(version: 2015), bib: sa, cites: cs, full: false)
#case("true", gb7714.with(version: 2015, show-sine-anno: true), bib: sa, cites: cs, full: false)
#case("true + 另两项也开（三项全缺 → 前两项合并、日期另起）", gb7714.with(version: 2015, show-sine-anno: true, show-sine-loco: true, show-sine-nomine: true), bib: sa, cites: cs, full: false)
#case("true · 著者-出版年制（年在责任者后，著录位不补）", gb7714.with(style: "author-date", version: 2015, show-sine-anno: true), bib: sa, cites: cs, full: false)
#case("custom-terms 覆写成 CSL 的 n.d.", gb7714.with(version: 2015, show-sine-anno: true, custom-terms: (sine-anno: (zh: "出版时间不详", en: "n.d."))), bib: sa, cites: cs, full: false)
