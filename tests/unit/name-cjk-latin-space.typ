// 回归：CJK 姓 + 拉丁名（音译西文名）走西文规则——姓 + 空格 + 名首字母缩写无点（昂温 S，对齐 Einstein A）；
//   纯 CJK 名（张三）紧排。用 assert.eq 字符串精确比对（pdftotext 会在 CJK-拉丁边界补空格，掩盖此 bug）。
#import "/src/elements/creator.typ" as creators
#assert.eq(creators.format-one((family: "昂温", given: "S.")), "昂温 S", message: "CJK姓+拉丁名:加空格、缩写无点")
#assert.eq(creators.format-one((family: "昂温", given: "P. S.")), "昂温 P S", message: "多个首字母:空格分隔、均无点")
#assert.eq(creators.format-one((family: "张", given: "三")), "张三", message: "纯CJK名不加空格")
#assert.eq(creators.format-one((family: "昂温", given: "")), "昂温", message: "无名时只姓")
#assert.eq(creators.format-one((family: "Einstein", given: "Albert"), name-style: (family-case: "uppercase")), "EINSTEIN A", message: "西文名:姓大写+首字母无点")
姓名空格校验通过
