//! param: date-fallback
//! values: none, "urldate"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "date-fallback", controls: "条目没有出版年（`date` 与 `year` 都缺）时，从哪个字段推定一个。",
  expect: [`none`（缺省）不推定——出版年就是空的，著者-出版年制下由 `show-no-date` 补占位词。
    `"urldate"` 取引用日期的*年份*，著录为 `[2024]`：方括号是「推定值」的标记（§7.5.4.3「估计的
    出版年应置于「[]」内」）。只取年——官方 compliant CSL 的 `<date variable="accessed"
    date-parts="year">` 也只取年。
    推定出的年*参与一切*：文献表出版年位、正文标注、排序键、消歧后缀（`[2024a]`，后缀在方括号*内*）。
    与「引用日期显不显示」无关（2025 版 `[M/OL]` 不著录引用日期，官方 CSL 照样拿它推定）。
    连引用日期也没有的条目仍是空的——*不造*「日期不详」（两版官方 CSL 实测都留空）。
    *2025 版平台式电子资源（EB / DS / PP）不推定*：它们的日期槽是「（创建或修改日期）[引用日期]」，
    没有传统「出版年」槽——引用日期已摆在 `[…]` 里当日期，再推一个出版年是造数据。官方 2025 CSL 同判
    （网页走 `creation-accessed-date`，无兜底；「缺 issued 取 accessed 年」只在图书类的 `date` 宏里），
    citeproc-lua 实测网页 / 数据集 / 预印本缺出版年都只出 `[引用日期]`。联机图书（`@book` + url）等有真
    出版年槽的照常推定。
    *缺省关的依据*：官方 compliant CSL 做（`issued` 缺失时取 `accessed` 的年加方括号），胡振震
    biblatex 不做，GB 只规定了「估计的出版年怎么写」、没规定「从哪里推」——推定一个作者从未声明过的
    年份是造数据，须显式同意。])
#let df = bytes("@book{f1, author={张三}, title={有引用日期无出版年}, address={北京}, publisher={某社}, url={https://example.com/a}, urldate={2024-03-05}, langid={chinese}}
@book{f2, author={张三}, title={同责任者同推定年}, address={北京}, publisher={某社}, url={https://example.com/b}, urldate={2024-06-01}, langid={chinese}}
@book{f3, author={李四}, title={什么日期都没有}, address={北京}, publisher={某社}, langid={chinese}}
@book{f4, author={王五}, title={有出版年不触发}, address={北京}, publisher={某社}, year={2020}, url={https://example.com/d}, urldate={2024-01-01}, langid={chinese}}
@online{f5, author={赵六}, title={电子资源缺出版年}, url={https://example.com/e}, urldate={2025-05-06}, langid={chinese}}")
#let cs = (<f1>, <f2>, <f3>, <f4>)
#case("none（缺省）· 顺序编码制", gb7714.with(version: 2015), bib: df, cites: cs, full: false)
#case("\"urldate\" · 顺序编码制（出版年位出 [2024]）", gb7714.with(version: 2015, date-fallback: "urldate"), bib: df, cites: cs, full: false)
#case("none（缺省）· 著者-出版年制（缺年 → show-no-date 补占位）", gb7714.with(style: "author-date", version: 2015), bib: df, cites: cs, full: false)
#case("\"urldate\" · 著者-出版年制（标注出 [2024a] / [2024b]，后缀在方括号内）", gb7714.with(style: "author-date", version: 2015, date-fallback: "urldate"), bib: df, cites: cs, full: false)
#case("\"urldate\" · 电子资源（2025 版 EB/DS/PP）：*不推定*，只出引用日期（对齐 citeproc）", gb7714.with(version: 2025, date-fallback: "urldate"), bib: df, cites: (<f5>,), full: false)
