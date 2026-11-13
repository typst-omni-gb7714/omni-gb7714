#import "/lib.typ": *
#set text(font: "Libertinus Serif", size: 10pt)
#show: gb7714(back-ref: true)
#let data = "@book{parent,author={Parentauthor, Anne},title={Parentbook},year={2020},langid={english}}
@book{other,author={Otherauthor, Bob},title={Otherbook},year={2021},langid={english}}"
#set-bib-label("parent")
#for index in range(10) [Temporary #index: #cite(<other>, bib-label: "other"). Parent: #cite(<parent>). #parbreak()]
#bibliography(data, label: "parent", title: [Parent list])
#bibliography(data, label: "other", title: [Other list])
