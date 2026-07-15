// 模板里写了不存在的 token → panic 并指路 custom-fields / custom-terms。
#import "/lib.typ": *
#show: gb7714.with(custom-drivers: (book: "author . title . nonexistent-token"))
#bibliography(bytes("@book{a, author={甲}, title={t}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
