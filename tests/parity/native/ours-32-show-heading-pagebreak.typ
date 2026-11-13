#import "/tests/_fixture/fonts.typ": test-fonts
#show: test-fonts
// 回归：用户 `show heading: it => { pagebreak(); it }` 让文献表标题跨页时，表内编号曾整体偏移
//   自己的条目数（正文 [1-3]、表里 [4][5][6]）。根因是 `bib-seq` 的 push 标签与标题 pagebreak
//   同段、被前导标签迁页错到 context 锚点之前。修法：push 后置到本表内容末尾。
#import "/lib.typ": *
#show: gb7714
#show heading: it => { pagebreak(); it }
A @k1@k2@k3
#bibliography(bytes("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, year={2020}}
@book{k2, author={Beta, B}, title={T2}, publisher={Q}, year={2021}}
@book{k3, author={Gamma, C}, title={T3}, publisher={R}, year={2022}}"))
