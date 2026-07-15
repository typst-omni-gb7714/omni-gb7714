// 0.15：`show std.bibliography: it => 包裹` 只命中一次（不再多出个空框）——SVG 标记 fill 恰 1 次。
#import "/lib.typ": *
#show: gb7714.with(full: true)
#show std.bibliography: it => block(fill: rgb("#123456"), it)
正文 @a
#bibliography(bytes("@article{a,author={Z},title={T},journal={J},year={2020}}"), title: none)
