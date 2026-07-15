// 完全对齐原生：omni numeric 文献表 = 单个 grid（x:0 编号 / x:1 内容），所以原生后处理技巧
//   `show grid.cell.where(x: 1): it => …`（如双语条目改写）能命中 omni 每条内容、不碰编号。见 run.sh。
#import "/lib.typ": *
#show: gb7714.with(full: true)
#show grid.cell.where(x: 1): it => [MARKX#it]
正文 @a @b
#bibliography(bytes("@book{a,author={AA},title={TitleA},publisher={P},year={2020}}
@book{b,author={BB},title={TitleB},publisher={Q},year={2021}}"), title: none)
