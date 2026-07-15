// `page-range-style` 值域外一律 panic 并列出合法值；"chicago" 是 CSL 1.0.1 的旧名，收作
// "chicago-15" 的别名（不 panic），所以这里用一个真的非法值。
#import "/lib.typ": *
#show: gb7714.with(full: true, page-range-style: "collapsed")
#bibliography(bytes("@book{a, author={A, X}, title={T}, publisher={P}, address={NY}, year={2020}}"), title: none)
