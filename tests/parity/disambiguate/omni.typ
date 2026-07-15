// 与 citeproc-lua 对拍用的渲染面（配置见 run.sh 头注：与官方 GB 著者-出版年制样式等价）。
#import "/lib.typ": gb7714, bibliography
#show: gb7714.with(style: "author-date", cite-et-al-min: 2, cite-et-al-use-first: 1,
                   disambiguate: (names: false, given-name: true, date: true))
#set page(width: 24cm, height: auto, margin: 1cm)
#set text(lang: "en", size: 9pt)
#cite(<a1>)#cite(<a2>)#cite(<b1>)#cite(<b2>)#cite(<c1>)#cite(<c2>)#cite(<d1>)#cite(<d2>)#cite(<e1>)#cite(<e2>)
#bibliography(bytes(read("refs.bib")), title: none)
