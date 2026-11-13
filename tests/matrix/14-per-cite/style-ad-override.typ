//! param: cite(style: "author-date") 覆写 · 顺序编码制全局
//! values: 同责任者同年 → 覆写成著者-出版年制时后缀 a/b 照出
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite(style: author-date) 覆写下的消歧后缀",
  expect: [全局*顺序编码制*下，年份消歧被门控跳过（省算，见 api.typ 的 `_need-global-disambig`）。
    但个别 `#cite(<key>, style: "author-date")` 把某条标注临时切成著者-出版年制时，per-list 消歧
    （不受全局门控管）照常算，同责任者同年的 a/b 后缀必须照出——锁住「优化不误伤 per-cite 覆写」。
    单区块文件：per-cite `#cite(style:)` 覆写在多区块文档里另有既有收敛隐患（与本优化无关，见 BUGS），
    故隔离成独立一档。])
#let ad = bytes(
  "@article{ov1, author={钱一}, title={甲}, journaltitle={刊}, year={2021}, volume={1}, pages={1}, langid={chinese}}\n" +
  "@article{ov2, author={钱一}, title={乙}, journaltitle={刊}, year={2021}, volume={2}, pages={2}, langid={chinese}}")
#cite-only("顺序编码制全局 + 本次覆写著者-出版年制", gb7714.with(), bib: ad,
  body: [顺序编码制 #cite(<ov1>)#cite(<ov2>)；覆写著者-出版年制 #cite(<ov1>, style: "author-date") #cite(<ov2>, style: "author-date")])
