// style 字典只收 cite / bib 两个键，值只收 numeric / author-date / auto（CSL 全名只能写标量形态）。
#import "/lib.typ": *
#show: gb7714.with(style: (cite: "numeric", biblio: "author-date"))
#bibliography(bytes("@book{a, author={A}, title={T}, year={2020}}"))
