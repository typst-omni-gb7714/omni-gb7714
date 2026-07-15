// 精准语言检测 accurate 模式的边缘场景准确度探针。
// 编译：typst compile --root <仓库根> probe.typ probe.pdf
// 直接调 `detect-accurate(entry)`，用人造 entry 验证字符表 + 百家姓姓氏白名单 + glotter 四级判定的覆盖。
#import "/src/parse/lang-detect.typ": detect-accurate

#let mk(fam, ttl) = (
  parsed_names: (author: if fam != none { ((family: fam, given: ""),) } else { () }),
  fields: if ttl != none { (title: ttl) } else { (:) },
)

#let cases = (
  // === A 日文（含全汉字、国字、新字体、撞字日本姓）===
  ("A 全汉字日文", "夏目漱石", "文学論", "ja"),
  ("A 全汉字日文", "新渡戸稲造", "武士道", "ja"),
  ("A 全汉字日文", "和辻哲郎", "風土", "ja"),
  ("A 全汉字日文", "丸山真男", "日本政治思想史研究", "ja"),
  ("A 全汉字日文", "岡倉天心", "茶道論", "ja"),
  ("A 国字日文", "辻邦生", "西行花伝", "ja"),
  ("A 国字日文", "畑中章宏", "災害民俗学", "ja"),
  ("A 新字体", "沢木耕太郎", "深夜特急", "ja"),
  ("A 撞字日本姓", "田中角栄", "私の履歴書", "ja"),
  ("A 撞字日本姓", "山本五十六", "海軍の伝統", "ja"),
  ("A 撞字日本姓", "高橋洋一", "経済入門", "ja"),
  ("A 撞字日本姓", "林芙美子", "放浪記", "ja"),
  ("A 撞字日本姓", "森鷗外", "舞姫", "ja"),
  ("A 含假名", "村上春樹", "海辺のカフカ", "ja"),

  // === B 中文（常见姓、复姓、罕用姓、繁体、极短姓名）===
  ("B 中文常见", "钱锺书", "围城", "zh"),
  ("B 中文常见", "鲁迅", "呐喊", "zh"),
  ("B 中文常见", "费孝通", "乡土中国", "zh"),
  ("B 中文复姓", "司马迁", "史记", "zh"),
  ("B 中文复姓", "欧阳修", "新唐书", "zh"),
  ("B 中文复姓", "诸葛亮", "出师表", "zh"),
  ("B 中文 2 字", "钱穆", "国史大纲", "zh"),
  ("B 中文 2 字", "李白", "将进酒", "zh"),
  ("B 中文 1 字", "王", "易", "zh"),
  ("B 罕用姓", "冮志和", "辽东史话", "zh"),
  ("B 罕用姓", "仝雪松", "中国油气田勘探", "zh"),
  ("B 罕用姓", "邝丽莎", "雪花秘扇", "zh"),
  ("B 罕用姓", "阚石", "历史与社会", "zh"),
  ("B 罕用姓", "隗瀛涛", "近代社会变迁史", "zh"),
  ("B 繁体中文", "錢穆", "國史大綱", "zh"),
  ("B 繁体中文", "余英時", "中國近世宗教倫理與商人精神", "zh"),

  // === J 少数民族（含中文式间隔符）===
  ("J 维吾尔", "阿不都·热依木", "维吾尔族文学史", "zh"),
  ("J 维吾尔", "玉素甫·哈斯·哈吉甫", "福乐智慧", "zh"),
  ("J 维吾尔", "麦麦提·托乎提", "新疆民俗研究", "zh"),
  ("J 藏族", "索朗·扎西", "藏族文化研究", "zh"),
  ("J 蒙古", "巴特尔·孟克", "草原游牧民俗", "zh"),
  ("J 满族复姓", "爱新觉罗·溥仪", "我的前半生", "zh"),
  ("J 哈萨克", "努尔兰·阿不都满", "新疆经济概览", "zh"),

  // === K 跨文化：语言看条目主体不看作者国籍 ===
  ("K 中文人发日文-含假名", "王明", "中国の歴史", "ja"),
  ("K 中文人发日文-含假名", "李红", "東アジアの国際関係", "ja"),
  ("K 日本人发中文-含简化字", "竹内好", "鲁迅论集", "zh"),
  ("K 日本人发中文-含简化字", "沟口雄三", "中国思想史研究", "zh"),
  ("K 中文译外文-含简化字", "杨绛", "堂吉诃德", "zh"),

  // === L 现代复杂作者格式 ===
  ("L 中国回族", "马克勤", "回族经济史", "zh"),
  ("L 中国人单名+西文", "Wang, Ming", "Recent Advances", "en"),
  ("L 学者半英化", "Zhang", "中国近代史", "zh"),

  // === C/D/E/F 通用基准 ===
  ("C 法文", "Piketty", "Le capital au XXIe siècle", "fr"),
  ("C 法文", "Sartre", "L'Être et le Néant", "fr"),
  ("D 英文", "Knuth", "The Art of Computer Programming", "en"),
  ("D 英文", "Darwin", "On the Origin of Species", "en"),
  ("E 德文→en", "Kafka", "Die Verwandlung", "en"),
  ("E 德文→en", "Nietzsche", "Also sprach Zarathustra", "en"),
  ("F 韩文", "김소월", "진달래꽃", "ko"),
  ("F 俄文", "Толстой", "Война и мир", "ru"),

  // === G/H/I 边界：仅姓 / 仅题名 / 空 / 罗马化 ===
  ("G 仅中文姓", "钱锺书", none, "zh"),
  ("G 仅英文姓", "Knuth", none, "en"),
  ("H 仅中文题", none, "山海经", "zh"),
  ("H 仅英文题", none, "Database System Concepts", "en"),
  ("I 空条目", none, none, "en"),
  ("I 罗马化中文名", "Mao Zedong", "On Protracted War", "en"),
)

#let pass = 0
#let fail = 0
#let fails = ()
#for (grp, fam, ttl, exp) in cases {
  let got = detect-accurate(mk(fam, ttl))
  if got == exp { pass += 1 } else { fail += 1; fails.push((grp, fam, ttl, exp, got)) }
}
// 自断言：任何一例回归即编译失败（run.sh 只需编译即可当门控）。
#assert(fail == 0, message: "lang-detect 回归：" + str(fail) + " 例失配 —— " + repr(fails))

= accurate 语言检测准确度（极限场景）

总计 *#(pass + fail)* 例，通过 *#pass*，失败 *#fail*，准确率 *#calc.round(pass / (pass + fail) * 100, digits: 1)%*

#if fails.len() > 0 [
  == 失败明细
  #for (grp, fam, ttl, exp, got) in fails [
    - [#grp]「#fam」「#ttl」：期望 #exp，实得 #got
  ]
] else [
  全部通过。
]

== 分组小结

#let groups = ("A", "B", "J", "K", "L", "C", "D", "E", "F", "G", "H", "I")
#table(
  columns: 4,
  align: (left, right, right, right),
  table.header[*组*][*总数*][*通过*][*准确率*],
  ..groups.map(g => {
    let total = cases.filter(c => c.at(0).starts-with(g + " ")).len()
    let f = fails.filter(c => c.at(0).starts-with(g + " ")).len()
    let p = total - f
    (g, str(total), str(p), if total > 0 { str(calc.round(p / total * 100)) + "%" } else { "—" })
  }).flatten(),
)
