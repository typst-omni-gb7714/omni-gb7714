//! param: edition 西文缩写点·版本感知（GB §7.4 唯一「2025 去点」的西文缩写）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "edition 缩写点", controls: "西文版次序数缩写（`ed` / `éd` / `изд`）的末项缩写点*版本感知*：2025 不带点（`5th ed`），2015 / 2005 带点（`5th ed.`）。这是 GB/T 7714 §7.4 里 2025 版*唯一*去点的西文缩写——`et al.` / `[S.l.]` / `[s.n.]` / 地点缩写两版都带点、名缩写两版都无点，均不涉及。",
  expect: [核对自两版国标原文（§7.4 / §8.3 示例列）:2015 印 `5th ed.`、2025 印 `5th ed`(孤立示例列里 `ed` 后无元素,那点必是缩写点)。

    - *单块 / 演示片段*(版次是整条唯一著录项):版本感知显现——2025 `5th ed` / `2e éd` / `2-е изд`(无点);2015 `5th ed.` / `2e éd.` / `2-е изд.`(带点)。
    - *多块著录*(版次后紧跟出版信息):末项缩写点被「版本 . 出版」的段间句点*抹平*——两版都渲染成 `5th ed. 出版地…`(一个点),对正常语料*零影响*。这是本设计成立的关键:区别只落在孤立演示片段。
    - 中日韩「版 / 판」非缩写词,两版都不带缩写点。字符串版次(`Rev. ed`)用户原样,不经序数词、不受版本感知影响。])

#let eb = bytes("@book{en-multi, author={Smith J}, title={Book}, edition={5}, location={New York}, publisher={Saunders}, date={1974}, langid={english}}
@book{en, edition={5}, langid={english}}
@book{fr, edition={2}, langid={french}}
@book{ru, edition={2}, langid={russian}}
@book{zh, edition={3}, langid={chinese}}")

#case("2025：单块西文缩写无点（en/fr/ru）+ 多块段间句点抹平", gb7714.with(version: 2025), bib: eb, cites: (<en-multi>, <en>, <fr>, <ru>, <zh>), full: true)
#case("2015：单块西文缩写带点（en/fr/ru）+ 多块与 2025 一致", gb7714.with(version: 2015), bib: eb, cites: (<en-multi>, <en>, <fr>, <ru>, <zh>), full: true)
