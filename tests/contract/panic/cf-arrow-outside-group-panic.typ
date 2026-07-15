// 组外的裸 `=>`（见 cf-arrow-misuse-panic 头注）。
#import "/lib.typ": *
#show: gb7714.with(custom-drivers: (book: "author => title."))
@x
#bibliography(bytes("@book{x, author={Li M}, title={A Book}, year={2020}, address={NY}, publisher={Pub}}"))
