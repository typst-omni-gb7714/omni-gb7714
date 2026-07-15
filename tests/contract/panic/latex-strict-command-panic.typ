// latex-strict-command: true（缺省）遇到未定义 LaTeX 命令 → 渲染期报错。
#import "/lib.typ": *
#show: gb7714.with()
#bibliography(bytes("@book{undef, author={甲}, title={拼错的命令 \\foobar{内容}}, address={北京}, publisher={社}, year={2020}, langid={chinese}}"), title: none, full: true)
