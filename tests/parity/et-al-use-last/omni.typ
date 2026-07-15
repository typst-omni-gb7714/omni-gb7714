// omni 侧：照搬心理学报 CSL 的 <bibliography et-al-min="8" et-al-use-first="6" et-al-use-last="true">。
// CSL 的 use-last 是布尔（只留末 1 位），映射到本包就是 1。
#import "/lib.typ": gb7714, bibliography
#show: gb7714.with(bib-et-al-min: 8, bib-et-al-use-first: 6, bib-et-al-use-last: 1)
#set text(font: ("Times New Roman",), size: 9pt)
#bibliography(bytes(read("refs.bib")), title: none, full: true)
