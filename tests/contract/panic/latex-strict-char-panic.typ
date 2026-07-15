// latex-strict-char: true（缺省）遇到未转义的特殊字符 → 渲染期报错。
#import "/lib.typ": *
#show: gb7714.with()
#bibliography(bytes("@book{bare, author={甲}, title={裸特殊字符 A & B}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
