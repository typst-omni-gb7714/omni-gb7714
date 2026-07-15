//! param: url-break-hyphen
//! values: false, true
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "url-break-hyphen", controls: "URL 断点落在行末时是否显示连字符（总开关）。",
  expect: [`false`（缺省）：断点用零宽空格（U+200B）——任意位置可断行，行末*不显*连字符，
    URL 复制干净、不会把连字符误读成 URL 的一部分。
    `true`：断点用软连字符（U+00AD），落行末才显 `-`，便于识别续行；
    URL 自带的真实 `-` 不叠加、不会出现 `--`。覆盖范围由 `url-break-hyphen-at-delimiters` 决定。
    ⚠️ 软连字符只在*实际断行处*显形——本用例把 URL 做得足够长以逼出断行。])
#let long = bytes("@online{u-h, author={甲}, title={长 URL 逼出断行}, url={https://example.com/averylongpathsegmentwithoutanyseparatorsatallxyz/anotherverylongsegmenthere/final}, urldate={2024-01-01}, year={2023}, langid={chinese}}")
#case("false（缺省，零宽空格）", gb7714.with(), bib: long, full: true)
#case("true（软连字符）", gb7714.with(url-break-hyphen: true), bib: long, full: true)
#case("true + url-break-every: none（只在天然分隔符处断，且显 -）", gb7714.with(url-break-hyphen: true, url-break-every: none), bib: long, full: true)
