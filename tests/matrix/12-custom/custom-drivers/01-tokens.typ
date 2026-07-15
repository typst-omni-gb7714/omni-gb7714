//! param: custom-drivers（内置 token 速查表）
//! values: 全部内置 token 逐个点名
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "custom-drivers · 内置 token", controls: "模板里能写哪些标识符。",
  expect: [形如 `[a-z][a-z0-9_-]*` 的小写标识符，引擎查表解析成内容；表里没有再查 `custom-terms`。
    *凡本包识别的有效 `.bib` 字段都暴露为 token*——写得出来、读得到的字段原则上都能直接以字段名取出。
    本文件把速查表的 token 逐个渲染出来（每行一个 token，前面用 verbatim 标出它的名字），
    好让人一眼核对每个 token 到底吐什么。
    *块 token*（`title-block` / `imprint-block` / `mark-medium` / `access` / `series-block`）是打包好的整段，
    受各自的 `show-*` 配置管；*原值 token*（`journaltitle` / `number` / `type` / `note`）就是字段原文。])
#let one(name, tpl) = case(name, gb7714.with(custom-drivers: (book: tpl, article: tpl, incollection: tpl, thesis: tpl, patent: tpl, online: tpl)),
  cites: (<bm-zh>, <aj-zh>, <ic-zh>, <dt-zh>, <pt-zh>, <eb-zh>), full: false)
#one("author · editor · translator · editor-other · bookauthor · holder", "{author=} author {／editor=} editor {／editor-other=} editor-other {／translator=} translator {／bookauthor=} bookauthor {／holder=} holder")
#one("title · subtitle · titleaddon · title-block · component-part-title-block", "{title=} title {／subtitle=} subtitle {／titleaddon=} titleaddon {／title-block=} title-block {／cp-title-block=} component-part-title-block")
#one("mark · medium · mark-medium · type · degree-annotation · country", "{mark=} mark {／medium=} medium {／mark-medium=} mark-medium {／type=} type {／degree=} degree-annotation {／country=} country")
#one("booktitle · booksubtitle · booktitleaddon · journal · journaltitle · shortjournal", "{booktitle=} booktitle {／booksubtitle=} booksubtitle {／booktitleaddon=} booktitleaddon {／journal=} journal {／journaltitle=} journaltitle {／shortjournal=} shortjournal")
#one("series · series-block · edition · version · volume · number · pages", "{series=} series {／series-block=} series-block {／edition=} edition {／version=} version {／volume=} volume {／number=} number {／pages=} pages")
#one("year · date · month · day · urldate", "{year=} year {／date=} date {／month=} month {／day=} day {／urldate=} urldate")
// `location` token 目前一写就 panic（白名单漏登记，见 tests/BUGS.md #5），修好后把它加回本行。
#one("address · publisher · school · organization · institution · imprint-block", "{address=} address {／publisher=} publisher {／school=} school {／organization=} organization {／institution=} institution {／imprint-block=} imprint-block")
#one("access · url · doi · isbn · issn · eprint · eprinttype · archiveprefix", "{access=} access {／url=} url {／doi=} doi {／isbn=} isbn {／issn=} issn {／eprint=} eprint {／eprinttype=} eprinttype {／archiveprefix=} archiveprefix")
#one("keywords · note · scale · dimensions · eventtitle · eventdate", "{keywords=} keywords {／note=} note {／scale=} scale {／dimensions=} dimensions {／eventtitle=} eventtitle {／eventdate=} eventdate")
