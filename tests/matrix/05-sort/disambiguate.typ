//! param: disambiguate
//! values: auto, true, false, dict(date / given-name / names)
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "disambiguate", controls: "引用标注的消歧机制（三键：`date` / `given-name` / `names`）。",
  expect: [标量是三键同值的简写；字典逐机制指定，缺的键按 `auto`。
    梯子次序与官方 CSL 同：*展开名单* → *补名* → 剩下的真同人同年落*年份后缀*。
    - `date`：`auto` 只在著者-出版年制*著录处*与其标注加 `a`/`b`；`true` 则 `numeric` 著录格式下条目末尾的出版年也带后缀。
      *分组判据是「行内渲染出的那个标签」*（含 `et al.` 截断词、含前两档的升级），不是「数据里是不是同一批人」——
      梯子的兜底档要兜住的正是「前两档过后*纸面上仍然撞车*」的条目。真 citeproc + 官方社区 GB 著者-出版年制样式
      实测（该样式关着 add-names、开着 add-year-suffix）：`Brown/Wang/Li (2021)` 与 `Brown/Chen/Li (2021)` 名册
      *不同*、标签都截成 `Brown et al., 2021`，citeproc 照样落 `2021a` / `2021b`。
      反过来，`张三，李四，等` 与 `张三` 的标签本来就不同，不进同一组、不加后缀（旧实现按「第一作者」分组，
      把它也拉了进来，反而误导读者）；
    - `given-name`：同姓不同人时补名（姓 → 姓+首字母 → 全名），GB §9.3.1 →§7.1.1，对齐 CSL 的 `disambiguate-add-givenname`；
    - `names`：首责任者同、合作者不同时逐条展开被「等」截断的名单，对齐 CSL 的 `disambiguate-add-names`。
    `given-name` / `names` 的 `auto` 跟*标注形态轴*：`style.cite` 是著者-出版年制才生效。
    *梯子次序是「①补名 ②展开名单 ③年份后缀」*——能用轻的手段分开就不用重的。d9 / d10 两条路都走得通
    （`Stone Sam/Wang/Li` 与 `Stone Sue/Chen/Li` 截断后都是 `Stone et al.`）：*先补名*得 `Stone S… et al.`
    而不是 `Stone, Wang et al.`。citeproc-lua 的 `build_fully_disambiguated_ir` 就是
    add_givenname → add_names → add_year_suffix，实测同形。
    （d3 / d4 的第一责任者是同一个人，补名无能为力，才轮到展开名单。）
    d7 / d8 是*估计的出版年*（`date={2019~}`）撞车：后缀落进方括号*内*（`[2019a]`，不是 `[2019]a`）——
    官方社区 CSL 经真 citeproc 实测就是「（张三，［2020a］）」，CSL 的 year-suffix 附在 year 这个
    date-part 之后，而方括号是整个日期元素的 prefix / suffix。])
#let dis = bytes("@book{d1, author={Smith, John}, title={Alpha}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{d2, author={Smith, Anne}, title={Beta}, address={NY}, publisher={P}, year={2020}, langid={english}}
@book{d3, author={Brown, Bob and Wang, Wei and Li, Lei}, title={Gamma}, address={NY}, publisher={P}, year={2021}, langid={english}}
@book{d4, author={Brown, Bob and Chen, Chao and Li, Lei}, title={Delta}, address={NY}, publisher={P}, year={2021}, langid={english}}
@book{d5, author={Jones, Jim}, title={Epsilon}, address={NY}, publisher={P}, year={2022}, langid={english}}
@book{d6, author={Jones, Jim}, title={Zeta}, address={NY}, publisher={P}, year={2022}, langid={english}}
@book{d7, author={Vague, Vic}, title={Eta}, address={NY}, publisher={P}, date={2019~}, langid={english}}
@book{d8, author={Vague, Vic}, title={Theta}, address={NY}, publisher={P}, date={2019~}, langid={english}}
@book{d9, author={Stone, Sam and Wang, Wei and Li, Lei}, title={Iota}, address={NY}, publisher={P}, year={2024}, langid={english}}
@book{d10, author={Stone, Sue and Chen, Chao and Li, Lei}, title={Kappa}, address={NY}, publisher={P}, year={2024}, langid={english}}
@book{d11, title={无责任者甲}, address={京}, publisher={社}, year={2013}, langid={chinese}}
@book{d12, title={无责任者乙}, address={京}, publisher={社}, year={2013}, langid={chinese}}")
#let cs = (<d1>, <d2>, <d3>, <d4>, <d5>, <d6>, <d7>, <d8>, <d9>, <d10>)
#let anon-cs = (<d11>, <d12>)
#case("auto · 著者-出版年制（三机制全开）", gb7714.with(style: "author-date", bib-et-al-min: 2, cite-et-al-min: 2), bib: dis, cites: cs, full: false)
#case("无责任者、同年 → 佚名 2013a/b（正文与文献表同源；author-short 返回 none 也要参与消歧）", gb7714.with(style: "author-date", show-anon: true), bib: dis, cites: anon-cs, full: false)
#case("false（全关：标注撞车不管）", gb7714.with(style: "author-date", bib-et-al-min: 2, cite-et-al-min: 2, disambiguate: false), bib: dis, cites: cs, full: false)
#case("true · 顺序编码制（date 一律加 → 条目末尾出版年带后缀）", gb7714.with(bib-et-al-min: 2, disambiguate: true), bib: dis, cites: cs, full: false)
#case("auto · 顺序编码制（[1] 无标签可消歧，著录处也不加）", gb7714.with(bib-et-al-min: 2), bib: dis, cites: cs, full: false)
#case(`(date: true, given-name: false, names: false)`.text, gb7714.with(style: "author-date", bib-et-al-min: 2, cite-et-al-min: 2, disambiguate: (date: true, given-name: false, names: false)), bib: dis, cites: cs, full: false)
#case(`(given-name: true, names: false, date: true)`.text, gb7714.with(style: "author-date", bib-et-al-min: 2, cite-et-al-min: 2, disambiguate: (given-name: true, names: false, date: true)), bib: dis, cites: cs, full: false)
#case(`(names: true, given-name: false, date: true)`.text, gb7714.with(style: "author-date", bib-et-al-min: 2, cite-et-al-min: 2, disambiguate: (names: true, given-name: false, date: true)), bib: dis, cites: cs, full: false)
#case("混合制 (cite: numeric, bib: author-date) + 显式 true", gb7714.with(style: (cite: "numeric", bib: "author-date"), bib-et-al-min: 2, disambiguate: true), bib: dis, cites: cs, full: false)
