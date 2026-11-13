//! param: 机构名识别（单花括号 + 企业标识词）→ 照录不缩写
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "机构名（企业标识词）照录", controls: "无逗号的机构名被 citegeist 拆成 given+family 后，如何避免被当人名缩写。",
  expect: [双花括号 `{{…}}` 的机构名（无 `given`、`family` 含空格）走 `_is-org`，照录。\
    但*单花括号*的机构名（`{Trisco ICAP Pty Ltd}`）无逗号，被 citegeist 拆成 `given`（Trisco ICAP Pty）+
    `family`（Ltd），逃过 `_is-org`，会被当人名缩写成「Ltd T I P」。

    修复：末词命中*企业标识词保守集*（ltd / inc / llc / plc / corp / gmbh / ag / pty / co / company / … ）时判为
    机构，按原序 `given + family` 平铺照录。

    *但带逗号的一律不进企业判定*：`Co`、`Ag`、`Sa`、`Inc` 都是真姓，`Co, Carl` 这种「姓, 名」写法在 BibTeX 里
    只可能是人名。解析结果不保留逗号，从条目原始字段串（`keep-raw-names`）按 ` and ` 切段核对「姓,」起头。
    于是 `Co, Carl` -> `Co C`、`{Co}, Carl` 同、`Sa, Dong and Trisco ICAP Pty Ltd` 一人一机构各归各。
    剩下的误判只有「无逗号 + 姓恰是标识词」（`Carl Co`），bibtex 自己也分不了，接受。

    *著者-出版年制的正文标注同样照录全名*：只姓形态原先直接取拆出来的 `family`，机构名标成 `(Ltd, 2020)`；
    现在先过同一个企业判定、命中交 `format-one`，得 `(Trisco ICAP Pty Ltd, 2020)`；双花括号机构与人名不受影响。

    - *专利机构权人*：`holder={Trisco ICAP Pty Ltd}`（单花括号）→「Trisco ICAP Pty Ltd」，不再是「Ltd T I P」。
      对齐 GB/T 7714 专利示例的机构权人照录（2015 附录 A.5「河北绿洲…有限公司」亦照录）。
    - *双花括号机构*：`author={{国家标准化管理委员会}}` → 照录（走 `_is-org`，本就正确）。
    - *真人名对照*：`author={Roe, Richard}` → 缩写「Roe R」。末词「Roe」不在企业词表，不误判——修复不波及普通姓名。

    企业词表取*保守*西文常见后缀；中文机构惯用双花括号、走 `_is-org`，不依赖本表。])
#let cb = bytes("@patent{pat, author={Tristram, Michael and Skarshewski, Peter}, holder={Trisco ICAP Pty Ltd}, date={2022-10-06}, langid={american}, location={AU}, number={AU2022228203A}, title={Storage and Delivery System}, type={patent}}
@book{corp, author={Example Research Co}, title={A Report}, date={2020}, langid={american}, location={NY}, publisher={Self}}
@book{org2, author={{国家标准化管理委员会}}, title={某规范汇编}, date={2021}, langid={chinese}, location={北京}, publisher={中国标准出版社}}
@book{person, author={Roe, Richard and Poe, Edgar and Doe, Jane}, title={A Control}, date={2019}, langid={american}, location={NY}, publisher={Wiley}}")
#case("单花括号机构：专利权人 holder / 作者末词企业词 → 照录", gb7714.with(), bib: cb, cites: (<pat>, <corp>), full: false)
#case("对照：双花括号中文机构照录 · 真人名照常缩写", gb7714.with(), bib: cb, cites: (<org2>, <person>), full: false)
#let cc = bytes("@book{cc1, author={Co, Carl}, title={A}, publisher={P}, address={X}, year={2020}, langid={english}}
@book{cc2, author={Inc, Ian}, title={B}, publisher={P}, address={X}, year={2020}, langid={english}}
@book{cc3, author={{Co}, Carl}, title={C}, publisher={P}, address={X}, year={2020}, langid={english}}
@book{cc4, author={Sa, Dong and Trisco ICAP Pty Ltd}, title={D}, publisher={P}, address={X}, year={2020}, langid={english}}
@book{cc5, editor={Ag, Anna}, title={E}, publisher={P}, address={X}, year={2020}, langid={english}}
@book{cc6, author={Acme Inc}, title={F}, publisher={P}, address={X}, year={2020}, langid={english}}")
#case("姓恰是标识词但写了逗号 → 人名（Co C / Inc I / Ag A）；无逗号的 Acme Inc 仍是机构", gb7714.with(), bib: cc, full: true)
#let ay = bytes("@book{ay1, author={Trisco ICAP Pty Ltd}, title={A}, publisher={P}, address={X}, year={2020}, langid={english}}
@book{ay2, author={{World Health Organization}}, title={B}, publisher={P}, address={X}, year={2021}, langid={english}}
@book{ay3, author={Acme Inc and Doe, Jane}, title={C}, publisher={P}, address={X}, year={2022}, langid={english}}
@book{ay4, author={Co, Carl}, title={D}, publisher={P}, address={X}, year={2023}, langid={english}}")
#case("著者-出版年制标注：单花括号机构照录全名（不再 (Ltd, 2020)）· 双花括号机构 · 机构 et al. · 人名只姓", gb7714.with(style: "author-date"), bib: ay, cites: (<ay1>, <ay2>, <ay3>, <ay4>), full: true)
