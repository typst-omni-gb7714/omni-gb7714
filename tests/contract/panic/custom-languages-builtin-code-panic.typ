// custom-languages 的码撞内置码（en）→ panic 并指出内置码集。
#import "/lib.typ": *
#show: gb7714.with(custom-languages: (en: ("english",)))
#bibliography(bytes("@book{a, author={甲}, title={t}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
