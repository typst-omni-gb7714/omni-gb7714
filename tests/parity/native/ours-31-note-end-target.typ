#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
#import "/lib.typ": *
#show: gb7714(version: 2015, note: "end")
= 甲章 <ch1>
注引 @k1 邻 @k1 换 @k2 。
= 乙章 <ch2>
注引 @k3 。
#pagebreak()
== 甲章尾注
#bibliography("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}
@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}", target: selector(std.cite).before(<ch2>), title: none)
== 乙章尾注
#bibliography("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}
@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}", target: selector(std.cite).after(<ch2>), title: none)
