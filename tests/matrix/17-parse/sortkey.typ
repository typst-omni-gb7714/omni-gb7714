//! param: 排序代理字段（sortkey · key · \noopsort）
//! values: 多音字 / 手工排序值
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "排序代理", controls: "让某条按指定的值排，而不是按渲染出来的责任者。",
  expect: [排序取值链：`sortkey` → `key` → `author` → `editor` → `title`（GB §3.14 的那个 name）。
    多音字、机构简称、以及不想按字面排的条目，用 `sortkey` / `key` 域手工指定排序值。
    `\noopsort{zzz}` 是 bst 时代的排序代理写法——它是个*未定义 LaTeX 命令*，
    要 `latex-strict-command: false` 才编得过（宽松档丢弃命令、保留其后内容）。
    排序只在著者-出版年制（或显式给了 `bib-sort-by`）下才发生。])
#let mix = bytes(read("/tests/_fixture/parse.bib") + read("/tests/_fixture/latex.bib"))
#case("sortkey / key 指定排序值（著者-出版年制）", gb7714.with(style: "author-date"), bib: mix, full: true,
  bib-args: (keys: [@pa-sortkey@pa-key@pa-namea]))
#case("\\noopsort 排序代理（需 latex-strict-command: false）", gb7714.with(style: "author-date", latex-strict-command: false, latex-strict-char: false),
  bib: mix, full: true, bib-args: (keys: [@tex-noopsort@pa-sortkey@pa-key]))
#case("顺序编码制（排序代理不参与，按引用 / 文件序）", gb7714.with(latex-strict-command: false, latex-strict-char: false),
  bib: mix, full: true, bib-args: (keys: [@pa-sortkey@pa-key@tex-noopsort]))
