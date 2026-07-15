//! param: et-al-translator-separator
//! values: auto, string, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "et-al-translator-separator", controls: "译者截断词与角色词之间的接缝（「等译」里有没有那个逗号）。",
  expect: [`auto`（缺省）下*中文紧贴*，得国标形「，等译．」；西文仍是逗号（`..., et al., trans.`），
    日文紧贴、韩文空格。

    中文紧贴的依据是**起草人明示**——陈浩元《GB/T 7714 新标准对旧标准的主要修改及实施要点提示》
    （编辑学报 2015, 27(4)）§3.3-7：「当遇到『等』『译』连用时，参照新标准给出的示例，可著录为
    『，等译．』，即『译』前不必标注『，』」。他是三个版本的主要起草人之一。

    ⚠️本项曾以社区 CSL 的「等, 译」为缺省——社区样式不是权威，起草人是。设 `", "` 可回到旧形。

    只管*译者被截断*的那一处：编者的「等主编」紧贴是 GB 惯例，未截断时「，译」前的逗号是国标明文
    （「『等』『译』字样前的标识符号为『，』」），两者都不归本项管。收多语言字典，未点到的语言退回
    `auto` 档派生值。])
#let cs = (<nm-translator>,)
#case("auto（缺省，国标形「等译」）", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1), bib: EDGE, cites: cs, full: false)
#case(`", "`.text + "（回到社区 CSL 的「等, 译」）", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, et-al-translator-separator: ", "), bib: EDGE, cites: cs, full: false)
#case(`"、"`.text, gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, et-al-translator-separator: "、"), bib: EDGE, cites: cs, full: false)
#case("多语言字典 (zh: 「, 」, rest: 「」)", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, et-al-translator-separator: (zh: ", ", rest: "")), bib: EDGE, cites: cs, full: false)
