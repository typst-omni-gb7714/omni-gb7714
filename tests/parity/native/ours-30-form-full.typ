#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// omni 对照 native-30：`#cite(<k>, form: "full")` 原位完整条目。
// 顺序编码制 `[1] ALPHA A, BRAVO B. 书名[M]. [出版地不详]: 社, 2020`（缺出版地+有出版者→auto 条件补白）；
// 著者-出版年制则带「作者，年」前缀。复用
// `_emit-entry` / `_emit-entry-author-date`（与文献表同一渲染）。修复前 ours 对 form:"full" panic 拒绝；
// 现支持、逐字节对齐原生。
// ⚠️语料刻意用**两个**责任者：唯一能分辨「取文献表侧还是引用侧 et-al 阈值」的临界值——缺省
//   bib-et-al-min=4（2<4 不截断、出全名）vs cite-et-al-min=2（2>=2 截成「ALPHA A, et al」）。单责任者
//   时两侧结果相同，对这一点是**空证**。因复用 `_emit-entry`，本包取文献表侧，与原生实测一致。
//   别把语料简化回一个责任者。
#import "/lib.typ": *
#show: gb7714(version: 2015)
前 #cite(<k>, form: "full") 后
#bibliography("@book{k, author={Alpha, A and Bravo, B}, title={书名}, publisher={社}, year={2020}}", title: none)
