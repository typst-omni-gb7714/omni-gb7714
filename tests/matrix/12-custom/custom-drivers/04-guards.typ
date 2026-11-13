//! param: custom-drivers（守卫 <EXPR => body>）
//! values: 原子 =/!=, 值或 ?, 与 &, 或 ?, 非 !, 分组 <…>, 嵌套, mark/medium/entry-type/bib 字段, otherwise 兜底, built-in 回落
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 守卫", controls: "按字段*取值*决定 body 渲不渲染（与条件组的*空缺*判断正交）。",
  expect: [组内写 `EXPR => body`，只在布尔谓词成立时渲染 body。
    *原子* `field=value` / `field!=value`：
    `mark` 比*文献类型标识码*、`medium` 比*载体码*、`entry-type` 比*条目类型*、其余一律比 *bib 字段值*
    （`langid=english`、`type=技术报告`），缺失字段当空串。
    规则：*带连字符的是包算出来的量*（`entry-type`、`entry-lang`），*不带连字符的一律是 bib 字段*（biblatex 字段名不含连字符）。
    `entry-lang` 比 omni *检测出的*条目语言码（`zh`/`en`…，过 `language.get`：先读 langid 字段、读不到按字形猜），
    与裸 `langid=` 字段比较不同——后者只认写了 langid 的条目，前者没写 langid 的中文条目也认得出。
    *空非空原子*：光秃秃一个 `field`——问「这个 token *渲染出来*空不空」，
    因此*过 `show-*` 门控与整条取码链*（`show-mark: false` 时 `<mark => …>` 为假）。
    取非用前缀 `!`（`!medium` = 没有载体码）。
    两种原子问的不是一回事，这是有意的：`mark=M` 问*数据*（这条目的码是不是 M，不过门控），
    `mark` 问*结果*（渲出来有没有东西，过门控）。
    *值或* `field=v1?v2`（同字段多候选任一命中）；*与* `&`；*或* `?`；*非* `!`（前缀，等价 `field!=v`）；
    优先级 `!` > `&` > `?`；*分组* `<…>` 作布尔括号覆盖优先级。
    ⚠️ `?` 身兼两职（算符「或」与同字段的「值或」）。它后面跟*裸 token 名*时两种读法都说得通，
    引擎*报错指路*而不是静默挑一种：要问空非空写 `? <doi>`，要当取值写 `?{doi}`。
    值要含空格或冒号，用花括号 verbatim（`t={New York}`）。
    body 可以是纯 verbatim、也可含 token；body 的*空非空*控制照旧靠*嵌套*条件组。
    *一个守卫组恰有一个 `=>`*——写多了或写在组外都报错（那两条在 `contract/panic/`）。
    ⚠️ `note=` 与 `note={}` 仍报「`=` 后缺值」——问空非空的写法是*光秃秃的* `note`，不是空值比较。

    *otherwise 兜底* `< => body>`：`=>` 左边空着，语义是「同一层的兄弟节点里没有任何别的守卫命中时才渲染」。
    守卫组本身是*并列*求值的（两个都为真就都渲染，不是 first-match），otherwise 是这条规则唯一的例外。
    作用域按*同级*算：顶层的 otherwise 看顶层的守卫，组体内的看组体内的。

    `built-in` *token*：渲染成「这条本来会走的内置驱动的完整输出」，配 otherwise 就是
    「我只定制一部分、其余照内置」——省掉把内置模板整段抄一遍（抄件还会随版本漂移）。
    回落条目要与*不写* `custom-drivers` 时逐字相同，末尾句点与类型标识码也一致
    （单块退化改用内置那套按数据元素组数的判据）。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let types = (book: none, article: none, thesis: none, online: none, report: none, incollection: none)
#let ALL = "creator . titles <mark=M => { ←M 图书}> <mark=J => { ←J 期刊}> <mark=D => { ←D 学位}> <mark=EB => { ←EB 电子}> <mark=R => { ←R 报告}> <mark=G => { ←G 汇编}> <mark=A => { ←A 析出}>"
#let one(name, tpl) = case(name, gb7714.with(custom-drivers: (
    book: tpl, article: tpl, thesis: tpl, online: tpl, report: tpl, incollection: tpl)),
  cites: (<bm-zh>, <aj-en>, <dt-zh>, <eb-zh>, <rp-zh>, <ic-zh>), bib: mixed, full: false)
#one("原子 mark=X（逐码点名）", ALL)
#one("原子 mark!=J（非期刊）", "creator . titles <mark!=J => { ←不是期刊}>")
#one("非号 !mark=J（等价 mark!=J）", "creator . titles <!mark=J => { ←不是期刊}>")
#one("值或 mark=M?R（图书或报告）", "creator . titles <mark=M?R => { ←图书或报告}>")
#one("值或多字符码 mark=EB?D", "creator . titles <mark=EB?D => { ←电子或学位}>")
#one("bib 字段 langid=english", "creator . titles <langid=english => { ←英文条目}> <langid=chinese => { ←中文条目}>")
#one("bib 字段 type=phdthesis（学位类型原值）", "creator . titles <type=phdthesis => { ←博士论文}>")
#one("包算量 entry-type=incollection", "creator . titles <entry-type=incollection => { ←析出条目}>")
#one("包算量 entry-lang=zh（检测语言，非 langid 字段）", "creator . titles <entry-lang=zh => { ←检测中文}> <entry-lang=en => { ←检测英文}>")
#one("载体码 medium=OL", "creator . titles <medium=OL => { ←联机}>")
#one("与 &：mark=M & langid=chinese", "creator . titles <mark=M & langid=chinese => { ←中文图书}>")
#one("或 ?：mark=J ? mark=D", "creator . titles <mark=J ? mark=D => { ←期刊或学位}>")
#one("优先级 ! > & > ?：!mark=J & langid=chinese ? mark=EB", "creator . titles <!mark=J & langid=chinese ? mark=EB => { ←命中}>")
#one("分组改优先级：<mark=M ? mark=J> & langid=english", "creator . titles <<mark=M ? mark=J> & langid=english => { ←英文的图书或期刊}>")
#one("守卫 body 含 token：<mark=D => {学位授予单位：} publisher>", "creator . titles <mark=D => { 学位授予单位：} publisher>")
#one("守卫里嵌条件组：<mark=A => &<editor booktitles>>", "creator . titles <mark=A => { 母体：} &<editor {, 编} . booktitles>>")
#one("守卫嵌守卫：<mark=M => <langid=chinese => {中文图书}>>", "creator . titles <mark=M => { } <langid=chinese => {←中文图书}> <langid=english => {←英文图书}>>")
#one("verbatim 值（含空格）：address={New York}", "creator . titles <address={New York} => { ←纽约出版}>")
#one("缺失字段当空串：<note!=x => …> 对无 note 的条目为真", "creator . titles <note!=x => { ←没有 note（或 note 不等于 x）}>")
#one("空非空原子：<doi => …> / <!doi => …>", "creator . titles <doi => { ←有 DOI}> <!doi => { ←没有 DOI}>")
#one("空非空原子过门控：<mark => …>（show-mark 关掉即为假，见下一档）", "creator . titles <mark => { ←mark 渲得出来}> <!mark => { ←mark 渲不出来}>")
#one("空非空与取值的分工：<mark=M => …> 不过门控、<mark => …> 过门控", "creator . titles <mark=M => { ←数据上是 M}> <mark => { ←渲得出 mark}>")
#one("与 / 或 / 非 自由组合：<mark=J & !doi => …>", "creator . titles <mark=J & !doi => { ←期刊且无 DOI}>")
#one("或的右操作数是空非空原子时要包起来：<mark=M ? <doi> => …>", "creator . titles <mark=M ? <doi> => { ←图书或有 DOI}>")
#one("精确复现内置 mark-medium：<mark => {[}mark<{/}medium>{]}>", "creator . titles <mark => {[}mark<{/}medium>{]}> . publisher")
#let MM = "creator . titles <mark => {[}mark<{/}medium>{]}> . publisher"
#case("同上 · show-mark: false（守卫为假 → 整块不出，与内置 mark-medium 逐字一致）",
  gb7714.with(custom-drivers: (book: MM, article: MM, thesis: MM, online: MM, report: MM, incollection: MM), show-mark: false),
  cites: (<bm-zh>, <aj-en>, <eb-zh>), bib: mixed, full: false)
#case("对照 · 内置 mark-medium token · show-mark: false",
  gb7714.with(custom-drivers: (book: "creator . titles<mark-medium> . publisher"), show-mark: false),
  cites: (<bm-zh>,), bib: mixed, full: false)
#case("otherwise `< => …>`：中文条目走兜底、西文走命中的那支",
  gb7714.with(custom-drivers: (book: "<entry-lang=en => {[EN] }author{, }title{.}>< => {[兜底] }creator{. }titles{.}>")),
  cites: (<bm-zh>, <bm-en>), bib: mixed, full: false)
#case("otherwise 不与命中的分支叠加（两个守卫都为真时并列渲染，otherwise 不出）",
  gb7714.with(custom-drivers: (book: "creator{. }<mark=M => {甲}><entry-lang=zh => {乙}>< => {兜底}>")),
  cites: (<bm-zh>,), bib: mixed, full: false)
#case("otherwise 嵌在组体内（作用域按同级算）",
  gb7714.with(custom-drivers: (book: "creator{. }<<entry-lang=en => {[EN]}>< => {[其他]}>>{.}")),
  cites: (<bm-zh>, <bm-en>), bib: mixed, full: false)
#case("built-in 回落：与不写 custom-drivers 逐字相同（对照下一例）",
  gb7714.with(custom-drivers: (book: "<entry-lang=en => {[EN] }author{, }title{.}>< => built-in>")),
  cites: (<bm-zh>, <bm-en>), bib: mixed, full: false)
#case("对照 · 完全不写 custom-drivers", gb7714.with(), cites: (<bm-zh>, <bm-en>), bib: mixed, full: false)
#case("built-in 与字面量并列 / 在可选组内",
  gb7714.with(custom-drivers: (book: "built-in{ ←内置}", article: "<built-in>")),
  cites: (<bm-zh>, <aj-en>), bib: mixed, full: false)
