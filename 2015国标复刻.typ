#import "@preview/pointless-size:0.1.2": zh
//#import "@preview/cuti:0.4.0": show-cn-fakebold
//#show: show-cn-fakebold
//#import "@preview/quan:0.1.0": quan-style, quan-init
//#quan-style(radius: 0%)
//#quan-init(digits: none)
#set page(
  margin: (top: 3.7cm, bottom: 3.5cm, inside: 2.8cm, outside: 2.6cm)
)
#show heading.where(level: 1): it => {
  v(.5em)
  align(center)[
    #text(font: "SimHei", size: zh(4))[#it.body]
  ]
  v(2em)
}
#show heading.where(level: 1): set heading(outlined: false)
#show heading.where(level: 2): it => {
  v(1.5em)
  set text(font: "SimHei", size: 10.0375pt)
  par(first-line-indent: 0em)[#context counter(heading).display((..nums) => {
    numbering("1", nums.pos().at(1))
  })#h(1em)#it.body]
  v(1.5em)
}

#show heading.where(level: 3): it => {
  set text(font: "SimHei", size: 10.0375pt)
  par(first-line-indent: 0em)[#context counter(heading).display((..nums) => {
    let n = nums.pos()
    numbering("1.1", n.at(1), n.at(2))
  })#h(1em)#it.body]
}

#show heading.where(level: 4): it => {
  v(.5em)
  set text(font: "SimHei", size: 10.0375pt)
  par(first-line-indent: 0em)[#context counter(heading).display((..nums) => {
    let n = nums.pos()
    numbering("1.1.1", n.at(1), n.at(2), n.at(3))
  })#h(1em)#it.body]
  v(.5em)
}

#show heading.where(level: 5): it => {
  v(.5em)
  set text(font: "SimHei", size: 10.0375pt)
  par(first-line-indent: 0em)[#context counter(heading).display((..nums) => {
    let n = nums.pos()
    numbering("1.1.1.1", n.at(1), n.at(2), n.at(3), n.at(4))
  })#h(1em)#it.body]
  v(.5em)
}

#set heading(numbering: (..nums) => {
  let n = nums.pos()
  if n.len() == 1 { none }
  else if n.len() == 2 { numbering("1", ..n.slice(1)) }
  else { numbering("1.1", ..n.slice(1)) }
})


#set text(font: ("Founder-S10-BZ", "SimSun", "Noto Serif CJK KR"), lang: "zh", size: 10.0375pt)

#set par(spacing: .85em, leading: .85em)

// 方正白正的前引号在 Typst 里排版有问题
// 这里无奈换成 SimSun
#show "\u{201C}": text.with(font: "SimSun")
#show "\u{201D}": text.with(font: "SimSun")
#show "\u{2018}": text.with(font: "SimSun")
#show "\u{2019}": text.with(font: "SimSun")
// 不懂方正书版的机制，把全角标点强行压成接近半角宽的
// 实测 0.5em 时前后引号会重叠
#show regex("[，。、；：！？“‘”’（）【】《》〈〉·]"): it => box(width: 0.6em, it)
#show regex("-"): it => text(font: "SimSun")[#it]

#set par(justify: true, first-line-indent: (amount: 2em, all: true))

#import "@preview/cjk-spacer:0.2.0": *
#show: cjk-spacer

#import "gb7714.typ": gb7714
#let (init-gb7714, bibliography, print-bib, cite, set-bib-label) = gb7714(
  (
    "2015-mainmatter": read("2015-mainmatter.bib"),
    "2015-appx": read("2015-appx.bib"),
  ),
  //cite-compress-min: 5
  //style: "author-year",
  //number-width: 5cm,
  //number-align: "",
  //after-number-sep: 0em,
  //item-sep: 16em,
  //hanging: false,
  //title: heading(level: 1)[biblio]
  //dash-in-pages: "～",
  //number-style: "plain",
  //hyperlink-title: true,
  //number-style: "quan",
  no-author: false,
  //no-others: true,
  full: true,
  //name-format: "pinyin",
)
#show: init-gb7714

#v(1fr)
#align(center)[
#text(size: zh(1), font: "SimHei")[
基于 omni-gb7714 对 GB/T 7714-2015 标准文件的复刻
]]
#v(1fr)

#pagebreak()
#counter(page).update(1)
#set page(
  header: context {
    if calc.odd(counter(page).get().first()) {
      align(right)[#text(font: "Times New Roman", weight: "bold", size: 10.0375pt)[GB/T] #text(font: "SimHei", size: 10.0375pt)[7714-2015]]
    } else {
      align(left)[#text(font: "Times New Roman", weight: "bold", size: 10.0375pt)[GB/T] #text(font: "SimHei", size: 10.0375pt)[7714-2015]]
    }
  },
  footer: context {
    let num = counter(page).display()
    if calc.odd(counter(page).get().first()) {
      align(right)[#num]
    } else {
      align(left)[#num]
    }
  }
)

#let to-unicode-roman(n) = {
  let roman-map = (
    "I": "\u{2160}", "II": "\u{2161}", "III": "\u{2162}",
    "IV": "\u{2163}", "V": "\u{2164}", "VI": "\u{2165}",
    "VII": "\u{2166}", "VIII": "\u{2167}", "IX": "\u{2168}",
    "X": "\u{2169}",
  )
  let s = numbering("I", n)
  if roman-map.keys().contains(s) { roman-map.at(s) } else { s }
}

#set page(
  numbering: "I",
  footer: context {
    set text(size: zh(-5))
    let n = counter(page).get().first()
    let num = to-unicode-roman(n)
    if calc.odd(n) {
      align(right)[#num]
    } else {
      align(left)[#num]
    }
  }
)
#show outline.entry: it => {
  show regex("X{0,3}(IX|IV|VI{0,3}|I{1,3})"): t => {
    let roman-map = (
      "I": "\u{2160}", "II": "\u{2161}", "III": "\u{2162}",
      "IV": "\u{2163}", "V": "\u{2164}", "VI": "\u{2165}",
      "VII": "\u{2166}", "VIII": "\u{2167}", "IX": "\u{2168}",
      "X": "\u{2169}",
    )
    if roman-map.keys().contains(t.text) { roman-map.at(t.text) } else { t }
  }
  let indent = if it.level == 1 { -1em } else if it.level == 3 { 1em } else { 0em }
  pad(left: indent, {
    it.prefix()
    h(1em)
    it.body()
    box(width: 1fr, repeat[…])
    it.page()
  })
}
#outline(
  title: [目#h(2em)次],
  depth: 3
)
#pagebreak()

#place(hide(heading(level: 1, outlined: true)[前言]))
= 前#h(2em)言

本标准按照 GB/T 1.1—2009 给出的规则起草。

本标准代替 GB/T 7714—2005《文后参考文献著录规则》。与 GB/T 7714—2005 相比，主要技术变化如下：

——本标准的名称由《文后参考文献著录规则》更名为《信息与文献\u{3000}参考文献著录规则》；

——根据本标准的适用范围和用途，将“文后参考文献”和“电子文献”分别更名为“参考文献”和“电子资源”；

——在“3\u{3000}术语和定义”中，删除了参考文献无须著录的“并列题名”,增补了“阅读型参考文献”和“引文参考文献”。根据 ISO      690:2010(E) 修改了“3.1\u{3000}文后参考文献”“3.2\u{3000}主要责任者”“3.3\u{3000}专著”“3.4\u{3000}连续出版物”“3.5\u{3000}析出文献”“3.6\u{3000}电子文献”的术语、定义、英译名；

——在著录项目的设置方面，为了适应网络环境下电子资源存取路径的发展需要，本标准新增了“数字对象唯一标识符”(DOI),   以便读者快捷、准确地获取电子资源；

——在著录项目的必备性方面，将“文献类型标识(电子文献必备，其他文献任选)”改为“文献类型标识(任选)”；将“引用日期(联机文献必备，其他电子文献任选)”改为“引用日期”；

——在著录规则方面，将“8.1.1”中的“用汉语拼音书写的中国著者姓名不得缩写”改为“依据 GB/T 28039—2011有关规定，用汉语拼音书写的人名，姓全大写，其名可缩写，取每个汉字拼音的首字母”。在“8.8.2”中增加了“阅读型参考文献的页码著录文章的起讫页或起始页，引文 参考文献的页码著录引用信息所在页”。在“8.5\u{3000}页码”中增补了“引自序言或扉页题词的页码，可按实际情况著录”的条款。新增了“8.6\u{3000}获取和访问路径”和“8.7\u{3000}数字对象统一标识符”的著录规则；

——在参考文献著录用文字方面，在“6.1”中新增了“必要时，可采用双语著录。用双语著录参考文献时，首先用信息资源的原语种著录，然后用其他语种著录”；

——为了便于识别参考文献类型、查找原文献、开展引文分析，在“文献类型标识”中新增了“A”档案 、“CM”舆图、“DS”数据集以及“Z”其他；

——各类信息资源更新或增补了一些示例，重点增补了电子图书、电子学位论文、电子期刊、电子资源的示例，尤其是增补了附视频的电子期刊、载有 DOI 的电子图书和电子期刊的示例以及韩文、日本、俄文的示例。

本标准使用重新起草法参考 ISO 690:2010(E)《信息和文献\u{3000}参考文献和信息资源引用指南》编制，与ISO 690:2010的一致性程度为非等效。

本标准由全国信息与文献标准化技术委员会(SAC/TC 4)提出并归口。

本标准起草单位：北京大学信息管理系、中国科学技术信息研究所、北京师范大学学报(自然科学版)编辑部、北京大学学报(哲学社会科学版)编辑部、中国科学院文献情报中心。

本标准主要起草人：段明莲、白光武、陈浩元、刘曙光、曾燕。

本标准所代替标准的历次版本发布情况为：

——GB/T 7714—1987、GB/T 7714—2005。

#pagebreak()
#counter(page).update(1)
#set page(
  numbering: "1",
  footer: context {
    set text(size: zh(-5))
    let num = counter(page).display("1")
    if calc.odd(counter(page).get().first()) {
      align(right)[#num]
    } else {
      align(left)[#num]
    }
  }
)

#show heading.where(level: 1): it => {
  v(1em)
  align(center)[
    #text(font: "SimHei", size: zh(4))[#it.body]
  ]
  v(.5em)
}

= 信息与文献\u{3000}参考文献著录规则

== 范围

本标准规定了各个学科、各种类型信息资源的参考文献的著录项目、著录顺序、著录用符号、著录用文字、各个著录项目的著录方法以及参考文献在正文中的标注法。

本标准适用于著者和编辑著录参考文献，而不是供图书馆员、文献目录编制者以及索引编辑者使用 的文献著录规则。

== 规范性引用文件

下列文件对于本文件的应用是必不可少的。凡是注日期的引用文件，仅注日期的版本适用于本文件。凡是不注日期的引用文件，其最新版本（包括所有的修改版）适用于本文件。

GB/T 7408—2005\u{3000}数据元和交换格式\u{3000}信息交换\u{3000}日期和时间表示法

GB/T 28039—2011\u{3000}中国人名汉语拼音字母拼写规则

ISO 4\u{3000}信息与文献\u{3000}出版物题名和标题缩写规则（Information and documentation—Rules for the abbreviation of title words and titles of publications）

== 术语与定义

下列术语和定义适用于本文件。

#let hei(body) = text(font: ("Times New Roman", "SimHei"), weight: "bold", body)

#heading(level: 3, outlined: false)[]

#hei[参考文献\u{3000}reference]

对一个信息资源或其中一部分进行准确和详细著录的数据，位于文末或文中的信息源。

#heading(level: 3, outlined: false)[]

#hei[主要责任者\u{3000}creator]

主要负责创建信息资源的实体，即对信息资源的知识内容或艺术内容负主要责任的个人或团体。 主要责任者包括著者、编者、学位论文撰写者、专利申请者或专利权人、报告撰写者、标准提出者、析出文  献的著者等。

#heading(level: 3, outlined: false)[]

#hei[专著\u{3000}monograph]

以单行本或多卷册(在限定的期限内出齐)形式出版的印刷型或非印刷型出版物，包括普通图书、古籍、学位论文、会议文集、汇编、标准、报告、多卷书、丛书等。

#heading(level: 3, outlined: false)[]

#hei[连续出版物\u{3000}serial]

通常载有年卷期号或年月日顺序号，并计划无限期连续出版发行的印刷或非印刷形式的出版物。

#heading(level: 3, outlined: false)[]

#hei[析出文献\u{3000}contribution]

从整个信息资源中析出的具有独立篇名的文献。

#heading(level: 3, outlined: false)[]

#hei[电子资源\u{3000}electronic resource]

以数字方式将图、文、声、像等信息存储在磁、光、电介质上，通过计算机、网络或相关设备使用的记录有知识内容或艺术内容的信息资源，包括电子公告、电子图书、电子期刊、数据库等。

#heading(level: 3, outlined: false)[]

#hei[顺序编码制\u{3000}numeric references method]

一种引文参考文献的标注体系，即引文采用序号标注，参考文献表按引文的序号排序。

#heading(level: 3, outlined: false)[]

#hei[著者-出版年制\u{3000}first element and date method]

一种引文参考文献的标注体系，即引文采用著者出版年标注，参考文献表按著者字顺和出版年排序。

#heading(level: 3, outlined: false)[]

#hei[合订题名\u{3000}title of the individual works]
 
由2种或2种以上的著作汇编而成的无总题名的文献中各部著作的题名。

#heading(level: 3, outlined: false)[]

#hei[阅读型参考文献\u{3000}reading reference]

著者为撰写或编辑论著而阅读过的信息资源，或供读者进一步阅读的信息资源。

#heading(level: 3, outlined: false)[]

#hei[引文参考文献\u{3000}cited reference]

著者为撰写或编辑论著而引用的信息资源。

#heading(level: 3, outlined: false)[]

#hei[数字对象唯一标识符\u{3000}digital object identifier; DOI]

针对数字资源的全球唯一永久性标识符，具有对资源进行永久命名标志、动态解析链接的特性。

== 著录项目与著录格式

本标准规定参考文献设必备项目与选择项目。凡是标注“任选”字样的著录项目系参考文献的选择项目，其余均为必备项目。本标准分别规定了专著、专著中的析出文献、连续出版物、连续出版物中的析出文献、专利文献以及电子资源的著录项目和著录格式。

#v(1em)

=== 专著

==== 著录项目

主要责任者

题名项
题名

  #h(1em)其他题名信息

  #h(1em)文献类型标识(任选)

  #h(1em)其他责任者(任选)

版本项

出版项

  #h(1em)出版地

  #h(1em)出版者

  #h(1em)出版年

  #h(1em)引文页码

  #h(1em)引用日期

获取和访问路径(电子资源必备)

数字对象唯一标识符(电子资源必备)

==== 著录格式

主要责任者. 题名：其他题名信息[文献类型标识/文献载体标识]. 其他责任者. 版本项. 出版地: 出版者, 出版年: 引文页码[引用日期]. 获取和访问路径. 数字对象唯一标识符.

#let sbi(body) = text(size: 8.62pt, body)

#sbi[

#hei[示例：]

#grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 10).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("4.1.2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)

#grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(10, 18).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("4.1.2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)

]
#v(1em)
=== 专著中的析出文献

==== 著录项目

析出文献主要责任者

#h(1em)析出文献题名项

#h(1em)析出文献题名

#h(1em)文献类型标识(任选)

析出文献其他责任者(任选)

出处项

#h(1em)专著主要责任者

#h(1em)专著题名

#h(1em)其他题名信息

版本项

出版项

#h(1em)出版地

#h(1em)出版者

#h(1em)出版年

#h(1em)析出文献的页码

#h(1em)引用日期

获取和访问路径(电子资源必备)

数字对象唯一标识符(电子资源必备)

==== 著录格式

析出文献主要责任者. 析出文献题名[文献类型标识/文献载体标识]. 析出文献其他责任者\/\/专著主要责任者. 专著题名: 其他题名信息. 版本项. 出版地: 出版者, 出版年: 析出文献的页码[引用日期]. 获取和访问路径. 数字对象唯一标识符.

#sbi[
  #hei[示例：]
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 8).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("4.2.2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]

#v(.5em)
=== 连续出版物

==== 著录项目

主要责任者

题名项

题名

#h(1em)其他题名信息

#h(1em)文献类型标识(任选)

#h(1em)年卷期或其他标识(任选)

出版项

#h(1em)出版地

#h(1em)出版者

#h(1em)出版年

#h(1em)引用日期

获取和访问路径(电子资源必备)

数字对象唯一标识符(电子资源必备)

==== 著录格式

主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. 年, 卷(期)-年, 卷(期). 出版地: 出版者, 出版年[引用日期]. 获取和访问路径. 数字对象唯一标识符.

#sbi[
  #hei[示例：]
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 4).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("4.3.2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]
#v(.5em)
=== 连续出版物中的析出文献

==== 著录项目

析出文献主要责任者

析出文献题名项

#h(1em)析出文献题名

#h(1em)文献类型标识(任选)出处项

连续出版物题名

#h(1em)其他题名信息

#h(1em)年卷期标识与页码

#h(1em)引用日期

#h(1em)获取和访问路径(电子资源必备)

数字对象唯一标识符(电子资源必备)

==== 著录格式

析出文献主要责任者. 析出文献题名[文献类型标识/文献载体标识]. 连续出版物题名: 其他题名信息, 年, 卷(期): 页码[引用日期]. 获取和访问路径. 数字对象唯一标识符.

#sbi[
  #hei[示例：]
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 10).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("4.4.2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]

#v(1.25em)

=== 专利文献

#v(.75em)

==== 著录项目

#v(.75em)

专利申请者或所有者

题名项

#h(1em)专利题名

#h(1em)专利号

#h(1em)文献类型标识(任选)

出版项

#h(1em)公告日期或公开日期

#h(1em)引用日期

获取和访问路径(电子资源必备)

数字对象唯一标识符(电子资源必备)

#v(.75em)

==== 著录格式

#v(.75em)

专利申请着或所有者. 专利题名: 专利号[文献类型标识/文献载体标识]. 公告自期或公开日期[引用日期]. 获取和访问路径. 数字对象唯一标识符.

#sbi[
  #hei[示例：]
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 4).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("4.5.2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]

#v(1.5em)

=== 电子资源

#v(.75em)

==== 著录项目

#v(.75em)

主要责任者

题名项

#h(1em)题名

#h(1em)其他题名信息

#h(1em)文献类型标识(任选)

出版项

#h(1em)出版地

#h(1em)出版者

#h(1em)出版年

#h(1em)引文页码

#h(1em)更新或修改日期

#h(1em)引用日期

#h(1em)获取和访问路径

数字对象唯一标识符

==== 著录格式

主要责任者. 题名: 其他题名信息[文献类型标识/文献载体标识]. 出版地: 出版者, 出版年: 引文页码(更新或修改日期)[引用日期]. 获取和访问路径. 数字对象唯一标识符.

#sbi[
  #hei[示例：]
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 6).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("4.6.2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]

== 著录信息源

参考文献的著录信息源是被著录的信息资源本身。专著、论文集、学位论文、报告、专利文献等可依据题名页、版权页、封面等主要信息源著录各个著录项目；专著、论文集中析出的篇章与报刊上的文章依据参考文献本身著录析出文献的信息，并依据主要信息源著录析出文献的出处；电子资源依据特定网址中的信息著录。

== 著录用文字

#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  参考文献原则上要求用信息资源本身的语种著录。必要时，可采用双语著录。用双语著录参考文献时，首先应用信息资源的原语种著录，然后用其他语种著录。
]

#sbi[
  #text(font: "SimHei")[示例1：]用原语种著录参考文献
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 7).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("6.1-1-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)]

#sbi[
  #text(font: "SimHei")[示例2：]用韩中2种语种著录参考文献
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 3).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("6.1-2-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]

#sbi[
  #text(font: "SimHei")[示例3：]用中英2种语种著录参考文献
  #grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 3).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("6.1-3-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]

#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  著录数字时，应保持信息资源原有的形式。但是，卷期号、页码、出版年、版次、更新或修改日期、引用日期、顺序编码制的参考文献序号等应用阿拉伯数字表示。外文书的版次用序数词的缩写形式表示。
]

#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  个人著者，其她全部著录，字母全大写，名可缩写为首字母(见8.1.1)；如用首字母无法识别该人名时，则用全名。
]

#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  出版项中附在出版地之后的省名、州名、国名等(见8.4.1)以及作为限定语的机关团体名称可按国际公认的方法缩写。
]

#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  西文期刊刊名的缩写可参照 ISO 4 的规定。
]

#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  著录西文文献时，大写字母的使用要符合信息资源本身文种的习惯用法。
]


== 著录用符号


#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  本标准中的著录用符号为前置符。按著者-出版年制组织的参考文献表中的第一个著录项目，如主要责任者、析出文献主要责任者专利申请者或所有者前不使用任何标识符号，按顺序编码制组织的参考文献表中的各篇文献序号用方括号，如：[1] 、[2]…。
]

#heading(level: 3, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  参考文献使用下列规定的标识符号：
]

#grid(
  row-gutter: 0.85em,
  columns: (3.5em, 1fr),
  [#h(2em).], [用于题名项、析出文献题名项、其他责在者、析出文献其他责任者、连续出版物的“年卷期或其他标识”项、版本项、出版项、连续出版物中析出文献的出处项、获取和访问路径以及数字对象唯一标识符前。每一条参考文献的结尾可用“.”号。]
)


#grid(
  row-gutter: 0.85em,
  columns: (3.65em, 1fr),
  [#h(2em):], [用于其他题名信息、出版者、引文页码、析出文献的页码、专利号前。]
)

#grid(
  row-gutter: 0.85em,
  columns: (3.65em, 1fr),
  [#h(2em),], [用于同一著作方式的责任者、“等”“译”字样、出版年、期刊年卷期标识中的年和卷号前。]
)

#grid(
  row-gutter: 0.85em,
  columns: (3.65em, 1fr),
  [#h(2em);], [用于同一责任者的合订题名以及期刊后续的年卷期标识与页码前。]
)

#grid(
  row-gutter: 0.85em,
  columns: (3.8em, 1fr),
  [#h(2em)\/\/], [用于同一责任者的合订题名以及期刊后续的年卷期标识与页码前。]
)

#grid(
  row-gutter: 0.85em,
  columns: (4.4em, 1fr),
  [#h(2em)\(\)], [用于期刊年卷期标识中的期号、报纸的版次、电子资源的更新或修改日期以及非公元纪年的出版年。]
)

#grid(
  row-gutter: 0.85em,
  columns: (4.4em, 1fr),
  [#h(2em)\[\]], [用于文献序号、文献类型标识、电子资源的引用日期以及自拟的信息。]
)

#grid(
  row-gutter: 0.85em,
  columns: (3.6em, 1fr),
  [#h(2em)\/], [用于合期的期号间以及文献载体标识前。]
)

#grid(
  row-gutter: 0.85em,
  columns: (3.5em, 1fr),
  [#h(2em)\-], [用于起讫序号和起讫页码间。]
)

== 著录细则
#v(-.25em)
=== 主要责任者或其他责任者
#v(.25em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  个人著者采用姓在前名在后的著录形式。欧美著者的名可用缩写字母，缩写名后省略缩写点。欧美著者的中译名只著录其姓；同姓不同名的欧美著者，其中译名不仅要著录其姓，还需著录其名的首  字母。依据 GB/T 28039—2011 有关规定，用汉语拼音书写的人名，姓全大写，其名可缩写，取每个汉字拼音的首字母。
]
#let phei(body) = text(font: "SimHei")[#body]

#v(-.4em)

#sbi[
#grid(
  columns: (2em, 5.6cm, 1fr),
  row-gutter: 0.85em,
  [#h(2em)],[#phei[示例1：]李时珍], [原题：(明)李时珍],
  [#h(2em)],[#phei[示例2：]乔纳斯], [原题：(瑞士)伊迪斯·乔纳斯],
  [#h(2em)],[#phei[示例3：]昂温], [原题：(美)S.昂温(Stephen Unwin)],
  [#h(2em)],[#phei[示例4：]昂温 G，昂温 P S], [原题：(英)G.昂温(G.Unwin)，P.S.昂温(P.S.Unwin)],
  [#h(2em)],[#phei[示例5：]丸山敏秋], [原题：(日)丸山敏秋],
  [#h(2em)],[#phei[示例6：]凯西尔], [原题：(阿拉伯)伊本·凯西尔],
  [#h(2em)],[#phei[示例7：]EINSTEIN A], [原题：Albert Einstein],
  [#h(2em)],[#phei[示例8：]WILLIAMS-ELLIS A], [原题：Amabel Williams-Ellis],
  [#h(2em)],[#phei[示例9：]DE MORGAN A], [原题：Augustus De Morgan],
  [#h(2em)],[#phei[示例10：]LI Jianning], [原题：Li Jianning],
  [#h(2em)],[#phei[示例11：]LI J N], [原题：Li Jianning],
)
]
#v(-.4em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  著作方式相同的责任者不超过3个时，全部照录。超过3个时，著录前3个责任者，其后加#box(width: 1em)[“,]等”或与之相应的词。
]
#v(-.4em)
#sbi[
#grid(
  columns: (2em, 5.6cm, 1fr),
  row-gutter: 0.85em,
  [#h(2em)],[#phei[示例1：]钱学森，刘再复], [原题：钱学森 刘再复],
  [#h(2em)],[#phei[示例2：]李四光，华罗庚，茅以升], [原题：李四光 华罗庚 茅以升],
  [#h(2em)],[#phei[示例3：]印森林，吴胜和，李俊飞，等], [原题：印森林 吴胜和 李俊飞 冯文杰],
)


#phei[示例4：]FORDHAM E W, ALI A, TURNER D A, et al.\
#h(5.3em)原题：Evens W. Fordham Amiad Ali David A. Turner John R. Charters
]

#v(-.4em)

#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  无责任者或者责任者情况不明的文献，“主要责任者”项应注明“佚名”或与之相应的词。凡采用顺序编码制组织的参考文献可省略此项，直接著录题名。
]

#v(-.4em)

#sbi[
#phei[示例：]#print-bib(keys: [#ref(label("8.1.3"))], number-style: "none", title: none, no-author: true)
]

#v(-.4em)

#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  凡是对文献负责的机关团体名称，通常根据著录信息源著录。机关团体名称应由上至下分级著录，上下级间用“.”分隔，用汉字书写的机关团体名称除外。
]
#v(-.4em)
#sbi[
#phei[示例1：]中国科学院物理研究所

#phei[示例2：]贵州省土壤普查办公室

#phei[示例3：]American Chemical Society

#phei[示例4：]Stanford University.Department of Civil Engineering
]

#v(.45em)
=== 题名
#v(.45em)

题名包括书名、刊名、报纸名、专利题名、报告名、标准名、学位论文名、档案名、舆图名、析出的文献名等。题名按著录信息源所载的内容著录。

#sbi[
#grid(
  columns: 2,
  row-gutter: 0.85em,
  [#h(2em)],[#phei[示例1：]王夫之“乾坤并建”的诠释面向],
  [#h(2em)],[#phei[示例2：]张子正蒙注],
  [#h(2em)],[#phei[示例3：]化学动力学和反应器原理],
  [#h(2em)],[#phei[示例4：]袖珍神学，或，简明基督教词典],
  [#h(2em)],[#phei[示例5：]北京师范大学学报(自然科学版)],
  [#h(2em)],[#phei[示例6：]Gases in sea ice 1975--1979],
)
#grid(
  columns: 2,
  row-gutter: 0.85em,
  [#h(2em)],[#phei[示例7：]J Math \& Phys],
)
]

#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  同一责任者的多个合订题名，著录前3个合订题名。对于不同责任者的多个合订题名，可以只 著录第一个或处于显要位置的合订题名。在参考文献中不著录并列题名。
]
#v(-.5em)
#sbi[
#grid(
  columns: (2em, 6.5cm, 1fr),
  row-gutter: 0.85em,
  [#h(2em)],[#phei[示例1：]为人民服务；纪念白求恩；愚公移山], [原题：为人民服务#h(1em)纪念白求恩#h(1em)愚公移山#h(2em)毛泽东著],
  [#h(2em)],[#phei[示例2：]大趋势], [原题：大趋势#h(2em)Megatrends],
)
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  文献类型标识(含文献载体标识)宜依附录B《文献类型和文献载体标识代码》著录。电子资源既要著录文献类型标识，也要著录文献载体标识。本标准根据文献类型及文献载体的发展现状作了必要 的补充。
]
#v(-.5em)#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  其他题名信息根据信息资源外部特征的具体情况决定取舍。其他题名信息包括副题名，说明题 名文字，多卷书的分卷书名、卷次、册次，专利号，报告号，标准号等。
]
#v(-.5em)
#sbi[
#phei[示例1：]地壳运动假说：从大陆漂移到板块构造[M]

#phei[示例2：]三松堂全集：第4卷[M]

#phei[示例3：]世界出版业：美国卷[M]

#phei[示例4：]ECL集成电路：原理与设计[M]

#phei[示例5：]中国科学技术史：第2卷\u{3000}科学思想史[M]

#phei[示例6：]商鞅战秋菊：法治转型的一个思想实验[J]

#phei[示例7：]中国科学：D辑\u{3000}地球科学[J]

#phei[示例8：]信息与文献——都柏林核心元数据元素集：GB/T 25100—2010[S]

#phei[示例9：]中子反射数据分析技术：CNIC-01887[R]

#phei[示例10：]Asian Pacific journal of cancer prevention: e-only
]

#v(.65em)

=== 版本

#v(.65em)

第1版不著录，其他版本说明应著录。版本用阿拉伯数字、序数缩写形式或其他标识表示。古籍的版本可著录“写本”“抄本”“刻本”“活字本”等。

#sbi[
#grid(
  columns: (2em, 4cm+1.5em, 1fr),
  row-gutter: 0.85em,
  [#h(2em)],[#phei[示例1：]3版], [原题：第三版],
  [#h(2em)],[#phei[示例2：]新1版], [原题：新1版],
  [#h(2em)],[#phei[示例3：]明刻本], [原题：明刻本],
  [#h(2em)],[#phei[示例4：]5th ed.], [原题：Fifth edition],
  [#h(2em)],[#phei[示例5：]Rev. ed.], [原题：Revised edition],
)
]
#v(.65em)
=== 出版项
#v(.65em)
出版项应按出版地、出版者、出版年顺序著录。

#sbi[
  #phei[示例1：]北京: 人民出版社, 2013

  #phei[示例2：]New York: Academic Press, 2012
]

#heading(level: 4, outlined: false)[出版地]
#v(-.5em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  出版地著录出版者所在地的城市名称。对同名异地或不为人们熟悉的城市名，宜在城市名后附省、州名或国名等限定语。
]
#v(-.5em)
#sbi[
  #phei[示例1：]Cambridge, Eng.

  #phei[示例2：]Cambridge, Mass.
]
#v(-.5em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  文献中载有多个出版地，只著录第一个或处于显要位置的出版地。
]
#v(-.5em)
#sbi[
  #phei[示例1：]北京: 科学出版社, 2013\
  #h(5.4em)原题：科学出版社#h(1em)北京#h(1em)上海#h(1em)2013

  #phei[示例2：]London: Butterworths, 2000\
  #h(5.4em)原题：Butterworths London Boston Durban   Syngapore Sydney Toronto Wellington 2000
]

#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  无出版地的中文文献著录“出版地不详”,外文文献著录“S.l.”,   并置于方括号内。无出版地的电子资源可省略此项。
]
#v(-.6em)
#sbi[
  #phei[示例1：]\[出版地不详\]: 三户图书刊行社, 1990

  #phei[示例2:]\[S.1.\]: MacMillan, 1975

  #phei[示例3：]Open University Press, 2011: 105[2014-06-16]. http://lib.myilibrary.com/Open,aspx?id=312377
]
#v(.15em)
#heading(level: 4, outlined: false)[出版者]
#v(-.35em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  出版者可以按著录信息源所载的形式著录，也可以按国际公认的简化形式或缩写形式著录。
]
#v(-.6em)
#sbi[
#grid(
  columns: (2em, 5.85cm, 1fr),
  row-gutter: 0.85em,
  [#h(2em)],[#phei[示例1：]中国标准出版社], [原题：中国标准出版社],
  [#h(2em)],[#phei[示例2：]Elsevier Science Publishers], [原题：Elsevier Science Publishers],
  [#h(2em)],[#phei[示例3：]IRRI], [原题：International Rice Research Institute],
)
]
#v(-.6em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  文献中载有多个出版者，只著录第一个或处于显要位置的出版者。
]
#v(-.6em)
#sbi[
  #phei[示例：]Chicago: ALA, 1978

  原题：American Library Assoclation / Chicago#h(2em)Canadian Library Association / Ottawa 1978
]
#v(-.6em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  无出版者的中文文献著录“出版者不详”,外文文献著录“s.n.”,并置于方括号内。无出版者的电子资源可省略此项。
]
#v(-.6em)
#sbi[
  #phei[示例1：]哈尔滨: [出版者不详], 2013

  #phei[示例2：]Salt Lake City: [s.n.], 1964
]
#v(.15em)
#heading(level: 4, outlined: false)[出版日期]
#v(-.25em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  出版年采用公元纪年#box(width: 1em)[，]并用阿拉伯数字著录。如有其他纪年形式时，将原有的纪年形式置于 “()”内。
]
#v(-.6em)
#sbi[
  #phei[示例1：]1947(民国三十六年)

  #phei[示例2：]1705(康熙四十四年)
]
#v(-.6em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  报纸的出版日期按照“YYYY-MM-DD”格式，用阿拉伯数字著录。
]
#v(-.6em)
#sbi[#phei[示例：]2013-01-08]
#v(-.6em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  出版年无法确定时，可依次选用版权年、印刷年、估计的出版年。估计的出版年应置于方括号内。
]
#v(-.6em)
#sbi[
  #phei[示例1：]c1988

  #phei[示例2：]1955 印刷

  #phei[示例3：]\[1936\]
]
#v(.35em)
#heading(level: 4, outlined: false)[公告日期、更新日期、引用日期]

#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  依据 GB/T 7408—2005 专利文献的公告日期或公开日期按照“YYYY-MM-DD”格式，用阿拉伯数字著录。
]
#v(-1.1em)
#heading(level: 5, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  依据 GB/T 7408—2005 电子资源的更新或修改日期#box(width: .5em)[、]引用日期按照#box(width: .5em)[“]YYYY-MM-DD#box(width: .5em)[”]格式#box(width: .25em)[，]用阿拉伯数字著录。
]
#v(-.6em)
#sbi[#phei[示例：]\(2012-05-03\)\[2013-11-12\]]
#v(.45em)
=== 页码
#v(.45em)
专著或期刊中析出文献的页码或引文页码#box(width: .4em)[，]应采用阿拉伯数字著录（参见8.8.2、10.1.3、10.2.4）。引自序言或扉页题词的页码，可按实际情况著录。

#sbi[
  #for i in range(1, 6) {
    set par(hanging-indent: 5.5em, first-line-indent: 0em)
    [#h(2em)#phei[示例#i：]#print-bib(keys: [#ref(label("8.5-" + str(i)))], number-style: "none", title: none)]
    v(0.85em, weak: true)
  }
]
#v(1.25em)
=== 获取和访问路径
#v(1.25em)
根据电子资源在互联网中的实际情况，著录其获取和访问路径。

#sbi[
  #for i in range(1, 3) {
    set par(hanging-indent: 5.85em, first-line-indent: 0em)
    [#h(2em)#phei[示例#i：]#print-bib(keys: [#ref(label("8.6-" + str(i)))], number-style: "none", title: none)]
    v(0.85em, weak: true)
  }
]
#v(1.25em)
=== 数字对象唯一标识符
#v(1.25em)
获取和访问路径中不含数字对象唯一标识符时，可依原文如实著录数字对象唯一标识符。否则，可省略数字对象唯一标识符。

#sbi[
  #phei[示例1：]获取和访问路径中不含数字对象唯一标识符
  #grid(
  columns: (5.4em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 2).map(i => (
    [],
    [#print-bib(keys: [#ref(label("8.7-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
#h(3.5em)（该书数字对象唯一标识符为：DOI:10.7666/d.y351065）
]

#sbi[
  #phei[示例1：]获取和访问路径中含数字对象唯一标识符
  #grid(
  columns: (5.4em, 1fr),
  row-gutter: 0.85em,
  ..(range(2, 3).map(i => (
    [],
    [#print-bib(keys: [#ref(label("8.7-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
#h(3.5em)（该书数字对象唯一标识符为：DOI:10.1002/9781444305036.ch2）
]

#v(1em)
=== 析出文献
#v(.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  从专著中析出有独立著者、独立篇名的文献按 4.2 的有关规定著录，其析出文献与源文献的关系用“\/\/”表示。凡是从报刊中析出具有独立著者、独立篇名的文献按 4.4 的有关规定著录，其析出文献与源文献的关系用“.”表示。关于引文参考文献的著录与标识参见 10.1.3 与 10.2.4。
]
#v(-.5em)
#sbi[
  #for i in range(1, 4) {
    set par(hanging-indent: 5.325em, first-line-indent: 0em)
    [#h(2em)#phei[示例#i：]#print-bib(keys: [#ref(label("8.8.1-" + str(i)))], number-style: "none", title: none)]
    v(0.85em, weak: true)
  }
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  凡是从期刊中析出的文章，应在刊名之后注明其年、卷、期、页码。阅读型参考文献的页码著录文章的起讫页或起始页，引文参考文献的页码著录引用信息所在页。
]
#v(-.5em)
#sbi[
  #phei[示例1：]2001, 1(1): 5-6

  #h(3.75em)年#h(1.1em)卷#h(.1em)期#h(.5em)页码

  #phei[示例2：]2014, 510: 356-363

  #h(3.75em)年#h(2em)卷#h(1.25em)页码

  #phei[示例3：]2010(6): 23

  #h(3.75em)年#h(.7em)期#h(.75em)页码

  #phei[示例4：]2012, 22(增刊2): 81-86

  #h(3.75em)年#h(1.4em)卷  期     页码
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  对从合期中析出的文献，按8.8.2的规则著录，并在圆括号内注明合期号。
]
#v(-.5em)
#sbi[
  #phei[示例：]2001(9/10): 36-39

  #h(3.25em)年#h(1.25em)期#h(2.25em)页码
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  凡是在同一期刊上连载的文献，其后续部分不必另行著录，可在原参考文献后直接注明后续部分的年、卷、期、页码等。
]
#v(-.5em)
#sbi[
  #phei[示例：]2011, 33(2): 20-25; 2011, 33(3): 26-30

  #h(3.25em)年#h(1.25em)期#h(2.25em)页码#h(1.75em)年#h(1.25em)期#h(2.25em)页码
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  凡是从报纸中析出的文献，应在报纸名后著录其出版日期与版次。
]
#v(-.5em)
#sbi[
  #phei[示例：]2013-03-16(1)

  #h(3.25em)年#h(.75em)月#h(.5em)日#h(.25em)版次
]

#v(-.7em)
== 参考文献表
#v(-.5em)
参考文献表可以按顺序编码制组织，也可以按著者-出版年制组织。引文参考文献既可以集中著录在文后或书末，也可以分散著录在页下端。阅读型参考文献著录在文后、书的各章节后或书末。
#v(.5em)
=== 顺序编码制
#v(.5em)
参考文献表采用顺序编码制组织时，各篇文献应按正文部分标注的序号依次列出(参见10.1)。

#sbi[
#phei[示例：]
#grid(
  columns: (2em, auto, 1em, 1fr),
  row-gutter: 0.85em,
  ..(range(1, 7).map(i => (
    [],
    [[#i]],
    [],
    [#print-bib(keys: [#ref(label("9.1-" + str(i)))], number-style: "none", title: none)],
  )).flatten())
)
]
#v(.5em)
=== 著者-出版年制
#v(.5em)
参考文献表采用著者-出版年制组织时，各篇文献首先接文种集中，可分为中文#box(width: .5em)[、]日文、西文、俄文、其他文种5部分；然后按著者字顺和出版年排列。中文文献可以接著者汉语拼音字顺排列(参见10.2), 也可以按著者的笔画笔顺排列。

#sbi[
  #phei[示例：]
  #grid(
    columns: (2em, 1fr),
    row-gutter: 0.85em,
    [], [
    #print-bib(
      keys: ("9.1-1", "9.1-2", "9.1-3", "9.1-4", "9.1-5", "9.1-6"),
      style: "author-year",
      sorting: "nyt",  // 按姓名（目前只支持拼音排序）→年→标题排序；也可用 "ynt"（年升序）/"yntd"（年降序）
      title: none, // 不要标题
    )]
  )
]
#v(-.7em)
== 参考文献标注法
#v(-.65em)
正文中引用的文献的标注方法可以采用顺序编码制，也可以采用著者-出版年制。

=== 顺序编码制
#v(.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  顺序编码制是按正文中引用的文献出现的先后顺序连续编码，将序号置于方括号中。如果顺序编码制用脚注方式时，序号可由计算机自动生成圈码。
]
#v(-.5em)
#sbi[
  #phei[示例 1：]引用单篇文献，序号置于方括号中

  ……德国学者 N. 克罗斯研究了瑞士巴塞尔市附近侏罗山中老第三纪断裂对第三系摺皱的控制#super[[25]];之后，他又描述 了西里西亚第3条大型的近南北向构造带，并提出地槽是在不均一的块体的基底上发展的思想#super[[236]]。

  …………

  #phei[示例 2：]引用单篇文献，序号由计算机自动生成圈码

  ……所谓“移情”,就是“说话人将自己认同于……他用句子所描写的事件或状态中的一个参与者”#super[①]。《汉语大词典》和张相#super[②]都认为“可”是“痊愈”,侯精一认为是“减轻”#super[③]。……另外，根据侯精一，表示病痛程度减轻的形容词“可”和表示逆转否定的副词“可”是兼类词#super[④],这也说明二者应该存在着源流关系。

  …………
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  同一处引用多篇文献时，应将各篇文献的序号在方括号内全部列出，各序号间用“,”。如遇连续序号，起讫序号间用短横线连接。此规则不适用于用计算机自动编码的序号。
]

#sbi[
  #phei[示例 ：]引用多篇文献

  裴伟#super[[570,8]]提出……

  莫拉德对稳定区的节理格式的研究#super[[255-256]]……
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  多次引用同一著者的同一文献时，在正文中标注首次引用的文献序号，并在序号的“[]”外著录引文页码。如果用计算机自动编序号时，应重复著录参考文献，但参考文献表中的著录项目可简化为文献序号及引文页码，参见本条款的示例2。
]

#set-bib-label("10.1.3-1-list")
#v(-.5em)
#sbi[
#phei[示例 1：]多次引用同一著者的同一文献的序号

……改变社会规范也可能存在类似的“二阶囚徒困境”问题：尽管改变旧的规范对所有人都好，但个人理性选择使得没有人愿意率先违反旧的规范@10.1.3-1-1。……事实上，古希腊对轴心时代思想真正的贡献不是来自对民主的赞扬，而是来自对民主制度的批评，苏格拉底、柏拉图和亚里士多德3位贤圣都是民主制度的坚决反对者@10.1.3-1-2[260]。……柏拉图在西方世界的影响力是如此之大以至于有学者评论说，一切后世的思想都是一系列为柏拉图思想所作的脚注@10.1.3-1-3。……据《唐会要》记载，当时拆毁的寺院有4600余所，招提、兰若等佛教建筑4万余所，没收寺产，并强迫僧尼还俗达260500人。佛教受到极大的打击@10.1.3-1-2[326-329]。……陈登原先生的考证是非常精确的，他印证了《春秋说题辞》“黍者绪也，故其立字，禾人米为黍， 为酒以扶老，为酒以序尊卑，禾为柔物，亦宜养老”,指出：“以上谓等威之辨，尊卑之序，由于饮食荣辱。”@10.1.3-1-4

  #phei[参考文献]
  #grid(
    columns: (2em, 1fr),
    row-gutter: 0.85em,
    [], [#print-bib(label: "10.1.3-1-list", title: none, after-number-sep: 1em) ]
  )

  #phei[示例 2：]多次引用同一著者的同一文献的脚注序号

……改变社会规范也可能存在类似的“二阶囚徒困境”问题：尽管改变旧的规范对所有人都好，但个人理性选择使得没有人愿意率先违反旧的规范#super[①]。……事实上，古希腊对轴心时代思想真正的贡献不是来自对民主的赞扬，而是来自对 民主制度的批评，苏格拉底、柏拉图和亚里士多德3位贤圣都是民主制度的坚决反对者#super[②]……柏拉图在西方世界的影像力是如此之大以至于有学者评论说，一切后世的思想都是一系列为柏拉图思想所作的脚注#super[③]。……据《唐会要》记载，当时拆毁的寺院有4600余所，招提、兰若等佛教建筑4万余所，没收寺产，并强迫僧尼还俗达260 500人。佛教受到极大的打击#super[④]。……陈登原先生的考证是非常精确的，他印证了《春秋说题辞》“黍者绪也，故其立字，禾入米为黍，为酒以扶老，为酒以序尊卑，禾为柔物，亦宜养老”,指出：“以上谓等威之辨，尊卑之序，由于饮食荣辱。”
#set-bib-label("10.1.3-2-list")

#phei[参考文献]

#grid(
    columns: (2em, 2em, 1fr),
    row-gutter: 0.85em,
    [], [①], [SUNSTEIN C R. Social norms and social roles[J/OL]. Columbia law review, 1996, 96: 903.[2012-01-26]. #link("http://www.heinonline.org/HOL/Page?handle=hein.journals/clr96&id=913&collection=journals&index=journals/clr.")],
    [], [②], [ MORRI I. Why the west rules for now: the patterns of history, and what they reveal about the future[M]. New York: Farrar, Straus and Giroux, 2010: 260.],
    [], [③], [罗杰斯. 西方文明史：问题与源头[M]. 潘惠霞, 魏婧, 杨艳, 等译. 大连: 东北财经大学出版社, 2011: 15-16.],
    [], [④], [同②326-329.],
    [], [⑤], [陈登原. 国史旧闻：第1卷[M]. 北京: 中华书局, 2000: 29.],
  )
]
#v(1em)
=== 著者-出版年制
#v(.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  正文引用的文献采用著者出版年制时，各篇文献的标注内容由著者姓氏与出版年构成，并置于“()”内。倘若只标注著者姓氏无法识别该人名时，可标注著者姓名，例如中国人、韩国人、日本人用汉字书写的姓名。集体著者著述的文献可标注机关团体名称。倘若正文中已提及著者姓名，则在其后的“()”内只著录出版年。
]
// 切换新列表并指定著者-出版年制
#set-bib-label("10.2.1-list")
#v(-.5em)
#sbi[
#phei[示例：]引用单篇文献

The notion of an invisible college has been explored in the sciences @10.2.1-1. Its absene among historians was
noted by @10.2.1-2 …

#phei[参考文献]

#grid(
    columns: (2em, 1fr),
    row-gutter: 0.85em,
    [], [// 打印该列表也用著者-出版年格式
#print-bib(label: "10.2.1-list", style: "author-year", title: none)]
  )
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  正文中引用多著者文献时，对欧美著者只需标注第一个著者的姓，其后附“et al.”；对于中国著者应标注第一著者的姓名，其后附“等”字。姓氏与“et al.”“等”之间留适当空隙。
]
#v(-.5em)
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  在参考文献表中著录同一著者在同一年出版的多篇文献时，出版年后应用小写字母 a,b,c…区别。
]
#v(-.5em)
#sbi[
#set-bib-label("10.2.3-1-list")
#phei[示例1：]引用同一著者同年出版的多篇中文文献#hide[@10.2.3-1-1@10.2.3-1-2]

#phei[参考文献]

#grid(
    columns: (2em, 1fr),
    row-gutter: 0.85em,
    [], [// 打印该列表也用著者-出版年格式
#print-bib(label: "10.2.3-1-list", sort-keys: [@10.2.3-1-1@10.2.3-1-2], style: "author-year", title: none)]
  )

#set-bib-label("10.2.3-2-list")
#phei[示例2：]引用同一著者同年出版的多篇英文文献#hide[@10.2.3-2-1@10.2.3-2-2]

#phei[参考文献]

#grid(
    columns: (2em, 1fr),
    row-gutter: 0.85em,
    [], [// 打印该列表也用著者-出版年格式
#print-bib(label: "10.2.3-2-list", style: "author-year", title: none)]
  )
]
#v(-.5em)
#heading(level: 4, outlined: false)[
  #set text(font: ("Founder-S10-BZ", "SimSun"))
  多次引用同一著者的同一文献，在正文中标注著者与出版年，并在“()”外以角标的形式著录引文页码。
]
#v(-.5em)
#sbi[
#set-bib-label("10.2.4-list")
#phei[示例：]多次引用同一著者的同一文献

主编靠编辑思想指挥全局已是编辑界的共识@10.2.4-3,然而对编辑思想至今没有一个明确的界定，故不妨提出一个构架……参与讨论。由于“思想”的内涵是“客观存在反映在人的意识中经过思维活动而产生的结果”@10.2.4-4[1194],所以“编辑思想”的内涵就是编辑实践反映在编辑工作者的意识中，“经过思维活动而产生的结果”。……《中国青年》杂志创办人追求的高格调——理性的成熟与热点的凝聚@10.2.4-2,表明其读者群的文化的品位的高层次……“方针”指“引导事业前进的方向和目标”@10.2.4-4[235]。……对编辑方针，1981年中国科协副主席裴丽生曾有过科学的论断——“自然科学学术期刊应坚持以马列主义、毛泽东思想为指导，贯彻为国民经济发展服务，理论与实践相结合，普及与提高相结合，‘百花齐放，百家争鸣’的方针。”@10.2.4-1 它完整地回答了为谁服务，怎样服务，如何服务得更好的问题。
// Typst 目前不允许孤行

…………

#phei[参考文献]

#grid(
    columns: (2em, 1fr),
    row-gutter: 0.85em,
    [], [#print-bib(label: "10.2.4-list", style: "author-year", title: none, sort-keys: [@10.2.4-1@10.2.4-2@10.2.4-3@10.2.4-4])]
  )
]

…………

#set-bib-label(none)

#pagebreak()
// 进入附录
#counter(heading).update(0)

#set heading(numbering: (..nums) => {
  let n = nums.pos()
  if n.len() == 1 {
    "附录 " + numbering("A", n.at(0))
  } else if n.len() == 2 {
    numbering("A", n.at(0)) + "." + str(n.at(1))
  }
})

#show heading.where(level: 1): it => {
  let num = counter(heading).display((..nums) => {
    numbering("A", nums.pos().at(0))
  })
  block(width: 100%, align(center)[
    #set text(size: zh(5))
    #phei[附#h(1em)录#h(1em)#num] \
    #phei[#it.body]
  ])
}

#show heading.where(level: 2): it => {
  v(1.5em)
  set text(font: "SimHei", size: 10.0375pt)
  par(first-line-indent: 0em)[#context counter(heading).display((..nums) => {
    let n = nums.pos()
    numbering("A", n.at(0)) + "." + str(n.at(1))
  })#h(1em)#it.body]
  v(1.5em)
}

= （资料性附录）\ 顺序编码制参考文献表著录格式示例

== 普通图书

#print-bib(
  entrytype: "book",
  bib-file: "2015-appx",
  full: true
)

== 论文集、会议录

#print-bib(
  entrytype: ("collection", "proceedings"),
  bib-file: "2015-appx",
  full: true
)

== 报告

#print-bib(
  type: ("R"),
  bib-file: "2015-appx",
  full: true
)

== 学位论文

#print-bib(
  type: ("D"),
  bib-file: "2015-appx",
  full: true
)

== 专利文献

#print-bib(
  type: ("P"),
  bib-file: "2015-appx",
  full: true
)

== 标准文献

#print-bib(
  type: ("S"),
  filter: e => e.entry_type not in ("inbook"), // 排除掉析出标准
  bib-file: "2015-appx",
  full: true
)

== 专著中析出的文献

#print-bib(
  entrytype: ("inbook", "inproceedings"), // 析出专利也用 inbook 就可以被匹配了
  bib-file: "2015-appx",
  full: true
)

== 期刊中析出的文献

#print-bib(
  type: ("J"),
  bib-file: "2015-appx",
  full: true
)

== 报纸中析出的文献

#print-bib(
  type: ("N"),
  bib-file: "2015-appx",
  full: true
)

==  电子资源（不包括电子专著、电子连续出版物、电子学位论文、电子专利）

#print-bib(
  type: "EB",
  bib-file: "2015-appx",
  full: true
)

#pagebreak()
= (资料性附录) \ 文献类型和文献载体标识代码