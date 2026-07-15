// custom-fields 的 `field` 取值撞了本包内部已用的字段名 → panic。
#import "/lib.typ": *
#show: gb7714.with(custom-fields: (kw: (field: "keywords", prefix: "关键词：")))
#bibliography(bytes("@book{a, author={甲}, title={t}, keywords={k}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
