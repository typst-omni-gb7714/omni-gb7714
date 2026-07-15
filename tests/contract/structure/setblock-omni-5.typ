// 同 setblock-omni 但 5 条目——证明框数不随条目数增长（仍 = 1，非逐条目 N 框）。
#import "/lib.typ": *
#show: gb7714.with(full: true)
#set block(fill: rgb("#123456"))
正文 @a @b @c @d @e
#bibliography(bytes("@book{a, author={A}, title={TA}, publisher={P}, year={2020}}
@book{b, author={B}, title={TB}, publisher={P}, year={2020}}
@book{c, author={C}, title={TC}, publisher={P}, year={2020}}
@book{d, author={D}, title={TD}, publisher={P}, year={2020}}
@book{e, author={E}, title={TE}, publisher={P}, year={2020}}"), title: none)
