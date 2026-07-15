// name-style 只收 auto 或五维字典；任何字符串（含旧预设名）一律 not-dictionary。
#import "/lib.typ": *
#show: gb7714.with(bib-name-style: "pinyin")
#bibliography(bytes("@book{a, author={A}, title={T}, year={2020}}"))
