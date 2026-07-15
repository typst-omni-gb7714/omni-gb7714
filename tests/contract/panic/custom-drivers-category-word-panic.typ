// custom-drivers 用内部类别词作键（monograph / component-part / …）→ panic 并给出改写指引。
#import "/lib.typ": *
#show: gb7714.with(custom-drivers: (monograph: "author . title"))
#bibliography(bytes("@book{a, author={甲}, title={t}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
