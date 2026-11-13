//! param: et-al-translator-separator
//! values: auto, string, dictionary
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "et-al-translator-separator", controls: "译者截断词与角色词之间的接缝（「等译」里有没有那个逗号）。",
  expect: [`auto`（缺省）下中文*按版本*派生：2005 / 2025 出「，等，译．」（译前加逗号），2015 出「，等译．」
    （紧贴）；西文仍是逗号（`..., et al., trans.`），日文紧贴、韩文空格。

    版本差异的依据：三版《著录用符号》规则条文一致，都把「，」列在「等」「译」字样之前。2025 §8 示例[3]
    （罗杰斯《西方文明史》）已著录为「潘惠霞，魏婧，杨艳，等，译」。2015 §8 同一示例却写作「等译」，与其自身
    §7.2 规则相左；起草人陈浩元《GB/T 7714 新标准对旧标准的主要修改及实施要点提示》（编辑学报 2015）认可
    此紧贴形，故 2015 尊其诠释。

    显式值统一覆盖版本缺省：`""` 强制紧贴「等译」、`", "` 强制加逗号「等, 译」。只管*译者被截断*的那一处：
    编者的「等主编」各版本恒紧贴，未截断时「，译」前的逗号是国标明文，两者都不归本项管。收多语言字典，未点到
    的语言退回 `auto` 档派生值。])
#let cs = (<nm-translator>,)
#case("auto 缺省（默认版本 2025 → 「，等，译」）", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1), bib: EDGE, cites: cs, full: false)
#case("version: 2015（→ 紧贴「，等译」，尊起草人诠释）", gb7714.with(version: 2015, bib-et-al-min: 1, bib-et-al-use-first: 1), bib: EDGE, cites: cs, full: false)
#case(`""`.text + "（强制紧贴「等译」，覆盖版本缺省）", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, et-al-translator-separator: ""), bib: EDGE, cites: cs, full: false)
#case(`", "`.text + "（强制加逗号，得社区 CSL 的「等, 译」）", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, et-al-translator-separator: ", "), bib: EDGE, cites: cs, full: false)
#case(`"、"`.text, gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, et-al-translator-separator: "、"), bib: EDGE, cites: cs, full: false)
#case("多语言字典 (zh: 「, 」, rest: 「」)", gb7714.with(bib-et-al-min: 1, bib-et-al-use-first: 1, et-al-translator-separator: (zh: ", ", rest: "")), bib: EDGE, cites: cs, full: false)
