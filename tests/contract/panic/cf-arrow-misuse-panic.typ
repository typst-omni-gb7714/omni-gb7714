// `=>` 只有「守卫组里谓词与组体的分界」这一个语义，误用必须报错，不能静默吞内容。
// 曾经：组里写第二个 `=>`，多余的箭头留在组体里成了渲染为空的节点，正撞上空节点的丢弃逻辑，
// 把*前一段*组体整个吞掉——`<mark=M => {甲} => {乙}>` 只出「乙」，且不报错。
// 组外的裸 `=>` 同样静默消失（还顺手吞掉前面的标点）。
#import "/lib.typ": *
#show: gb7714.with(custom-drivers: (book: "author. title<mark=M => {甲} => {乙}>."))
@x
#bibliography(bytes("@book{x, author={Li M}, title={A Book}, year={2020}, address={NY}, publisher={Pub}}"))
