// set block 单框一致性（原生侧基准）：纯 typst std.bibliography + show…: set block(fill 标记色)。
// 不 import omni（否则 omni 拦截 std.bibliography(bytes) 会 panic 指向 omni 函数）。title:none 去掉 heading 块。
#show std.bibliography: set block(fill: rgb("#123456"))
正文 #cite(<a>) #cite(<b>) #cite(<c>)
#std.bibliography(bytes("@book{a, author={Zhang San}, title={Title A}, publisher={Pub}, year={2020}}
@article{b, author={Li Si}, title={Title B}, journal={J}, year={2021}, pages={1-9}, volume={1}}
@article{c, author={Wang Wu}, title={Title C}, journal={K}, year={2022}, pages={3-7}, volume={2}}"), style: "gb-7714-2015-numeric", title: none)
