// 0.15：omni 每个 #bibliography 只发*一个* std.bibliography（日期解析/路由 + 渲染合并），使 query / 包裹类
//   原生操作只命中一次、无空框漏出。断言 query(std.bibliography).len()==2（两个列表各一个，不是各两个）。见 run.sh。
#import "/lib.typ": *
#show: gb7714.with(full: true)
正文 @a @b
#bibliography(bytes("@article{a,author={AA},title={TA},journal={J},year={2020}}"), label: "l1", title: none)
#bibliography(bytes("@article{b,author={BB},title={TB},journal={K},year={2021}}"), label: "l2", title: none)
#context [STDBIBCOUNT=#query(std.bibliography).len()=END]
