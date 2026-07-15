// 0.15 能力：omni 的可见列表经 std.bibliography 哨兵改道，使原生写法 `show std.bibliography: set block`
//   命中整表（与原生体验一致）。断言：SVG 中标记 fill 色恰 1 次（整表一个框、不随条目数）。见 run.sh。
#import "/lib.typ": *
#show: gb7714.with(full: true)
#show std.bibliography: set block(fill: rgb("#123456"))
正文 @a @b @c
#bibliography(bytes("@book{a,author={Zhang San},title={TA},publisher={P},year={2020}}
@article{b,author={Li Si},title={TB},journal={J},year={2021},pages={1-9},volume={1}}
@article{c,author={Wang Wu},title={TC},journal={K},year={2022},pages={3-7},volume={2}}"), title: none)
