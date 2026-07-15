//! param: 字段别名归一（journal ↔ journaltitle · address ↔ location）
//! values: 只写别名 / 只写真名 / 两个都写
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "字段别名", controls: "两个同义字段名，谁胜。",
  expect: [`journal` 是 `journaltitle` 的传统别名，`address` 是 `location` 的传统别名。
    只写别名 → 照常著录；两个都写 → *真名静默胜*（不报错、不合并）。
    ⚠️ *底层 crate 的 crossref 继承表只认真名 `location`、不认别名 `address`*——
    所以 `@proceedings{.., address={北京}}` 被 `@inproceedings{.., crossref=..}` 继承时会丢出版地。
    载入期把 `address` 归一成 `location` 正是为了堵这个洞（见 `crossref-xdata.typ`）。
    模板里 `address` 与 `location` 两个 token *都*读归一后的值
    （⚠️ `location` token 目前一写就 panic，见 BUGS #5）。])
#case("四条别名条目（2025 · 顺序编码制）", gb7714.with(), bib: PARSE, full: true,
  bib-args: (keys: [@pa-journal-alias@pa-journal-both@pa-location-alias@pa-location-both]))
#case("同上 · 著者-出版年制", gb7714.with(style: "author-date"), bib: PARSE, full: true,
  bib-args: (keys: [@pa-journal-alias@pa-journal-both@pa-location-alias@pa-location-both]))
#case("模板里用 address token 取归一后的值", gb7714.with(custom-drivers: (book: "author . title . {address=} address")),
  bib: PARSE, full: true, bib-args: (keys: [@pa-location-alias@pa-location-both]))
#case("short-journal 与别名并存（无 shortjournal → 回落全称）", gb7714.with(short-journal: true),
  bib: PARSE, full: true, bib-args: (keys: [@pa-journal-alias@pa-journal-both]))
