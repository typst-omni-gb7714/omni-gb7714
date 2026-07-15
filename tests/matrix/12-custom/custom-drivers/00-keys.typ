//! param: custom-drivers（键：entry_type 小写 / 标识码大写）
//! values: 小写键, 大写码键, 优先级, 自造类型, 未命中类型走内置
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 键", controls: "哪些条目被模板接管。",
  expect: [字典 `(<键>: "模板串")`，键有两种，*优先级 entry_type > 码*：
    - *小写键 = entry_type*：点名 `.bib` 里的类型（`patent` / `inproceedings`，含 `@standard` 一类非 crate 标准类型，也含自造类型）；
    - *大写键 = 文献类型标识码*（附录 A 闭集，并入 `custom-marks` 登记的自造码）：按*版本中性语义类*匹配——
      `D:` 一键接管全部学位论文、`J:` 接管全部期刊（`PP:` 在 2015 下同样命中预印本，尽管渲染成 `[A]`）。
    命中的模板*覆盖该类条目的全部内置格式逻辑*；没被点名的类型继续走内置格式，不受影响。
    *内部类别词*（`monograph` / `component-part` / `serial-article` / `serial` / `electronic`）不是用户词汇，
    写了报错并给出改写指引（那条在 `contract/panic/`）。])
#let cs = (<bm-zh>, <aj-zh>, <dt-zh>, <st-zh>)
#case("不传（全部走内置）", gb7714.with(), cites: cs, full: false)
#case("小写键 book（只接管 @book）", gb7714.with(custom-drivers: (book: "author {｜} title {｜} publisher")), cites: cs, full: false)
#case("大写码键 J（接管全部期刊）", gb7714.with(custom-drivers: (J: "author {《} journal {》} year")), cites: cs, full: false)
#case("大写码键 D（一键接管全部学位论文）", gb7714.with(custom-drivers: (D: "author . title mark-medium . {学位授予单位：} publisher . year")), cites: cs, full: false)
#case("优先级：entry_type 胜过码（thesis 与 D 同时命中 → 走 thesis）", gb7714.with(custom-drivers: (
  thesis: "{[按 entry_type]} author . title",
  D: "{[按码 D]} author . title")), cites: cs, full: false)
#case("@standard（非 crate 标准类型）也能点名", gb7714.with(custom-drivers: (standard: "{【标准】} number . title")), cites: cs, full: false)
#case("自造类型 + custom-marks 登记码", gb7714.with(
  custom-marks: (mytype: "XX"),
  custom-drivers: (mytype: "author . title mark-medium . publisher , year")),
  bib: bytes("@mytype{ct-1, author={甲}, title={自造类型条目}, publisher={社}, year={2020}, langid={chinese}}"), full: true)
#case("自造类型只登记码、不写模板（按码路由进内置八驱动）", gb7714.with(custom-marks: (dissertation: "D")),
  bib: bytes("@dissertation{ct-2, author={乙}, title={自造学位论文}, institution={示例大学}, address={武汉}, year={2021}, langid={chinese}}"), full: true)
#case("自造类型什么都不配（兜底 [Z]）", gb7714.with(),
  bib: bytes("@mytype{ct-3, author={丙}, title={没配任何东西}, publisher={社}, year={2020}, langid={chinese}}"), full: true)
