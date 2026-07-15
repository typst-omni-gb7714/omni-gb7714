//! param: custom-drivers（条件组 ?<…> / &<…>）
//! values: 中性 <…>, 任一 ?<…>, 全部 &<…>, 前缀恒发, 嵌套, smart-join
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 条件组", controls: "按字段*空缺*决定整组去留。",
  expect: [组的判据只看*数据 token*（标识符 / 别名 / 子组），*不含字面标点*：
    - `<…>`：中性「有则显示」，等价 `?<…>`（供单 token 场景直接写）；
    - `?<…>`：*任一*非空则整组渲染，全空则整组消失；
    - `&<…>`：*全部*非空才渲染，缺一则整组消失。
    组满足条件时，组内走 *smart-join* 自动清理内部悬空分隔符；
    且*组前导前缀*（第一个数据 token 之前的字面量）**恒发**——它绑定的是「整组非空」，不会被空的首 token 吞掉。
    组内*尾部*字面量保留为后缀（`?<editor {,编}>` 这类句式）。
    语料：`bm-zh` 有 edition 与 pages、`bm-noyear` 无 year、`ti-notitle` 无 title、`aj-en` 有 volume 与 number。])
#let mixed = bytes(read("/tests/_fixture/main.bib") + read("/tests/_fixture/edge.bib"))
#let one(name, tpl) = case(name, gb7714.with(custom-drivers: (book: tpl, article: tpl)),
  cites: (<bm-zh>, <bm-noyear>, <ti-notitle>, <aj-en>, <aj-zh>), bib: mixed, full: false)
#one("?<> 任一非空：?<volume ( number )>", "author . title . journal ?<volume ( number )> . year")
#one("&<> 全部非空：&<volume ( number )>", "author . title . journal &<volume ( number )> . year")
#one("前缀恒发：?<{附：} edition note>（edition 空、note 有也出「附：」）", "author . title . ?<{附：} edition note>")
#one("对照：edition 与 note 都空 → 整组消失（含前缀）", "author . title . ?<{附：} edition note> . year")
#one("尾部字面量作后缀：?<editor {, 编}>", "author . title . ?<editor {, 编}> . publisher")
#one("组内 smart-join 清悬空分隔：?<edition , pages , number>（首 token 空也不冒悬空标点）", "author . title . ?<edition , pages , number> . year")
#one("括号要跟内容同进同退 → 把它和内容一起进组：?<edition <( number )>>", "author . title . ?<edition <( number )>> . year")
#one("对照：括号不进组 ?<edition ( number )>（组尾没有段可分隔 → 右括号留下）", "author . title . ?<edition ( number )> . year")
#one("组里多 token 任意嵌套：?<{（} volume ?<{, } number> {）}>", "author . title . ?<volume <{, } number>> . year")
#one("嵌套组：?<{（} volume ?<{, } number> {）}>", "author . title . journal ?<{（} volume ?<{, } number> {）}> . year")
#one("&< 里嵌 ?<：&<title ?<subtitle>>", "author . &<title ?<subtitle>> . year")
#one("空组不留痕：?<nonexistent-field-alike>（用 note 冒充：全空）", "author . title ?<{【} note {】}> . year")
#one("中性 <…> = ?<…>：<edition>", "author . title . <edition> . year")
#one("整条都在一个组里：&<author title year>", "&<author . title . year>")
