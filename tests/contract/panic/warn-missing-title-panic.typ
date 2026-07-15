// warn-missing-title: true 遇到缺题名的条目 → 载入期报错并指明该键。
// （矩阵里放不下这一档：它扫的是*整个文档*的 bib 数据，一处缺题名就整篇编不过。）
#import "/lib.typ": *
#show: gb7714.with(warn-missing-title: true)
#bibliography(bytes("@book{no-title, author={甲}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
