// omni：同样用原生 CSL 流派(springer-vancouver)。inline 引用应*完全 passthrough*、与原生逐像素一致
//   （omni 不插 leading-wj、不吃标记前空白）。run.sh 比第一行(正文含引用)像素应全等。
#import "/lib.typ": *
#set page(width: 300pt, height: auto, margin: 10pt)
#show: gb7714.with()
文本before @a 文本after.
#bibliography(bytes("@article{a,author={Zhang San},title={Title},journal={J},year={2020},volume={1},pages={1-9}}"), style: "springer-vancouver", title: none)
