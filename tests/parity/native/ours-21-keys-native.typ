// 回归：native-mode 下显式 `keys:` 点名的条目（未被正文引用）必须渲染——
// 曾有 bug：routed-empty 只看「有没有路由 cite」，不看用户显式的 `keys:`，把整表判空、只剩标题。
#import "/lib.typ": *
#let MAIN = "@book{m1, author={A}, title={T1}, publisher={P}, year={2020}}
@book{m2, author={B}, title={T2}, publisher={P}, year={2021}}"
#let EX = "@book{e1, author={KEYTESTAUTH}, title={例书}, publisher={Q}, year={2020}}"
#show: gb7714.with()
正文 @m1 @m2
#bibliography(MAIN, title: [主表])
#bibliography(EX, keys: [#ref(label("e1"))], numbering-style: none, title: none)
