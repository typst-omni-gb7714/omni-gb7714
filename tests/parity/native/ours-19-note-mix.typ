#import "/lib.typ": *
#show: gb7714(version: 2015, )
一 @k1 二 @k2
#bibliography("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}", title: "NOTE", style: "gb-7714-2015-note")
#bibliography("@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}", title: "GBN")
