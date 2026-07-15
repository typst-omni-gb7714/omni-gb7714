//! param: custom-pids
//! values: 注册新 PID（自创键）, 覆写内置 PID（doi/cstr/isbn/issn/eprint）, field / prefix / resolver
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-pids", controls: "永久标识符入口——键是*自创名*就注册新 PID，键 ∈ 内置五名就*覆写内置* PID。",
  expect: [值为字典 `(field: .., prefix: .., resolver: ..)`：从 `field` 字段读值，标签取 `prefix`（或 `field` 名，自动补冒号、自动大写）。
    - *注册新* PID（必须给 `field`）：`(myurn: (field: "urn"))` 从 `urn` 字段读值，标签取 `field` 名；
    - *值自带的「标签：」头会被剥掉*——渲染是「标签 + 冒号 + 值」，用户照着输出的样子写
      `urn = {URN:ISBN:978-…}`，包不该再补一遍标签（否则出 `URN:URN:ISBN:…`）。国标 §7.9.1 示例 2
      的 PID 就是 `URN:ISBN:978-951-51-2090-8` 这个形态。内置 `eprint`（`arXiv:2301.x`）与 `cstr` 同规；
    - *`eprint` 的平台解析表*：`resolver` 收*按平台的字典*（键 = `archiveprefix`，大小写、空格、连字符
      都不敏感），覆写或补充内置六家（arXiv / PubMed / ChinaXiv / bioRxiv / Research Square / OSF）。
      表里没有的平台*编号照样著录*，只是不可点击、2025 版也合不出获取路径；
    - *覆写内置* PID（`field` 可省，缺则读默认字段）：`(doi: (resolver: "https://doi.company.com/{}"))` 换机构镜像、
      `(isbn: (prefix: "书号"))` 改标签、`(doi: (field: "mydoi"))` 让 DOI 改读别的字段。
    *可点击跳转*（`hyperlink: true` 时）：值本身是 URL 就链到自身；否则走 `resolver` 模板——
    含 `{}` 占位则替换字段值、否则当前缀拼接。
    均著录于条目末尾「获取和访问路径」区，配合 `show-pid` / `pid-priority` / `dedup-url-pid` 使用。
    *限制*：新 PID 名不与内置 token 同名；新 PID 的 `field` 不与内部已用字段名冲突；
    永久标识符*不作 `custom-drivers` 模板 token*（模板里要整块请用内置 `access` token）。])
#let cp = bytes("@article{cp-1, author={甲}, title={带 URN 与 Handle}, journaltitle={刊}, year={2023}, volume={1}, pages={1--10}, urn={urn:nbn:de:1234}, handle={20.500/abc}, doi={10.1234/x}, langid={chinese}}
@book{cp-2, author={乙}, title={带 ISBN}, isbn={978-7-111-11111-1}, address={北京}, publisher={社}, year={2020}, langid={chinese}}
@article{cp-3, author={丙}, title={自定义 DOI 字段}, journaltitle={刊}, year={2023}, volume={2}, pages={1--5}, mydoi={10.9999/custom}, langid={chinese}}
@book{cp-4, author={丁}, title={国标原文形态的 URN}, address={Helsinki}, publisher={P}, year={2016}, urn={URN:ISBN:978-951-51-2090-8}, langid={english}}
@preprint{cp-5, author={戊}, title={内置表没有的平台}, year={2023}, eprint={4321098}, archiveprefix={SSRN}, langid={english}}")
#let one(name, cfg) = case(name, cfg, bib: cp, full: true)
#one("(:)（缺省：DOI 出、ISBN 不出）", gb7714.with())
#one("注册新 PID：(myurn: (field: \"urn\"))", gb7714.with(custom-pids: (myurn: (field: "urn")), show-pid: (rest: true)))
#one("注册新 PID + prefix + resolver（可点击）", gb7714.with(
  custom-pids: (handle: (field: "handle", prefix: "HDL", resolver: "https://hdl.handle.net/")), show-pid: (rest: true)))
#one("resolver 带 {} 占位", gb7714.with(
  custom-pids: (handle: (field: "handle", prefix: "HDL", resolver: "https://example.org/resolve?id={}")), show-pid: (rest: true)))
#one("覆写内置：(doi: (resolver: \"https://doi.company.com/{}\"))", gb7714.with(custom-pids: (doi: (resolver: "https://doi.company.com/{}"))))
#one("覆写内置：(isbn: (prefix: \"书号\"))", gb7714.with(custom-pids: (isbn: (prefix: "书号")), show-pid: (isbn: true)))
#one("覆写内置：(doi: (field: \"mydoi\"))（DOI 改读别的字段）", gb7714.with(custom-pids: (doi: (field: "mydoi"))))
#one("与 show-pid 联动：(myurn: false)", gb7714.with(custom-pids: (myurn: (field: "urn")), show-pid: (rest: true, myurn: false)))
#one("与 pid-priority 联动：URN 排到 DOI 之前", gb7714.with(custom-pids: (myurn: (field: "urn")), show-pid: (rest: true), pid-priority: ("myurn", "doi")))
#one("与 show-pid.max 联动：max: 1", gb7714.with(custom-pids: (myurn: (field: "urn")), show-pid: (rest: true, max: 1), pid-priority: ("myurn", "doi")))
#one("剥前缀：urn = {URN:ISBN:978-…} 不出双前缀（国标 §7.9.1 示例 2 的形态）", gb7714.with(
  custom-pids: (urn: (field: "urn", prefix: "URN")), show-pid: (rest: true)))
#one("eprint 平台解析表：内置没有 SSRN → 编号照印、不可点", gb7714.with(version: 2025))
#one("eprint 平台解析表：补上 SSRN → 2025 版合成获取路径", gb7714.with(version: 2025,
  custom-pids: (eprint: (resolver: (ssrn: "https://papers.ssrn.com/sol3/papers.cfm?abstract_id={}")))))
#one("平台键大小写/空格/连字符不敏感（写 S-S-R-N 也命中）", gb7714.with(version: 2025,
  custom-pids: (eprint: (resolver: ("s-s-r-n": "https://example.org/{}")))))
