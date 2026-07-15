// 原生基准：std.bibliography + show…: set block(fill 标记) → 整表一个框（fill 标记色恰 1 次）。title:none 去 heading 块。
#show std.bibliography: set block(fill: rgb("#123456"))
正文 #cite(<a>) #cite(<b>) #cite(<c>)
#std.bibliography(bytes("@book{a,author={Zhang San},title={TA},publisher={P},year={2020}}
@article{b,author={Li Si},title={TB},journal={J},year={2021},pages={1-9},volume={1}}
@article{c,author={Wang Wu},title={TC},journal={K},year={2022},pages={3-7},volume={2}}"), style: "gb-7714-2015-numeric", title: none)
