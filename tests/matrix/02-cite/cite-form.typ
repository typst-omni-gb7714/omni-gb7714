//! param: cite-form
//! values: auto, super, inline, normal, prose, author, year, none
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "cite-form", controls: "正文引用标注的形态。",
  expect: [`auto` 随制度：顺序编码制 `super`（上标 [1]）、著者-出版年制 `normal`（括号内）。
    `prose` 把责任者移出括号（「张三（2020）指出」）；`author` / `year` 只出一半；`none` 只注册不显示。
    上标形态吃引用号前的空格（对齐原生「词[1]」）。])
#let probe-cites = [词 #cite(<bm-zh>) 与 #cite(<bm-en>)。]
#cite-only("auto · 顺序编码制（→ super）", gb7714.with(), body: probe-cites)
#cite-only("auto · 著者-出版年制（→ normal）", gb7714.with(style: "author-date"), body: probe-cites)
#cite-only("super", gb7714.with(cite-form: "super"), body: probe-cites)
#cite-only("inline", gb7714.with(cite-form: "inline"), body: probe-cites)
#cite-only("normal", gb7714.with(cite-form: "normal"), body: probe-cites)
#cite-only("prose · 著者-出版年制", gb7714.with(style: "author-date", cite-form: "prose"), body: probe-cites)
#cite-only("prose · 顺序编码制", gb7714.with(cite-form: "prose"), body: probe-cites)
#cite-only("author · 著者-出版年制", gb7714.with(style: "author-date", cite-form: "author"), body: probe-cites)
#cite-only("year · 著者-出版年制", gb7714.with(style: "author-date", cite-form: "year"), body: probe-cites)
#cite-only("none（只注册不显示）", gb7714.with(cite-form: none), body: probe-cites)

// `form: "full"` 的*裸* / 合成 `std.cite`（元素自带 `form: "full"`，非经 omni markup 包装器造，
//   如 Touying `bibliography-as-footnote` 在 show 规则里重发的、或用户直接写的 `std.cite(k, form:"full")`）：
//   应原位完整著录，而非退化成 [N]。markup `#cite(form:"full")` 见 14-per-cite/overrides。
#let _synth = [
  #show std.cite.where(form: "normal"): it => std.cite(it.key, form: "full")
  正文 @bm-zh @bm-en。
]
#case("form:full · 裸/合成 std.cite · 顺序编码制", gb7714.with(version: 2025), bib: MAIN, body: _synth)
#case("form:full · 裸/合成 std.cite · 著者-出版年制", gb7714.with(version: 2025, style: "author-date"), bib: MAIN, body: _synth)
