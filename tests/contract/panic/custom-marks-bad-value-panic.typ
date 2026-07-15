// `custom-marks` 的值必须是非空字符串标识码（校验已从 api.typ 抽进 mark-medium/custom.typ）。
#import "/lib.typ": *
#show: gb7714.with(custom-marks: (book: 123))
@b1
#bibliography(bytes("@book{b1, author={甲}, title={书}, year={2020}, address={B}, publisher={P}}"))
