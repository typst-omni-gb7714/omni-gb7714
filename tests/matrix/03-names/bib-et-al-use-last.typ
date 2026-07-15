//! param: bib-et-al-use-last
//! values: 0, 1, 2, 语言档
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "bib-et-al-use-last", controls: "截断后，在省略号之后再保留*原名单末尾* N 位责任者。",
  expect: [缺省 `0`（关）——GB 没有这条规定，是方言功能。开启后责任者串出「前 use-first 位 +
    省略号 + 末 N 位」（`A，B，C，… Z`），并且**不再出「等 / et al」**：省略号与截断词互斥
    （citeproc-lua 实测同判）。

    语料每条 8 位责任者。四档配置都用 `bib-et-al-min: 8`：
    - `0`（缺省）：8 位达到阈值，出「前 3 位 + 等」。
    - `1`：*心理学报 / 心理科学进展*的配置（```xml et-al-min="8" et-al-use-first="6" et-al-use-last="true"```
      —— CSL 的布尔 `true` 就是本项的 `1`）。出前 6 位 + 省略号 + 末 1 位，省掉第 7 位。
      与 citeproc-lua 的对拍见 `tests/parity/et-al-use-last/`。
    - `2`：留末 2 位。**CSL 表达不了这一档**（它的 `et-al-use-last` 是布尔，只能留末 1 位）；
      本项收整数正是为了与 `et-al-use-first` 值域一致。
    - *语言档*：三档取值与 `bib-et-al-min` 同规，`(zh: 1, rest: 0)` 让中文条目用省略号、西文条目
      仍出 `et al`。

    `and others` 那条恒不走 use-last：.bib 作者写到一半以 `and others` 收尾，名单本身就是不完整的，
    取不出真正的「最后一位」——省略号会骗人，所以仍出截断词。

    *前置条件* `use-first + use-last <= min - 1`（违反即报错，见 `tests/contract/panic/`）：责任者数
    恰好达到 `min` 时，「前 use-first 位 + 末 use-last 位」若不比 `min` 小，一位都没省掉。

    省略号字形走 `custom-punct` 的 `…` 键（默认单个 `…`，与 citeproc 实测一致）。])
#let cs = (<el-zh>, <el-en>, <el-others>)
#case("0（缺省，关）", gb7714.with(bib-et-al-min: 8), bib: ETAL-LAST, cites: cs, full: false)
#case("1（心理学报：8 / 6 / 1）", gb7714.with(bib-et-al-min: 8, bib-et-al-use-first: 6, bib-et-al-use-last: 1), bib: ETAL-LAST, cites: cs, full: false)
#case("2（留末 2 位，CSL 表达不了）", gb7714.with(bib-et-al-min: 8, bib-et-al-use-first: 5, bib-et-al-use-last: 2), bib: ETAL-LAST, cites: cs, full: false)
#case("语言档 (zh: 1, rest: 0)：中文用省略号、西文仍出 et al",
  gb7714.with(bib-et-al-min: 8, bib-et-al-use-first: 6, bib-et-al-use-last: (zh: 1, rest: 0)),
  bib: ETAL-LAST, cites: cs, full: false)
