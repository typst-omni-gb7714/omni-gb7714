//! param: component-part-separator
//! values: 默认 //, 字符串, 多语言字典
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "component-part-separator", controls: "析出文献题名与其*出处*（母体：图书 / 论文集 / 会议名称）之间的分隔符——GB/T 7714 里那个 `//`。",
  expect: [默认 `"//"` 是 GB 全语言通用的析出符（`析出题名//母体`）。biblatex-gb7714（胡振震）
    整节称它「*析出文献标识符号*」（`gbpunctin` 选项），标准 3.8 术语「析出文献 / component part」，
    陈浩元称「*出处项前标识符号*」；语义是「析出文献*登载于*母体之中」（旧著录写「见:」/「In:」同此意）。

    收字符串（所有语言）或多语言字典（按*条目语言*分设、未点名的回落 `"//"`）。值是*完整分隔串*，
    前导符含在里面（如 `. 见: ` 自带前导句点）。冒号等标点*逐字使用、不感知*，按 `bib-punct-style`
    自己写（默认半角 `见: `、`full` 档全角 `见：`）。纯著录符号，引文里永不出现，故无 `cite-` 对应。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/roles.bib"))
#let cs = (<ic-zh>, <rl-part-en>)
#case("默认 //（GB 全语言通用）", gb7714.with(), bib: mixed, cites: cs, full: false)
#case(`". 见: "`.text + "（旧式，所有语言一律用）", gb7714.with(component-part-separator: ". 见: "), bib: mixed, cites: cs, full: false)
#case("多语言字典 (zh: 「. 见: 」, en: 「. In: 」)", gb7714.with(component-part-separator: (zh: ". 见: ", en: ". In: ")), bib: mixed, cites: cs, full: false)
#case("未点名的语言回落 //（只设 zh，en 条目仍 //）", gb7714.with(component-part-separator: (zh: ". 见: ")), bib: mixed, cites: cs, full: false)
