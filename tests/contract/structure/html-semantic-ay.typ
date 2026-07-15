// HTML 语义标签（著者-出版年制）：<section role="doc-bibliography" class="hanging-indent">（AY 悬挂档加 class）+ <li>（无 prefix）。
// 对齐原生 gb-7714-2015-author-date 的 HTML 导出。见 run.sh htmlsem 检查。
#import "/lib.typ": *
#show: gb7714.with(style: "author-date", full: true)
正文 @a @b
#bibliography(bytes("@book{a, author={Zhang San}, title={Title A}, publisher={Pub}, year={2020}}
@article{b, author={Li Si}, title={Title B}, journal={J}, year={2021}, pages={1-9}, volume={1}}"), title: [参考文献])
