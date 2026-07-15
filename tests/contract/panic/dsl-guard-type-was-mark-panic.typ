// `type=M` 的静默陷阱：改名前 `type` 指标识码，现在指 bib 字段——语法两边都合法，静默改语义
// 太危险（条目多半没有 type 字段 → 落空 → 整组消失，不报错）。值命中已知标识码全集时报错指路。
#import "/lib.typ": *
#show: gb7714.with(custom-drivers: (M: "author. title{[}mark{]}. <type=M => {旧写法}>."))
@b1
#bibliography(bytes("@book{b1, author={甲}, title={书名}, year={2020}}"))
