// disambiguate 字典只收 date / given-name / names 三键。
#import "/lib.typ": *
#show: gb7714.with(disambiguate: (given-nmae: true))
#bibliography(bytes("@book{a, author={A}, title={T}, year={2020}}"))
