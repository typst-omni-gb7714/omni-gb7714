// 驱动二：omni-gb7714，著者-出版年制 + 笔画排序。
// 编译：typst compile --root <仓库根> omni.typ。
// 关键参数：style: "author-date" + bib-sort-zh-by: "bihua"（中文按笔画，经 auto-bihua）。
#import "/lib.typ": gb7714, bibliography
#import "/tests/_fixture/fonts.typ": test-font-stack
#set text(font: test-font-stack, lang: "zh")
#let bib = read("refs.bib")
#show: gb7714.with(
  style: "author-date",
  version: 2015,
  bib-sort-zh-by: "bihua",
  full: true,   // 收录全部条目（等价 biblatex 的 \nocite{*}）
)

#bibliography(bib)
