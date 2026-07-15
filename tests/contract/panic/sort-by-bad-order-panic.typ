// sort-by 方向字典的值只收 ascending / descending。
#import "/lib.typ": *
#show: gb7714.with(full: true, bib-sort-by: (("date": "down"),))
#bibliography(bytes("@book{a, author={A}, title={T}, year={2020}}"), title: none)
