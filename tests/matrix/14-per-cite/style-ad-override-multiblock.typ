//! param: cite(style: "author-date") 覆写 · 多区块下后缀各表独立
//! values: numeric 表不冲掉 AD 覆写的后缀（#20 浅）；两张 AD 主表各存各的后缀（#20 深）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite(style: author-date) · 多区块后缀独立",
  expect: [BUGS #20 回归。多张文献表触发 0.15 原生路由（native 模式），消歧后缀表 `_list-suffix-map`
    此时按 *bib 实例索引*建键（而非共用主列表空串 `""`），cite 标签按其 marker 携带的 bib-index 合并回读。

    *浅层*：块一 author-date 覆写算出 `a`/`b`，块二纯顺序编码文献表随后渲染——修复前它往 `""` 写空后缀
    经 `.final()` 冲掉块一后缀。修复后块一标注仍为 `(钱一, 2021a, 2021b)`。

    *深层*：块三、块四各是一张 author-date 主表、各含一对同责任者同年——修复前靠后那张的后缀盖掉靠前的
    （行内标注与其文献表后缀不一致）。修复后*两块行内标注都带各自的 a/b*。四块都不得报未收敛。])
#let ad = bytes(
  "@article{ov1, author={钱一}, title={甲}, journaltitle={刊}, year={2021}, volume={1}, pages={1}, langid={chinese}}\n" +
  "@article{ov2, author={钱一}, title={乙}, journaltitle={刊}, year={2021}, volume={2}, pages={2}, langid={chinese}}\n" +
  "@article{sun1, author={孙三}, title={丙}, journaltitle={报}, year={2018}, volume={1}, pages={1}, langid={chinese}}\n" +
  "@article{sun2, author={孙三}, title={丁}, journaltitle={报}, year={2018}, volume={2}, pages={2}, langid={chinese}}")
// 浅层：AD 覆写 + 随后 numeric 表
#case("块一 顺序编码全局 + 覆写著者年制（同年 → a/b）", gb7714.with(), bib: ad, cites: (<ov1>, <ov2>), full: false,
  body: [覆写 #cite(<ov1>, style: "author-date") #cite(<ov2>, style: "author-date")])
#case("块二 纯顺序编码文献表（不得冲掉块一后缀）", gb7714.with(), bib: ad, cites: (<ov1>,), full: false,
  body: [顺序 #cite(<ov1>)])
// 深层：两张 author-date 主表各含一对同年，各自后缀须独立保留
#case("块三 著者年制主表（钱一同年 → a/b）", gb7714.with(style: "author-date"), bib: ad, cites: (<ov1>, <ov2>), full: false,
  body: [钱 #cite(<ov1>)#cite(<ov2>)])
#case("块四 著者年制主表（孙三同年 → a/b，且不夺块三后缀）", gb7714.with(style: "author-date"), bib: ad, cites: (<sun1>, <sun2>), full: false,
  body: [孙 #cite(<sun1>)#cite(<sun2>)])
