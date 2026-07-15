// 脚注制 × native 路由（多表 + target）：脚注渲染补发 form: none 隐形注册，
// 原生表照常收录、路由、跨表连续编号；脚注体与重复梯子由本包渲染。
// 引文页码两种写法都钉：markup 简写 @k[..]（经旁车元数据携带）与 #cite 直传。
#import "/lib.typ": *
#set text(lang: "zh")
#show: gb7714(version: 2015, cite-footnote: true)
一 @k1 中 @k1[11] 。
#[尾 @k5 又 @k5 。] <appendix>
末 #cite(label("k1"), supplement: [25]) 。
#bibliography(bytes("@book{k1, author={Alpha, A}, title={T1}, publisher={P}, address={B}, year={2020}}"), title: [表一])
#bibliography(bytes("@book{k5, author={Gamma, C}, title={T5}, publisher={R}, address={B}, year={2022}}"), title: [表二], target: selector(std.cite).within(<appendix>))
