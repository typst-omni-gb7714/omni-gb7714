// footnote-repeat-style 值域外一律 bad-value（含旧两槽字典——迁移文案已按「未发布不指路」清理）。
#import "/lib.typ": *
#show: gb7714.with(cite-footnote: true, footnote-repeat-style: (adjacent: "ibid", subsequent: "short"))
A @ya
#bibliography(bytes("@book{ya, author={张三}, title={甲}, year={2020}, address={B}, publisher={P}}"), title: none)
