#[在 scope 里 @ka] <s1>
#bibliography(bytes("@book{ka, author={Alpha, A}, title={Book A}, publisher={P}, year={2020}}\n@book{kb, author={Beta, B}, title={Book B}, publisher={Q}, year={2021}}"), title: "AUTO表")
#bibliography(bytes("@book{ka, author={Alpha, A}, title={Book A}, publisher={P}, year={2020}}"), title: "TARGET表", target: selector(std.cite).within(<s1>))
