// 守卫里 `?` 后面跟裸 token 名 → 两种读法都说得通 → 报错指路（不静默按值或解析）。
#import "/lib.typ": *
#show: gb7714.with(custom-drivers: (book: "author . title <mark=M ? doi => {x}> . year"))
#bibliography(bytes("@book{p, author={甲}, title={t}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
