#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "同名区块的稳定身份")
#let data = bytes("@book{one,author={Firstauthor, Anne},title={Firstbook},year={2020},langid={english}}
@book{two,author={Secondauthor, Bob},title={Secondbook},year={2021},langid={english}}")
#case("相同显示名", gb7714.with(), id: "first", bib: data, cites: (<one>,), full: false)
#case("相同显示名", gb7714.with(), id: "second", bib: data, cites: (<two>,), full: false)
