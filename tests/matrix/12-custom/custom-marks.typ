//! param: custom-marks
//! values: dictionary（entry_type → 标识码）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-marks", controls: "配置级「条目类型 → 默认标识码」登记表。",
  expect: [键 = entry_type（小写，*开放集*）；值 = 标识码本体（非空字符串），*也可是守卫串*
    `<url ? doi => EB>< => M>`（按字段分派码，与 custom-drivers 同套守卫 DSL，first-match，`< => X>` 兜底）。
    守卫结果进入取码链，供显示、码键和缺少明确出版形式时的默认归类使用；
    已有图书／期刊等结构信息不被资源代码抹去，日期按实际形式判断。守卫是 field-only（只读 bib 字段与
    entry-type，不能用 `mark`/`medium`——那正是本处要解析的码）。载体段不在此写——
    `/OL` 由 `medium` 字段与联机判据决定。
    *链位*：条目数据五通道（note 劫持 / `usera` / `entrytypeid` / `entrysubtype` / `mark`）之下、
    版本化类型默认之上——*条目字段永远压配置，配置压内置默认*。
    也可*覆写内置类型*的默认码（`(software: "SW")`）。
    登记的自造码自动并入*大写码键的合法集*：`show-mark` / `show-url` / `show-pid` 字典与 `custom-drivers`
    都能用 `(SW: ..)` 点名；专属类别仍可按码选择，但DS、CP、EB等代码不覆盖已明确的出版形式。
    没登记的自造类型兜底 `[Z]`。])
#let mk = bytes("@mytype{cm-1, author={甲}, title={自造类型}, publisher={社}, year={2020}, langid={chinese}}
@dissertation{cm-2, author={乙}, title={自造学位论文}, institution={示例大学}, address={武汉}, year={2021}, langid={chinese}}
@software{cm-3, author={丙}, title={软件}, publisher={社}, year={2020}, version={1.0}, langid={chinese}}
@misc{cm-4, author={丁}, title={条目字段 usera 压配置}, usera={XX}, year={2020}, langid={chinese}}")
#case("(:)（缺省：自造类型兜底 [Z]、software 内置 [CP]）", gb7714.with(), bib: mk, full: true)
#case(`(mytype: "XX")`.text + "（给自造类型登记码）", gb7714.with(custom-marks: (mytype: "XX")), bib: mk, full: true)
#case(`(dissertation: "D")`.text + "（登记 D → 自动按码路由进学位论文格式）", gb7714.with(custom-marks: (dissertation: "D")), bib: mk, full: true)
#case(`(software: "SW")`.text + "（覆写内置类型的默认码）", gb7714.with(custom-marks: (software: "SW")), bib: mk, full: true)
#case("条目字段压配置：`misc: \"YY\"` 遇上条目自带 usera={XX}", gb7714.with(custom-marks: (misc: "YY")), bib: mk, full: true)
#case("自造码并入大写码键合法集：show-mark: (XX: false)", gb7714.with(custom-marks: (mytype: "XX"), show-mark: (rest: true, XX: false)), bib: mk, full: true)
#case("自造码并入 custom-drivers 的码键：(XX: 模板)", gb7714.with(custom-marks: (mytype: "XX"),
  custom-drivers: (XX: "{【自造码模板】} author . title<mark-medium>")), bib: mk, full: true)
#case("三者叠：登记 + 显示控制 + 模板", gb7714.with(custom-marks: (mytype: "XX", dissertation: "D"),
  show-pid: (mytype: false), custom-drivers: (D: "{【D 格式】} creator . titles<mark-medium> . publisher")), bib: mk, full: true)
#let mk-guard = bytes("@misc{g-url, author={戊}, title={带网址杂项}, year={2021}, url={https://ex.com/x}, urldate={2023-11-05}, langid={chinese}}
@misc{g-plain, author={己}, title={无网址杂项}, year={2020}, langid={chinese}}")
#case("守卫串按字段分派：`<url ? doi => EB>< => M>`（有 url→EB 且出引用日期，无→兜底 M）",
  gb7714.with(version: 2025, custom-marks: (misc: "<url ? doi => EB>< => M>")), bib: mk-guard, full: true)
