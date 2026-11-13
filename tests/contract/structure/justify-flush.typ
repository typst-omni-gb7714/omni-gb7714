// 两端对齐的几何不变量：条目行必须顶到内容区右缘。
//
// 条目里放一长串挤不下的数字（收录号 / 课题编号这类，真实语料常见）：这一行只能断在数字前，
// 断点前留下的空当要由两端对齐吃掉。文献表编号列成表时若把内容列宽定成 `auto`，列宽会取
// 「最长那一行的自然宽度」——正好被这个早断点压窄，段落于是在窄列里对齐，版面上那一行就没顶
// 到右缘（实测短约一个汉字）。内容列用 `1fr` 才与原生一致。
//
// 用纯 ASCII 与拉丁标点，不依赖任何中日韩字体；页宽写死，断点位置对任何字体都成立
// （数字串长到任何一行都放不下）。
#import "/lib.typ": gb7714, bibliography
#set page(width: 300pt, height: auto, margin: 20pt)   // 内容区 260pt，右缘 = 280pt
#set text(size: 9pt, lang: "en")
#set par(justify: true)
#show: gb7714.with(show-annotation: true)
#bibliography(
  bytes(
    "@article{jf, author={Smith, John and Doe, Jane}, title={A study of things and other things}, "
      + "journal={Journal of Examples}, year={2021}, volume={57}, number={1}, pages={1--5}, "
      + "annote={Accession 90211234567890123456789012345 end}, langid={english}}",
  ),
  title: none,
  full: true,
)
