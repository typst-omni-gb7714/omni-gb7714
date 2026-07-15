//! combo: 取码链 × custom-marks × custom-drivers × show-mark（码即身份）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：码即身份", controls: "标识码怎么定，定了之后牵动格式路由与显示控制。",
  expect: [*取码链*（自上而下，先命中先赢）：
    note 劫持 > `usera` > `entrytypeid` > `entrysubtype` > `mark` 字段 > `custom-marks` > 版本化默认 > auto-table。
    **条目字段永远压配置，配置压内置默认。**
    码定了之后：
    - *格式路由*按码走（拿到 `D` 就走学位论文驱动）——「码即身份」；
    - `show-mark` / `show-url` / `show-pid` 的*大写码键*按码匹配（`custom-marks` 登记的自造码自动并入合法集）；
    - `custom-drivers` 的*大写码键*按码匹配（优先级仍是 entry_type > 码）。
    语料 `mk-*` 五条正是取码链的五个通道。])
#let one(name, cfg) = case(name, cfg, bib: EDGE, cites: (<mk-usera>, <mk-entrytypeid>, <mk-mark>, <mk-subtype>, <mk-none>), full: false)
#one("缺省（五个通道各自生效，mk-none 兜底）", gb7714.with())
#one("custom-marks: (misc: \"YY\") —— 配置压内置默认，但压不过条目字段", gb7714.with(custom-marks: (misc: "YY")))
#one("show-mark 按码关：(rest: true, S: false)（mk-mark 的 [S] 消失）", gb7714.with(show-mark: (rest: true, S: false)))
#one("show-mark 按 entry_type 关：(misc: false)（五条全关）", gb7714.with(show-mark: (misc: false)))
#one("优先级：entry_type 键胜过码键 (misc: true, S: false)", gb7714.with(show-mark: (misc: true, S: false)))
#one("custom-drivers 按码接管：(J: 模板)（mk-entrytypeid 走模板）", gb7714.with(custom-drivers: (J: "{【J 模板】} author . title")))
#one("custom-drivers 按 entry_type 接管：(misc: 模板)（五条全走模板，优先于码键）", gb7714.with(
  custom-drivers: (misc: "{【misc 模板】} author . title", J: "{【J 模板】} author . title")))
#one("custom-marks 自造码 + show-mark + custom-drivers 三者按码串起来", gb7714.with(
  custom-marks: (misc: "YY"), show-mark: (rest: true), custom-drivers: (YY: "{【YY 模板】} author . title<mark-medium>")))
