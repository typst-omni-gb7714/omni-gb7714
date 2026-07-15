// 守卫的 `=` 后面缺值 → panic（判「字段为空」是条件组 ?<…> 的活，守卫写不出空值）。
#import "/lib.typ": *
#show: gb7714.with(custom-drivers: (book: "author . title <note= => {x}>"))
#bibliography(bytes("@book{a, author={甲}, title={t}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
