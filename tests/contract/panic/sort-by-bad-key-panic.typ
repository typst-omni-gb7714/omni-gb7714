// sort-by 非法排序键必须 panic，并列出合法键（文种不是键，报错里点明）。
#import "/lib.typ": *
#show: gb7714.with(full: true, bib-sort-by: ("auther", "date"))
#bibliography(bytes("@book{a, author={A}, title={T}, year={2020}}"), title: none)
