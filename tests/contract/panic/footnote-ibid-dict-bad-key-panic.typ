// custom-terms `ibid` 字典值的键白名单：`text` / `supplement-separator` 之外的键 panic。
// （顶层裸键与纯词同一取舍：当语言码宽容处理，拼错静默无效——Typst 没有 warning API。）
#import "/lib.typ": *
#show: gb7714.with(version: 2015, cite-footnote: true, custom-terms: (ibid: (zh: (word: "同前"))))
A #cite(<ya>)
#bibliography(bytes("@book{ya, author={张三}, title={甲}, year={2020}, address={B}, publisher={P}}"), title: none)
