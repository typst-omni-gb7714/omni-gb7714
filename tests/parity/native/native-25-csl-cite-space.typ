// 原生基准：原生 CSL 流派(springer-vancouver)正文引用，标记前后空白由原生 CSL 决定。
#set page(width: 300pt, height: auto, margin: 10pt)
文本before #cite(<a>) 文本after.
#std.bibliography(bytes("@article{a,author={Zhang San},title={Title},journal={J},year={2020},volume={1},pages={1-9}}"), style: "springer-vancouver", title: none)
