// 浏览器内 WASM 性能基准的 omni-gb7714 驱动文件。
// 由 site.js 通过 typst.ts 虚拟文件系统挂载在 /main-omni.typ。
// 引用同目录的 lib.typ + refs.bib（91 条 GB/T 7714—2015 标准条目）。
#import "/lib.typ": *

#show: gb7714()

= 性能基准（omni-gb7714）

通过完整解析所有条目、按顺序编码制排序、运行 omni-gb7714 的国标合规扩展（消歧、双语、责任者拼接等），以测出全流程耗时。

// bibliography 要的是 read() 读出的 bib *内容*，不是文件路径
#bibliography(read("/refs.bib"), full: true)
