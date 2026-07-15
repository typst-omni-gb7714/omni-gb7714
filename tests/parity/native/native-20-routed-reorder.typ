#[早 @p1 @p2] <sec>
晚 @a @b
#bibliography(bytes("@book{a, author={Alpha, A}, title={Book A}, publisher={P}, year={2020}}\n@book{b, author={Beta, B}, title={Book B}, publisher={Q}, year={2021}}"), title: "主表")
#bibliography(bytes("@book{p1, author={Pone, P}, title={Paper One}, publisher={R}, year={2022}}\n@book{p2, author={Ptwo, P}, title={Paper Two}, publisher={S}, year={2023}}"), title: "副表", target: selector(std.cite).within(<sec>))
