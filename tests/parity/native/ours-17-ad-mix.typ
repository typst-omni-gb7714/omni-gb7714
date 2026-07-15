#import "/lib.typ": *
#show: gb7714(version: 2015, )
一 @k1 二 @k2 三 @k3
#bibliography("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}", title: "N1")
#bibliography("@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}", title: "AD", style: "author-date")
#bibliography("@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}", title: "N2")
