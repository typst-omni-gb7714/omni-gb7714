//! param: show-sine-loco
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-sine-loco", controls: "缺出版地时是否补「[S.l.] / 出版地不详」占位。",
  expect: [`false`（缺省）：留空。`true`：补占位（GB/T 7714 严格著录）。占位词按*条目语言*取。
    条目自己写了 `address = {[S.l.]}` 的，两档都原样著录（用户手写的字段文本不受本参数管）。
    与 `show-sine-nomine` 正交——出版地与出版者各管各的。])
#let cs = (<im-nopub>, <im-noloc>, <im-placeholder>)
#case("false（缺省）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("true", gb7714.with(show-sine-loco: true), bib: EDGE, cites: cs, full: false)
#case("true + show-sine-nomine: true（两个占位一起补）", gb7714.with(show-sine-loco: true, show-sine-nomine: true), bib: EDGE, cites: cs, full: false)
#case("true · 西文条目（[S.l.]）", gb7714.with(show-sine-loco: true, show-sine-nomine: true), bib: bytes("@book{en-nopub, author={Smith, John}, title={No Imprint}, year={2020}, langid={english}}"), full: true)
