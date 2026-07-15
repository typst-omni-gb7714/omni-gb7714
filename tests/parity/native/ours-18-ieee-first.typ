#import "/lib.typ": *
#show: gb7714(version: 2015, )
一 @k1 @k2 二 @k3
#bibliography("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}\n@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}", title: "IEEE", style: "ieee")
#bibliography("@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}", title: "GBN")
