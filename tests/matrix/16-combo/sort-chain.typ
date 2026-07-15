//! combo: bib-sort-by × entry-lang-order × bib-sort-zh-by × sort-use-prefix × creator-idem × sort-keys
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "联动：排序链", controls: "文献表的次序由六个参数叠出来。",
  expect: [叠加次序（自外向内）：
    `sort-keys` 点名的条目*置顶* → *文种*分组（`entry-lang-order`，GB §9.3.2「先按文种集中」，
    是隐式的最高优先级键、不可省）→ `bib-sort-by` 的键数组 → 中文按 `bib-sort-zh-by`（拼音 / 笔画）、
    西文按 `sort-use-prefix` 决定前缀算不算 → 排完之后 `creator-idem` 把*紧邻*的同责任者替换成长横线。
    顺序编码制的缺省是 `none`（按引用先后，GB §9.2.1.1），排序参数不参与；显式给键数组则生效。])
#let mixed = bytes(read("/tests/_fixture/lang.bib") + read("/tests/_fixture/edge.bib"))
#let one(name, cfg) = case(name, cfg, bib: mixed, full: true)
#one("顺序编码制（缺省：不排序，按引用 / 文件序）", gb7714.with())
#one("著者-出版年制（缺省：文种 → name → date → title）", gb7714.with(style: "author-date"))
#one("+ entry-lang-order: (en, zh, ..)（文种次序翻过来）", gb7714.with(style: "author-date", entry-lang-order: ("en", "zh", "ja", "ko", "fr", "ru", "de")))
#one("+ bib-sort-zh-by: bihua（中文组内改笔画序）", gb7714.with(style: "author-date", bib-sort-zh-by: "bihua"))
#one("+ bib-sort-by: ((date: descending), name)", gb7714.with(style: "author-date", bib-sort-by: ((date: "descending"), "name")))
#one("+ sort-use-prefix: true（西文前缀计入）", gb7714.with(style: "author-date", sort-use-prefix: true))
#one("+ creator-idem: 「———」（排完之后才替换）", gb7714.with(style: "author-date", creator-idem: "———"))
#one("+ sort-keys 置顶（压在文种分组之上）", gb7714.with(style: "author-date", sort-keys: [@nm-same-b@lg-en]))
#one("顺序编码制 + 显式 bib-sort-by: (name,)（显式给就生效）", gb7714.with(bib-sort-by: ("name",)))
#one("全叠：sort-keys + 文种序 + 笔画 + 降序 + 前缀 + idem", gb7714.with(style: "author-date",
  sort-keys: [@lg-en], entry-lang-order: ("en", "zh", "ja", "ko", "fr", "ru", "de"),
  bib-sort-zh-by: "bihua", bib-sort-by: ("name", (date: "descending")), sort-use-prefix: true, creator-idem: "———"))
