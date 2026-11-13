//! param: EDTF 结构化日期（date 字段的不确定标记 / 区间 / 开区间 / BCE）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "EDTF 日期", controls: "`date` 字段的 EDTF 写法（不确定标记 `~ ? %`、区间 `a/b`、开区间 `a/..`、公元前负年）如何渲染，以及 `date` 与 `year` 两个字段的分工。",
  expect: [`date` 字段由 citegeist（biblatex crate）*结构化解析*成 `parsed_dates`（`kind` at/between/after/before、
    `approximate` / `uncertain` 布尔、`start` / `end` 的年月日、BCE 负年），出版年取值优先用它；只有 `year`
    字段时 crate *不*解析 EDTF（只取数字、丢 `~ ? %`），回退旧的字符串 `edtf-year`。分工依据：`date` 是
    biblatex 的 EDTF 日期字段、`year` 是遗留数字字段。

    - *不确定标记*：`date` 带 `~`（约）/ `?`（不确定）/ `%`（两者）→ `approximate` / `uncertain` 为真 →
      出版年置「[]」内（§7.5.4.3「估计的出版年应置于「[]」内」）。`date={2024-03~}` 出 `[2024]`——旧实现
      `split("-").first()` 会把 `~` 连同 `03~` 一起切掉、丢失 approximate，现由结构化布尔修复。
    - *`year` 字段*：`year={2019~}`（用户手写、或 `date-fallback` 注入的 `2024~`）crate 不解析，走旧
      `edtf-year` 抠尾字符 → `[2019]`。两条路各管各。
    - *连续出版物年份区间*（§8.4.2「年,卷(期)—年,卷(期)」）：`date={1957/1990}` → `kind:"between"`，起讫
      `1957,1(1)—1990`；`date={1957/..}` → `kind:"after"`（开放区间，至今仍在出版）→ `1957,1(1)—`。EDTF 的
      `..` 现由结构化正确处理——旧 `split("/")` 会得到 `end=".."` 乱码。
    - *年 0 端点归一*（回归 #10）：`date={1984/0000}`（或 CSL JSON 末段 `[0]`）被 crate 解析成 `between` +
      `end.year=0`。年 0 不是真实出版年，`parsed()` 单一入口把零端点当缺失、`kind` 降级为 `after`，故正确出
      开区间 `1984—`，不再吐出 `1984—0`。
    - *公元前（BCE）*：`date={-0031}` → 负年 `-31`。GB 无 BCE 细则（§7.5.4.1 只规定「公元纪年、阿拉伯数字」，
      其他纪年如民国/康熙置「()」内、靠 .bib 数据给出，通篇无公元前示例）；326 个社区 GB CSL 里 325 个不处理、
      李泽平 bst 不处理、只有 biblatex 出 `−0031`（保留 EDTF 4 位 + Unicode 减号）。omni 出 `-31`（阿拉伯数字
      + 负号）符合「公元纪年、阿拉伯数字」精神，不为极罕见的 BCE 加 4 位补零特殊逻辑。])
#let eb = bytes("@book{a, author={甲}, title={年约}, address={北京}, publisher={某社}, date={2024~}, langid={chinese}}
@book{b, author={乙}, title={年月约·修 approximate}, address={北京}, publisher={某社}, date={2024-03~}, langid={chinese}}
@book{y, author={原}, title={year 字段约·走旧路}, address={北京}, publisher={某社}, year={2019~}, langid={chinese}}
@book{bce, author={西塞罗}, title={公元前著作}, address={罗马}, publisher={某社}, date={-0031}, langid={chinese}}
@periodical{r1, title={起讫区间}, date={1957/1990}, volume={1}, number={1}, address={北京}, publisher={某社}, langid={chinese}}
@periodical{r2, title={开区间至今}, date={1957/..}, volume={1}, number={1}, address={北京}, publisher={某社}, langid={chinese}}
@periodical{r3, title={年0终点归一}, date={1984/0000}, volume={1}, number={1}, address={北京}, publisher={某社}, langid={chinese}}")
#case("出版年 EDTF：date 字段结构化（约标记 / BCE）· year 字段字符串", gb7714.with(), bib: eb, cites: (<a>, <b>, <y>, <bce>), full: false)
#case("连续出版物年份区间：起讫 between / 开区间 after / 年 0 端点归一（回归 #10）", gb7714.with(), bib: eb, cites: (<r1>, <r2>, <r3>), full: false)
