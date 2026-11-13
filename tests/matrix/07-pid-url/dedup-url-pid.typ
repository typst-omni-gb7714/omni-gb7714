//! param: dedup-url-pid
//! values: auto, true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "dedup-url-pid", controls: "标识符已被 URL 承载时，是否不重复著录（GB/T 7714—2025 §7.9.1）。",
  expect: [`true`（= `auto` 缺省）：*精确值匹配*——著录出来的获取路径（URL）里含该标识符的字面值时抑制它
    （`https://doi.org/10.1234/abc` 含 `10.1234/abc` → DOI 不重复）。只按值匹配，*不*按类型标记（曾用「URL 含
    `doi.org/` 就压 DOI」，会把指向另一资源的 DOI/arXiv 误压，已删）。
    eprint 用*剥掉体系标签后的裸 id* 比对：`PSSXiv:202408.01096` 著录时剥成 `202408.01096`，url `.../abs/202408.01096`
    含裸 id → 抑制该 eprint（§7.9.1 的 PID 指裸 id，不含 `PSSXiv:` 标签）；CSTR / DOI 无标签，按原值比。
    `false`：关闭去重，标识符不论 URL 内容一律独立输出。
    `show-pid` 里显式置 `true` 的标识符*总是强制显示*，本参数只影响 `auto` 状态者。])
#let cs = (<pid-all>, <bm-online>)
#let m = bytes(read("/tests/_fixture/main.bib")) + bytes(read("/tests/_fixture/edge.bib"))
// 预印本：cstr + eprint 指向同一篇（cstr 资源段含 eprint 平台号），eprint 裸 id 又在 url 里。
//   §7.9.1 → eprint 被 url 压掉，只留 cstr（对齐国标 §8.15.2 示例，只出 CSTR）。
#let PP = bytes("@online{pp-eprint, author={{肖玲}}, title={数据要素的统计测算方法探究}, eprint={PSSXiv:202408.01096}, eprinttype={PSSXiv}, cstr={32012.36.PSSXiv.202408.01096}, url={https://zsyyb.cn/abs/202408.01096}, date={2024-07-02}, urldate={2024-09-30}, langid={chinese}}")
#case("auto（缺省 → true，DOI 被 URL 承载 → 不重复著录）", gb7714.with(show-pid: (doi: auto)), bib: m, cites: cs, full: false)
#case("false（关闭去重，DOI 独立输出）", gb7714.with(show-pid: (doi: auto), dedup-url-pid: false), bib: m, cites: cs, full: false)
#case("true + show-pid: (doi: true)（显式 true 强制直通，去重不生效）", gb7714.with(show-pid: (doi: true)), bib: m, cites: cs, full: false)
#case("false + max: 1（去重关 → URL 承载的标识符不再计入配额）", gb7714.with(show-pid: (rest: true, doi: true, max: 1), dedup-url-pid: false), bib: m, cites: cs, full: false)
#case("eprint 裸 id 在 url 里 → 剥标签后被压，只留 cstr（§7.9.1 / §8.15.2）", gb7714.with(version: 2025), bib: PP, cites: (<pp-eprint>,), full: true)
#case("同上但 dedup-url-pid: false → eprint 照常独立输出（PSSXiv:202408.01096）", gb7714.with(version: 2025, dedup-url-pid: false), bib: PP, cites: (<pp-eprint>,), full: true)
