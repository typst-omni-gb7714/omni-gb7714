// `custom-punct` 的键必须是标点字符本身。曾经完全没有校验——写错键静默忽略、无声无息，
// 而同族的 custom-terms / custom-fields / custom-pids 都有 validate-*。这不是巧合：
// custom-punct 与 custom-marks 恰恰是当初唯二没有自己 custom.typ 的族，也恰恰是唯二缺校验的。
#import "/lib.typ": *
#show: gb7714.with(custom-punct: ("拼错的键": "X"))
@b1
#bibliography(bytes("@book{b1, author={甲}, title={书}, year={2020}, address={B}, publisher={P}}"))
