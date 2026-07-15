// footnote-repeat-reset 值域：只收 none 或 selector（含标签/元素函数），字符串 panic。
#import "/lib.typ": *
#show: gb7714.with(version: 2015, cite-footnote: true, footnote-repeat-reset: "heading-1")
A #cite(<ya>)
#bibliography(bytes("@book{ya, author={张三}, title={甲}, year={2020}, address={B}, publisher={P}}"), title: none)
