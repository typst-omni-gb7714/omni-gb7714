//! param: emphasis
//! values: 规格 (italic/bold/prefix/suffix)、语言分设 (zh/rest)、各槽 titles/journaltitles/booktitles/series/creator/volume/issue/date
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "emphasis", controls: "按*渲染位置*(槽)施加斜体 / 加粗 / 包裹符，可按条目语言分设。替代旧 italic-book-title / italic-journal / bold-journal-volume 三布尔。",
  expect: [槽 = 渲染位置：`titles`(专著级题名，含副题名)/ `journaltitles`(刊名)/ `booktitles`(母体题名)/
    `series` / `creator`(主责任者)/ `volume` / `issue` / `date`。值 = 规格 `(italic:,bold:,prefix:,suffix:)`(键可叠加)|
    语言分设 `(zh:,rest:)`(atom = none | 规格)| `none`。消歧靠键(规格键 vs 语言键)。
    *角色分派*：析出篇名 / article 篇名*不*装饰，容器 `journaltitles` / `booktitles` 才装饰(见 titles 档：只有专著 bm 的题名进《》，析出 ic 的析出篇名不进、母体才进)。
    ⚠️ *italic / bold 的字形差异不进文本 golden*(pdftotext 抽不出，见「字形 / 几何开关」契约)；*prefix / suffix 包裹符进文本*，本表主要靠《》验证管道。])
#let cs = (<bm-zh>, <aj-en>, <aj-zh>, <ic-zh>)
#case("默认 (:)（都不装饰）", gb7714.with(), cites: cs, full: false)
#case("titles 书名号《》（只专著题名进，析出篇名不进）", gb7714.with(emphasis: (titles: (prefix: "《", suffix: "》"))), cites: cs, full: false)
#case("titles 语言分设：zh《》/ rest 斜体", gb7714.with(emphasis: (titles: (zh: (prefix: "《", suffix: "》"), rest: (italic: true)))), cites: cs, full: false)
#case("journaltitles 书名号（刊名）", gb7714.with(emphasis: (journaltitles: (prefix: "《", suffix: "》"))), cites: cs, full: false)
#case("booktitles 书名号（析出母体）", gb7714.with(emphasis: (booktitles: (prefix: "《", suffix: "》"))), cites: cs, full: false)
#case("volume 加粗（字形不进文本）", gb7714.with(emphasis: (volume: (bold: true))), cites: cs, full: false)
#case("creator 加粗（字形不进文本）", gb7714.with(emphasis: (creator: (bold: true))), cites: cs, full: false)
#case("titles italic（字形不进文本，验不崩）", gb7714.with(emphasis: (titles: (italic: true))), cites: cs, full: false)
#case("titles 叠加 italic + 书名号", gb7714.with(emphasis: (titles: (italic: true, prefix: "《", suffix: "》"))), cites: cs, full: false)
