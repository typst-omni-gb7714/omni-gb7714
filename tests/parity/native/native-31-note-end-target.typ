#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
= 甲章 <ch1>
@k1 @k2
= 乙章 <ch2>
@k3
#bibliography(bytes("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}
@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}"), target: selector(std.cite).before(<ch2>))
#bibliography(bytes("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}
@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}"), target: selector(std.cite).after(<ch2>))
