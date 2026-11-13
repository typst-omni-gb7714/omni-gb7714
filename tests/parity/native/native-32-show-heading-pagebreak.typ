#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
#show heading: it => { pagebreak(); it }
A @k1@k2@k3
#bibliography(bytes("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}
@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}"))
