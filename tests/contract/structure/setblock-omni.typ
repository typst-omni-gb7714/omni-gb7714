// set block 单框一致性（omni 侧）：整个文献表 = 一个 block，set block(fill 标记色) 只命中一次。
// 与 setblock-native.typ 同数据、同标记色、同 title:none——SVG 中标记色出现次数应都 = 1。见 run.sh。
#import "/lib.typ": *
#show: gb7714.with(full: true)
#set block(fill: rgb("#123456"))
正文 @a @b @c
#bibliography(bytes("@book{a, author={Zhang San}, title={Title A}, publisher={Pub}, year={2020}}
@article{b, author={Li Si}, title={Title B}, journal={J}, year={2021}, pages={1-9}, volume={1}}
@article{c, author={Wang Wu}, title={Title C}, journal={K}, year={2022}, pages={3-7}, volume={2}}"), title: none)
