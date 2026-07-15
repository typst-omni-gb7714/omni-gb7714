//! param: footnote-repeat-style
//! values: auto, "full", "number", "shortened", "reuse"
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "footnote-repeat-style", controls: "脚注制下*重复*引用同一文献时脚注里装什么。",
  expect: [首次恒为完整著录（官方 note CSL 与全部社区方言一致）。本参数只管重复位；
    *紧邻*位的「同上」简化由 `footnote-ibid` 独立控制，两参正交出全部有据体例：
    - `auto`（缺省）= `"number"`：配合缺省 `footnote-ibid: true` 即官方 note CSL 的梯子——紧邻「同上(: 页码)」、隔开「同③(: 页码)」；
    - `"full"`：重复著录整条（GB §9.2.1.3「重复著录」正统，社区方言主流）；
    - `"number"`：同③（首注号；圈码*自动镜像*文档当前的脚注编号样式）；
    - `"shortened"`：缩略「责任者. 题名[标识].」（完整注的缩减产物，CMOS 术语；页码接独立著录段）；
    - `"reuse"`：*不发新注*，正文上标复用首注号——唯一装不下页码的值。
    「同上」「同」两词可经 `custom-terms` 的 `ibid`（纯词）与 `footnote-number`（前后缀对）覆写，按*文档语言*取词。])
#let ladder = [首 #cite(<bm-zh>) 邻 #cite(<bm-zh>) 换 #cite(<bm-en>) 隔 #cite(<bm-zh>) 带页码 #cite(<bm-zh>, supplement: [88])。]
#case("auto（缺省 → number）", gb7714.with(cite-footnote: true), full: false, body: ladder)
#case(`"full"`.text + "（重复著录整条）", gb7714.with(cite-footnote: true, footnote-repeat-style: "full"), full: false, body: ladder)
#case(`"number"`.text, gb7714.with(cite-footnote: true, footnote-repeat-style: "number"), full: false, body: ladder)
#case(`"shortened"`.text, gb7714.with(cite-footnote: true, footnote-repeat-style: "shortened"), full: false, body: ladder)
#case(`"reuse"`.text + "（不发新注，正文复用首注号；装不下页码）", gb7714.with(cite-footnote: true, footnote-repeat-style: "reuse"), full: false, body: ladder)
#case(`"full"`.text + " + footnote-ibid: false（GB 纯重复著录）", gb7714.with(cite-footnote: true, footnote-repeat-style: "full", footnote-ibid: false), full: false, body: ladder)
#case(`"shortened"`.text + " + footnote-ibid: false（Chicago 17th 全缩略）", gb7714.with(cite-footnote: true, footnote-repeat-style: "shortened", footnote-ibid: false), full: false, body: ladder)
#case("custom-terms 覆写 ibid（纯词或 (text:, supplement-separator:) 字典）与 footnote-number（三槽）", gb7714.with(cite-footnote: true,
  custom-terms: (ibid: (zh: "同前注"), footnote-number: (zh: (prefix: "见注", suffix: "", supplement-separator: "，第")))), full: false, body: ladder)
