// A1: edition/volume 覆写值须是前后缀对；给字符串（当纯词写）必 panic。
#import "/lib.typ": *
#show: gb7714.with(custom-terms: (volume: (zh: "第X卷")))
#bibliography(bytes("@book{a, author={张三}, title={T}, publisher={P}, address={B}, year={2020}}"))
