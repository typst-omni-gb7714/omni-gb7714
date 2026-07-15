//! param: short-journal
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "short-journal", controls: "期刊名取 `journal` 还是 `shortjournal`。",
  expect: [`false`（缺省）用 `journal` / `journaltitle`；`true` 用 `shortjournal` 代替。
    条目*没有* `shortjournal` 字段时回落到全称（不留空）。])
#let jr = bytes("@article{j-short, author={Brown, Bob}, title={With Short Journal}, journaltitle={Journal of Physical Chemistry Letters}, shortjournal={J Phys Chem Lett}, year={2023}, volume={12}, number={4}, pages={100--115}, langid={english}}
@article{j-noshort, author={Green, Grace}, title={Without Short Journal}, journaltitle={Journal of Examples}, year={2023}, volume={9}, pages={1--8}, langid={english}}")
#case("false（缺省）", gb7714.with(), bib: jr, full: true)
#case("true", gb7714.with(short-journal: true), bib: jr, full: true)
