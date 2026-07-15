//! param: page-range-style
//! values: none, "expanded", "minimal", "minimal-two", "chicago-15", "chicago-16"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "page-range-style", controls: "起讫页码的*位数形态*（与管连接符的 `page-range-separator` 正交）。",
  expect: [`none`（缺省）：*页码原样，一个数字都不动*——GB/T 7714—2025 §7.7 只规定「阿拉伯数字」，
    没规定折叠还是展开；标准不要求就不替用户决定，开档位即用户显式同意「改写我的 `pages` 数据」。
    `"expanded"`：结束页补全（`321-28` → `321-328`）。`"minimal"`：只留变化的位（`321-328` → `321-8`）。
    `"minimal-two"`：同上但至少两位（→ `321-28`）。
    `"chicago-15"` / `"chicago-16"`：起始页 < 100 或整百时全写、百位后是 0x 时只写变化位、否则至少两位；
    两版只在四位数变三位时不同（`1496-1500` 对 `1496-500`）。CSL 的 `"chicago"` 是 `chicago-15` 的别名。
    算法照搬 citationberg（Typst 原生 CSL 引擎），与原生路由逐字一致。
    *边界*：起讫两端*前缀不同*就整段不动（`xii-xv`）；`S12-S18` 前缀同为 S，照常重排；
    结束页比起始页*长*的是真跨百（`98-103`），不折叠、不补位；多段页码逐段处理。
    只作用于文献表的 `pages`；`eid`（文章编号）与正文引文页码不参与。])
#let pg = bytes("@article{p-a, author={甲}, title={321-328}, journaltitle={刊}, year={2020}, pages={321--328}, langid={chinese}}
@article{p-b, author={乙}, title={321-28（原始就是折叠写法）}, journaltitle={刊}, year={2020}, pages={321--28}, langid={chinese}}
@article{p-c, author={丙}, title={100-104（整百）}, journaltitle={刊}, year={2020}, pages={100--104}, langid={chinese}}
@article{p-d, author={丁}, title={101-107（百位后 0x）}, journaltitle={刊}, year={2020}, pages={101--107}, langid={chinese}}
@article{p-e, author={戊}, title={1496-1500（四位变三位）}, journaltitle={刊}, year={2020}, pages={1496--1500}, langid={chinese}}
@article{p-f, author={己}, title={98-103（真跨百）}, journaltitle={刊}, year={2020}, pages={98--103}, langid={chinese}}
@article{p-g, author={庚}, title={xii-xv（罗马数字，前缀不同）}, journaltitle={刊}, year={2020}, pages={xii--xv}, langid={chinese}}
@article{p-h, author={辛}, title={S12-S18（前缀相同）}, journaltitle={刊}, year={2020}, pages={S12--S18}, langid={chinese}}
@article{p-i, author={壬}, title={多段 12-15, 20-25}, journaltitle={刊}, year={2020}, pages={12--15, 20--25}, langid={chinese}}")
#case("none（缺省，原样）", gb7714.with(), bib: pg, full: true)
#case(`"expanded"`.text, gb7714.with(page-range-style: "expanded"), bib: pg, full: true)
#case(`"minimal"`.text, gb7714.with(page-range-style: "minimal"), bib: pg, full: true)
#case(`"minimal-two"`.text, gb7714.with(page-range-style: "minimal-two"), bib: pg, full: true)
#case(`"chicago-15"`.text, gb7714.with(page-range-style: "chicago-15"), bib: pg, full: true)
#case(`"chicago-16"`.text, gb7714.with(page-range-style: "chicago-16"), bib: pg, full: true)
#case(`"minimal"`.text + " + page-range-separator: 「～」（两轴正交）", gb7714.with(page-range-style: "minimal", page-range-separator: "～"), bib: pg, full: true)
