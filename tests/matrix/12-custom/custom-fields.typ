//! param: custom-fields
//! values: auto（纯透传）, (field:, prefix:, suffix:), 多语言前后缀
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-fields", controls: "把 `.bib` 字段暴露成 `custom-drivers` 模板里可用的 token，可选加本地化前后缀。",
  expect: [- `auto`（*纯透传*，字段名 == token 名）：`(myarxiv: auto)` 后模板里 `myarxiv` 直接读该字段原值；
    - 字典 `(field: "xxx", prefix: .., suffix: ..)`：读 `xxx` 字段并在前 / 后拼固定文本。
      `prefix` / `suffix` 收字符串或*多语言字典*（按*条目语言*择一）；*字段缺失则该 token 为空*
      （于是能被条件组与别名链正常处理）。
    字段值同其它显示字段走 LaTeX→Typst 处理（`\textbf{}` / 引号连字 / 转义正常，未定义命令优雅降级）。
    *限制*：token 名不与内置 token 同名；`field` 取值不能与本包内部已用字段名冲突（撞了 panic）。])
#let cf = bytes("@book{cf-1, author={甲}, title={有自定义字段}, myfield={自定义值}, userref={hello}, address={北京}, publisher={社}, year={2020}, langid={chinese}}
@book{cf-2, author={Smith, John}, title={English Entry}, myfield={custom value}, address={NY}, publisher={P}, year={2021}, langid={english}}
@book{cf-3, author={丙}, title={没有自定义字段}, address={北京}, publisher={社}, year={2020}, langid={chinese}}
@book{cf-4, author={丁}, title={字段里有 LaTeX}, myfield={\\textbf{粗体} 与 \\& 转义}, address={北京}, publisher={社}, year={2020}, langid={chinese}}")
#let one(name, cfg) = case(name, cfg, bib: cf, full: true)
#one("auto（纯透传）", gb7714.with(custom-fields: (myfield: auto), custom-drivers: (book: "author . title . {myfield=} myfield")))
#one("(field: \"userref\", prefix: \"abc: \")", gb7714.with(custom-fields: (myref: (field: "userref", prefix: "abc: ")), custom-drivers: (book: "author . title . myref")))
#one("prefix + suffix", gb7714.with(custom-fields: (myf: (field: "myfield", prefix: "【", suffix: "】")), custom-drivers: (book: "author . title . myf")))
#one("多语言 prefix（按条目语言择一）", gb7714.with(custom-fields: (myf: (field: "myfield", prefix: (zh: "见：", en: "See: "))), custom-drivers: (book: "author . title . myf")))
#one("字段缺失 → token 为空（条件组正常判空）", gb7714.with(custom-fields: (myf: (field: "myfield", prefix: "【", suffix: "】")), custom-drivers: (book: "author . title ?<{ 附注：} myf> . year")))
#one("别名链回退：myfield | 字面量", gb7714.with(custom-fields: (myfield: auto), custom-drivers: (book: "author . title . myfield | {（无自定义字段）}")))
#one("字段值走 LaTeX 处理", gb7714.with(custom-fields: (myf: (field: "myfield")), custom-drivers: (book: "author . title . myf")))
