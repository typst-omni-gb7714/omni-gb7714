// 页码单复数判据（`pages.is-plural`）的 12 条哨兵，判据照抄 hayagriva 的 `PageRanges::is_plural`
// （即 Typst 原生 CSL 引擎的行为，对应 CSL 的 `plural="contextual"`）。
#import "/src/elements/pages.typ": is-plural
#assert.eq(is-plural("42"), false, message: "单页 → 单数")
#assert.eq(is-plural("42-42"), false, message: "起讫相同的退化区间 → 单数（同上游）")
#assert.eq(is-plural("114-514"), true, message: "真区间 → 复数")
#assert.eq(is-plural("114--514"), true, message: "biblatex 双连字符区间 → 复数")
#assert.eq(is-plural("114–514"), true, message: "en dash 区间 → 复数")
#assert.eq(is-plural("42, 45"), true, message: "两个单页 → 复数")
#assert.eq(is-plural("12-15, 20-25"), true, message: "多段区间 → 复数")
#assert.eq(is-plural("S12-S18"), true, message: "带前缀字母的区间 → 复数")
#assert.eq(is-plural("xii-xv"), true, message: "罗马数字区间 → 复数")
#assert.eq(is-plural("e12345"), false, message: "文章编号不是区间 → 单数")
#assert.eq(is-plural("第 5 页"), false, message: "解析不成页码 → 单数")
#assert.eq(is-plural(""), false, message: "空值 → 单数")
#assert.eq(is-plural(none), false, message: "none → 单数")
页码单复数判据校验通过
