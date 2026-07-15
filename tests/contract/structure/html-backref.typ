// C9: HTML 双向反链——cite 侧 role=doc-biblioref（首次引用带 id、重复引用不带，避免重复 id）；
// back-ref 开启时 bib 编号 role=doc-backlink 反链回首次 cite 的 id。对齐原生 std.bibliography HTML。
#import "/lib.typ": *
#show: gb7714.with(version: 2015, back-ref: true)
正文 @a @a @b
#bibliography(bytes("@book{a, author={张三}, title={书}, publisher={社}, address={北京}, year={2020}}
@book{b, author={李四}, title={文}, publisher={社}, address={北京}, year={2021}}"), title: none)
