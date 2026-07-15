//! param: sort-use-prefix
//! values: true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "sort-use-prefix", controls: "排序键是否把西文姓名前缀（van / de la）算进去。",
  expect: [`false`（缺省）：`van der Zee` 按 `Zee` 排（前缀不参与，落到 Wilson 之后）。
    `true`：按 `van der Zee` 整体排（v < w，落到 Wilson 之前）。
    条目级 `options = {useprefix=..}` 优先于本参数。])
#let two = bytes("@book{p1, author={van der Zee, Jan}, title={Prefix Zee}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{p2, author={Adams, Amy}, title={Adams}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{p3, author={Wilson, Will}, title={Wilson}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{p4, author={de la Zorro, Ana}, title={Zorro}, address={NY}, publisher={P}, year={2020}, langid={english}, options={use-prefix=true}}")
#case("false（缺省）· 按 Zee 排；p4 有 options={use-prefix=true} 故按 de la Zorro 排（d）", gb7714.with(style: "author-date"), bib: two, full: true)
#case("true · 按 van der Zee 排（Adams → de la Zorro → van der Zee → Wilson）", gb7714.with(style: "author-date", sort-use-prefix: true), bib: two, full: true)
#case("顺序编码制（按标注序，与本参数无关）", gb7714.with(), bib: two, full: true)
#case("逐名字覆盖：author 内写 use-prefix=true（优先于条目级与全局）", gb7714.with(style: "author-date"),
  bib: bytes("@book{q1, author={family=Zeta, given=Ann, prefix=de, use-prefix=true}, title={Name-level}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{q2, author={Adams, Amy}, title={Adams}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{q3, author={Miller, Max}, title={Miller}, address={NY}, publisher={P}, year={2020}, langid={english}}"), full: true)
