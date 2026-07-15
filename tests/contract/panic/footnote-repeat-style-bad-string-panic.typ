// 旧值字符串（"short" 等）不再有等价表指路，与任何值域外字符串同走 bad-value。
#import "/lib.typ": *
#show: gb7714.with(cite-footnote: true, footnote-repeat-style: "short")
A @ya
#bibliography(bytes("@book{ya, author={张三}, title={甲}, year={2020}, address={B}, publisher={P}}"), title: none)
