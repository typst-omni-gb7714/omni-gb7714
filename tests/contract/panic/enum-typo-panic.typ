// 批次三①：枚举字符串参数收到拼错的值必须 panic（此前会静默落到默认值，曾让废值 `none` 悄悄出编号）。
#import "/lib.typ": *
#show: gb7714(numbering-style: "bracet")
@a
#bibliography(bytes("@book{a, author={A}, title={T}, publisher={P}, address={C}, year={2020}}"), title: none)
