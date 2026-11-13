// emphasis 用裸 .bib 字段名（booktitle）作槽 → panic 并指路到合成体槽名 booktitles。
#import "/lib.typ": *
#show: gb7714.with(emphasis: (booktitle: (italic: true)))
#bibliography(bytes("@book{a, author={甲}, title={t}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
