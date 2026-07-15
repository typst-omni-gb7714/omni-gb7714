// titles-text-case 白名单外键必 panic（shortjournal 明确不受理：缩写刊名大小写即其规范）。
#import "/lib.typ": *
#show: gb7714(titles-text-case: (shortjournal: "title"))
@a
#bibliography(bytes("@book{a, author={A}, title={T}, publisher={P}, year={2020}}"), title: none)
