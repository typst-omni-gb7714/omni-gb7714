//! param: bib-name-style(given-form: "pinyin-initials")
//! values: 标量 pinyin-initials, 字典 (pinyin: pinyin-initials, rest: initials), 2015 缺省, 2025 缺省
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "given-form: \"pinyin-initials\"", controls: "拼音名的名按音节逐节缩首字母（`Yanshuo` -> `Y S`）。",
  expect: [2015 / 2005 文献表缺省走 `(pinyin: "pinyin-initials", rest: "initials")`：拼音名 `CHU Y S`、`PAN E T`、`WANG X Y`
    （对齐李泽平 bst 的 initializepinyin 默认），西文名仍单首字母；2025 缺省拼音名全拼不变。
    *标量*档不做拼音检测——能切就切（`Anna` 也切成 `A N`）；*字典*档才检测，且配中国姓的西文常用名
    （Anna Wang、Lisa Chen）有阻断表拦下、退回单首字母。已有分隔符的 `Yan-Shuo` / `Yan Shuo` 走既有分段。
    切点从长到短找：`Changan` 得 `C A`（长安）；歧义用 `Chang'an` 强制。])
#let PY = bytes("@book{p1, author={Chu, Yanshuo and Pan, Erting and Wang, Xinya}, title={Alpha}, publisher={P}, address={X}, date={2020}, langid={english}}
@book{p2, author={Chu, Yan-Shuo and Ouyang, Xiu and Li, Changan}, title={Beta}, publisher={P}, address={X}, date={2021}, langid={english}}
@book{p3, author={Wang, Anna and Chen, Lisa and Smith, Anna}, title={Gamma}, publisher={P}, address={X}, date={2022}, langid={english}}")
#case("2015 缺省：拼音名逐音节缩，西文名单首字母", gb7714.with(version: 2015), bib: PY, full: true)
#case("2005 缺省：同 2015", gb7714.with(version: 2005), bib: PY, full: true)
#case("2025 缺省：拼音名全拼不变", gb7714.with(), bib: PY, full: true)
#case("标量 pinyin-initials（不检测，Anna 也切）", gb7714.with(version: 2015, bib-name-style: (given-form: "pinyin-initials")), bib: PY, full: true)
#case("显式标量 initials：整名单首字母（退路一）", gb7714.with(version: 2015, bib-name-style: (given-form: "initials")), bib: PY, full: true)
#case("2025 + 字典 (pinyin: pinyin-initials, rest: initials)", gb7714.with(bib-name-style: (given-form: (pinyin: "pinyin-initials", rest: "initials"))), bib: PY, full: true)
