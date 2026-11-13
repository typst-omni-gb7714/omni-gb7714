//! param: show-sine-loco
//! values: auto, false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-sine-loco", controls: "缺出版地时是否补「[S.l.] / 出版地不详」占位。",
  expect: [`auto`（缺省）：条件补白——另一侧（出版者）在场时补，皆缺则都不补；但*电子资源的出版信息片段*
    （无责任者 / 题名 + 有 url）缺出版地不补（GB §7.5.2.3「无出版地的*电子资源*可省略此项」，如
    §7.5.2.3:3「Open University Press, 2025. https://…」）——非电子片段（§7.5.2.3:1「[出版地不详]: 三户图书刊行社, 1990」）
    与完整著录（§8.2.2:7 联机图书仍补 [S.l.]）照补。`false`：从不补。`true`：总补（GB 严格著录）。占位词按*条目语言*取。
    条目自己写了 `address = {[S.l.]}` 的，各档都原样著录（用户手写的字段文本不受本参数管）。与 `show-sine-nomine` 正交。])
#let cs = (<im-nopub>, <im-noloc>, <im-placeholder>)
#case("auto（缺省）", gb7714.with(), bib: EDGE, cites: cs, full: false)
#case("true", gb7714.with(show-sine-loco: true), bib: EDGE, cites: cs, full: false)
#case("true + show-sine-nomine: true（两个占位一起补）", gb7714.with(show-sine-loco: true, show-sine-nomine: true), bib: EDGE, cites: cs, full: false)
#case("true · 西文条目（[S.l.]）", gb7714.with(show-sine-loco: true, show-sine-nomine: true), bib: bytes("@book{en-nopub, author={Smith, John}, title={No Imprint}, year={2020}, langid={english}}"), full: true)

// auto 缺省的电子片段规则（§7.5.2.3 / §7.5.3.3）：非电子片段照补、电子片段省、完整著录照补。
#let SL = bytes("@book{fragprint, publisher={三户图书刊行社}, date={1990}, langid={chinese}}
@book{fragurl, publisher={Open University Press}, date={2025}, url={https://x.uk/econ}, urldate={2014-06-16}, langid={british}}
@book{fragloc, location={哈尔滨}, date={2013}, langid={chinese}}
@book{fullonline, author={Praetzellis, Adrian}, title={Death by Theory}, publisher={Rowman}, date={2020}, url={https://x.org/dt}, langid={english}}")
#case("auto：非电子片段补(§7.5.2.3:1 [出版地不详]／§7.5.3.3:1 [出版者不详])·电子片段省(§7.5.2.3:3)·完整联机著录仍补(§8.2.2:7)", gb7714.with(version: 2025), bib: SL, cites: (<fragprint>, <fragloc>, <fragurl>, <fullonline>), full: true)
