# 矩阵测试暴露的问题

重构测试套件时，穷举参数取值暴露出来的真实缺陷。

**已修**：#1 / #3 / #4 / #5 / #6 / #7 / #8 / #9 / #12 / #13 / #14。
**待裁决**：#2 / #10 / #11——它们不是纯 bug，而是「行为对不对」或「加不加能力」先要定下来。

---

## ✅ #1　`cite-name-date-separator` 收多语言字典时直接 panic〔已修〕

**现象**

```typst
#show: gb7714.with(style: "author-date", cite-name-date-separator: (zh: "，", rest: ", "))
→ error: type dictionary has no method `starts-with`   (src/punct/built-in.typ:186)
```

doc 明写它收字典，同族的 `bib-name-date-separator` 收同一个字典*正常工作*。

**根因**　cite 侧（`_author-date-cite-label`）自带一套感知逻辑（裸逗号 → `name-separator`），
所以它不走 bib 侧的 `punct.resolve-separator`，而是直接调只认字符串的 `punct.unwrap-separator`。
**字典档从来没被解开过**——转发缺口。

**已修**　感知逻辑之前先补一步「字典按*条目语言*挑值」（`punct.pick-separator-by-lang`，
兜底档 `auto` = 本参数的预设值），挑出来的值再走原有的三态。与 bib 侧同规、两侧对称。

**矩阵**　`02-cite/cite-name-date-separator.typ` 三个字典取值已启用
（按语言挑值 / `rest` 兜底 / 没点到的语言退回 `auto` 派生值 / verbatim 值）。

---

## ✅ #2　消歧梯子的兜底档缺位：`date` 按「完整名册」分组，不按「行内渲染出的标签」〔已修〕

**现象**（`05-sort/disambiguate.typ`）

语料两条：`Brown, Wang, Li (2021)` 与 `Brown, Chen, Li (2021)`。首责任者同、合作者不同。

```typst
#show: gb7714.with(style: "author-date", cite-et-al-min: 2,
                   disambiguate: (names: false, given-name: true, date: true))
→ 正文：(Brown et al., 2021, 2021)      ← 两条渲染成同一个标签，读者无法分辨
→ 文献表：Brown B，Chen C，Li L，2021.  /  Brown B，Wang W，Li L，2021.   ← 也没有后缀
```

`date: true` 已经显式打开，却*没有*落 `2021a` / `2021b`。

**根因**　`date` 机制的分组判据是*完整名册*（roster）：两条名册不同 → 判为「不是同一批人」→
不进同一消歧组。而它们**渲染出来的标签是同一个**（`et al.` 把差异截掉了）。

官方 CSL 的梯子是：展开名单 → 补名 → *剩下仍然撞车的*一律落年份后缀。
兜底档的判据得是「渲染后的标签是否相同」，否则前面两档一旦关掉（或无力分开），标注就永久撞车。

我们自己的 doc 写的是「剩下的（**真同人同年**）落年份后缀」——「真同人」这个判据本身就是分歧点。

**待裁决**　是否把 `date` 的分组判据改成「行内渲染出的标签相同」。
改之前应先用真 citeproc（pandoc / citeproc-lua + 官方 GB 著者-出版年制 CSL）实测
`disambiguate-add-names="false"` + `disambiguate-add-year-suffix="true"` 的输出，拿到权威再动。

**矩阵**　`05-sort/disambiguate.typ` 里两个取值正印着这个现象，用例保留。

**核销**（2026-07）　早已修复：`date` 档的分组键现在就是*渲染出的标签*
（`author-date.typ` 的 `disambiguation-key = _escalated-label(escalations, key)`，标签 = `author-short` 含
截断词 + 年 + ①②的升级）。逐档隔离实测：`(names: false, given-name: false, date: true)` 下
`Brown/Wang/Li` 与 `Brown/Chen/Li` 都截成 `Brown et al., 2021`，正文与文献表*一致*落 `2021a` / `2021b`。
`parity/disambiguate/`（citeproc-lua 对拍，`disambiguate-add-names="false"` + `add-year-suffix="true"`）
持续把关，10 条语料逐条一致。

---

## ✅ #3　`pid-priority` 的 doc 与 `show-pid.max` 的 doc 互相打架〔已修〕

**实测**（`07-pid-url/pid-priority.typ`，语料 `pid-all`：`doi` + `cstr` + `url = https://doi.org/10.1234/example`）

```typst
show-pid: (rest: true, doi: true, max: 1), pid-priority: ("cstr", "doi")
→ [1] 未. …[J/OL]. 学报，2023，1：1-10. https://doi.org/10.1234/example.
                                        ↑ 一个标识符都没著录
```

**当前行为**：`dedup-url-pid` 认定 DOI 已被 URL 承载 → DOI 被抑制，但*仍计入 `max` 配额* →
配额用尽 → 明明被 `pid-priority` 点了名的 CSTR 也不出。

**两处 doc 说的不是一回事**：

- `show-pid` 的 `max` 键：「`dedup-url-pid` 开启时 URL 已承载的标识符**计入配额**（它已著录于获取和访问
  路径中，不重复著录）」 ← 与实测一致；
- `pid-priority`：「`max: 1` 时「第一个」= 本优先级下首个**有值**的标识符（**URL 去重先行，计数干净**）」
  ← 「去重先行、计数干净」读起来正是「被 URL 承载的不占配额」，与实测相反。

**已修（2026-07-15，`94cec30`）**　**两条 doc 都错，而且行为也错**——查了国标原文才发现，`max` 那句
「GB/T 7714—2025 只须著录一个标识符」是**杜撰的**：§7.9 全文只有 7.9.1（路径含 PID 时可不重复著录）
与 7.9.2（不含时可按原文*如实著录*），**没有数量上限**。

真正的病是 `carried` **双重计数**：`effective()` 里已经把 DOI 压下了（7.9.1 兑现），`access()` 又拿
同一个事实扣一次 `max` 配额，把*别的* PID 也顶掉。删掉 `carried` 后 `pid-priority` 点名的 CSTR 立刻
出来了。而 `pid-priority` 那句「URL 去重先行，计数干净」**本来就是对的**——是实现没跟上文档。

连带刨出的四个 bug、三个隐形层（CSTR/DOI 互斥、carried、eprint 平台特判）与整套 PID 语义重整见提交
`94cec30`。

**矩阵**　`07-pid-url/pid-priority.typ` 与 `dedup-url-pid.typ` 都印着这个现象，用例保留。

---

## ✅ #4　脚注渲染路径的 `base` 可以为负 → 用不相关的越界错误盖住真正的报错〔已修〕

**现象**　同一文档里别处的 `gb7714(..)` 因配置非法而 panic 时（例如 `custom-terms` 写错子键），
脚注制的用例会先抛出：

```
error: array index out of bounds (index: -1, len: 0)
    src/citation/footnote.typ:239   let all = anchors-all.slice(0, cut)
```

真正的报错（`custom-terms 'footnote-number' 的槽位字典只接受 prefix / suffix / supplement-separator`）
被它盖住，用户看到的是一条与病因毫无关系的越界错误。

**根因**　`base = anchors-all.len() - group-size`。正常情形下 `anchors-all` 至少含本组自己的锚点，
`base ≥ 0`；配置 panic 时状态没写进去、`anchors-all` 为空，`base = -1`，`slice(0, -1)` 越界。

**已修**　`base` 加 `calc.max(0, ..)` 护栏。它不改任何行为（`base < 0` 本来就只在别处已经出错时才出现），
只是让真正的报错浮到最前面。这是*诊断质量*的修，不是功能修。

---

## ✅ #5　`location` token 手册里写着能用、实际 panic —— 白名单漏登记〔已修〕

**现象**

```typst
custom-drivers: (book: "address {／} location")
→ error: 模板里的 token `location` 既不是内置标识，也不在 custom-fields / custom-terms 字典里。
```

手册的 token 速查表明写「`address` / `location` —— 出版地（**自动归一化两个别名**）」。

**根因**　`src/fields/built-in.typ`：`resolve-built-in-token` 里*有* `location` 的分支
（`if name == "address" or name == "location"`），但白名单 `built-in-token-names` **只登记了 `address`**。
模板引擎先查白名单再派发，那条分支**永远走不到**。

文件里本来就有一行注释写着这条不变量：「在 `resolve-built-in-token` 里增删 `if name == ...` 分支时，
**必须同步更新这份集合**」——注释靠人记，人没记住。

**已修**　白名单补 `"location"`（现 59 个 token），并新增 `tests/contract/token-whitelist.sh`：
拿分支名与白名单**双向比对**，机器来管这条不变量。

---

## ✅ #6　组前导前缀按渲染期判定 → 组内首 token 一空，紧跟的分隔符就冒充前缀发出去〔已修〕

**现象**（语料：`@article` 有 `pages` / `volume`，*无* `edition`）

```
模板 author . title . ?<edition , pages>
实际 Brown B. T. ，100-115.      ← 打头一个悬空的全角逗号
应当 Brown B. T. 100-115.
```

**根因**　「**组前导前缀**」（手册：「组前导前缀恒发，它绑定的是整组非空，不会被空的首 token 吞掉」）
是个**词法**概念——源码里位于*首个数据 token 之前*的那段字面量。
实现却按**渲染期**判定（「首个*非空内容*之前的字面量」）：`active-group` 的 `preamble` 阶段遇到空 token
就 `continue`（不推进 phase、不丢 buffer），于是空的首 token 后面那个*分隔符*落进了 buffer，
被当成前缀发了出去。

**已修**　显式区分两个 buffer：`prefix`（首个数据 token 之前，词法定型，`active-group` 下恒发）与
`buffer`（数据 token 之间的分隔符）。首个数据 token 一到（空的也算）前缀即定型。

首个内容之前的其余 buffer 分情况：`preamble`（前面没有空 token）→ 本来就是前缀，照发；
`midstream`（前面有空 token）→ 是分隔符，丢掉。

**当时没动的那一半（「左边丢、右边收敛」）后来证明也是错的**——见 #12。我读了代码注释里那句
「有意设计」就信了，没去跟内置对拍。教训：*注释不是权威，内置渲染才是*。

---

## ✅ #7　软空格切断了括号配对 → `[ mark ]` 的右括号残留〔已修〕

**现象**　模板 `author . title [ mark ] . publisher` 配 `show-mark: false`：

```
[1] 甲. 题名]. 社.
        ↑ 右方括号孤零零留着
```

**不是 `mark` 专属**：这是通用的括号配对机制（`_BRACKET-PAIRS` 那 13 对），对任何 token 都成立。
坏的只是「配对回看时只看 buffer 的最后一项」——中间夹一个软空格，最后一项就是软空格、不是 `[`，配对落空。
所以 `[mark]`（紧贴）、`{[}mark{]}`（verbatim）、`<[mark]>`（组）都好好的，唯独 `[ mark ]` 漏。

**已修 → 后来整个删掉了**。先是让配对跨过软空格；随即发现**这套窥孔配对根本不该存在**：
它只在「单个 token 紧贴一对括号」时碰巧对，括号里一多个 token 就吐破碎输出
（`( number , pages )` 缺 number 时得 `，100-115）`），而条件组的路径*根本用不着它*
——`<[mark/medium]>` 的正确性来自「组前导前缀恒发」与「组尾字面量作后缀」两条规则。

**终态**：括号在模板里没有任何特殊地位，就是普通字面量。要它跟内容同进同退，把它和内容*一起*
放进条件组（`<[mark]>` / `<（number）>`）——任意多 token、任意嵌套都成立。忘了包组，token 出不来时
那个 `）` 会明晃晃留在输出里：那是模板作者的事，引擎不替他兜底。手册已写明。

---

## ✅ #8　成列档（`number-placement: "column"`）下两个段落缩进量被静默忽略〔已修〕

**症状**　缺省的 `"column"` 档下，`entry-hanging-indent` 与 `entry-first-line-indent` **两个都
静默无效**（四种取值渲出来一模一样），而它们在 `"margin"` / `"inline"` / 无编号三档都生效。

**根因**　成列档的实现是 grid（编号一列、正文一列），内容格里是个光段落——
`par(hanging-indent:, first-line-indent:)` 根本没接上去。代码注释写的是「段落缩进的两个量在此
无处安放（CSL 与原生皆如此）」。**那句话是错的**：正文格本身就是一个段落，两个量就是它的 `par` 量。

**静默忽略一个用户显式设的配置项，是本仓明令禁止的**——`config-sync` 那道闸的存在理由，
一字不差就是这个：「漏转发一个参数，引擎会静默用自己的默认值、不报错——这道闸把它变成硬失败」。

**已修**　grid 内容格接上 `par(hanging-indent:, first-line-indent:)`（普通条目与 `@set` 两条路径都接）。
缺省 `auto` 在顺序编码制下派生为 `0pt`，是空操作，默认渲染一处不变。

**顺带纠正两处自相矛盾的注释**：一处写「两个量正交、同时生效（与原生 `par` 同义）」，
另一处写「`first-line-indent` 与悬挂互斥（doc 明写），这里不接」——后者是错的
（Typst 的 `par` 里首行在 `first-line-indent`、余行在 `hanging-indent`，各管各），
而且它正是 `@set` 骨架那条分支不接首行缩进的借口。

**中途试过、又否掉的一版**（记下来，免得再走一遍）：想把 `entry-hanging-indent` 改成
「余行距*版心左缘*的绝对距离，四档同义」，`auto` 按版式派生（`"column"` → `number-width + gutter`），
grid 里换算成 `值 − (编号列宽 + gutter)`。看着更「一致」，**实测否掉**：

- 编号列宽随条目数变（`[9]` → `[120]` 宽出约 1.4em）。用户写死的绝对值随时可能*小于*编号列宽
  → 余行倒插到首行文字的左边，**加减几条参考文献就能把版式弄崩**（实测：120 条时 `3em` 的余行
  落在首行文字左边 1em 处）。
- 孪生参数 `entry-first-line-indent` 只能是段落量（原生 `par` 就这一种）。悬挂用绝对、首行用相对，
  两个兄弟参数就活在两个坐标系里——最坏的结果。
- 「余行顶格」本来就不该由它背：那是「编号不占一列」，即 `number-placement: "inline"`。
  **`number-placement` 管编号占不占列，`entry-hanging-indent` 管正文段落悬挂多少，两个参数各管一件事。**

**doc 改**　`entry-hanging-indent` 的「`auto`：顺序编码制 = `number-width + number-gutter`」是错的
——`auto` 在顺序编码制下就是 `0pt`，那个「余行贴正文列」的 flush 是*编号列*给的，与本量无关。

---

## ✅ #9　内置 `@periodical` 驱动的年卷期区间：孤儿逗号 + 无依托的破折号〔已修〕

修 format-twins 那道闸时挖出来的（把「只有必备字段」的瘦条目加进语料之后）。

**修之前**（内置渲染）

```
volume={9}，无 date    → 编. 刊名[J]. ，9—. 地：社.     ← 打头一个孤儿逗号
只有 title             → 刊名[J]. —.                     ← 一个无依托的破折号
```

**根因**（`src/drivers/built-in.typ` 的 `serial`）两处无条件拼接：

- `if start-volume != none { s += p("comma") + start-volume }`——年份为空时那个逗号照拼；
- `year-volume-combined += "—"`——起始段一项数据都没有时，区间号照补。

国标 8.4 的格式是「年, 卷(期)**—**年, 卷(期)」：那个 `—` 是**区间号**，标的是「起讫」。
起始段空着的时候它没有可标的东西，不该单独出现。

**已修**　年卷期段改由一个 `_year-volume-number(year, volume, number)` 拼装——*前面没有内容
就不发前导分隔符*；起始段为空则整段不出（`—` 也不出）。

**连带**　修之前，`custom-drivers` 的模板要逐字复现内置（format-twins 盯着），
手册的 `@periodical` 串被迫写成 `<title => …>`（**恒真守卫**）才能发出那个无条件的 `—`
——手册在教用户一个 hack。修好之后回到干净形态：`?<date，volume<（number）>{—}>`。

---

## ⏳ #10　模板表达不了年卷期的**区间解析**——真区间的 `@periodical` 复现不了

`@periodical` 的 `date=1957/1990`、`volume=1-15`、`number=1-4` 是**写在一个字段里的起讫**。
内置 `serial` 驱动把它们*拆成两段*再用 `—` 连起来：

```
内置   1957，1（1）—1990，15（4）.   地：社，1957—1990.
模板   1957/1990，1-15（1-4）—.      地：社，1957/1990—.     ← token 取的是字段原值
```

模板的 `date` / `volume` / `number` token 拿到的是**字段原值**，拆不开。这不是 bug，是**表达力缺口**：
区间解析是内部逻辑，没有 token 暴露出来。

format-twins 的语料因此只有「字段齐全」与「只有必备字段」两条 periodical，**不含真区间**——
这是个已知的覆盖洞（旧闸干脆把 periodical 整类排除掉，理由同此）。

**提案**：像 `imprint-block` / `title-block` / `series-block` 那样，把年卷期区间做成一个 **block token**
（暂名待定），模板写 `author. title<mark-medium>. <该 token>. address：…`。
block token 存在的意义正是「把有内部逻辑的一整段打包」，这一段完全符合。
做完之后，twins 的语料就能补上真区间那条，把这个洞堵死。

**待裁决**：加不加这个 token（新增公共 token = API 变更）。

---

## ⏳ #11　制度轴：模板既不能按制度分设，也不能在内部按制度分支

**第 1 层：整份按制度换模板——能做。** `style` 与 `custom-drivers` 都是用户手里的参数，
逐表也各有一份（`bibliography(style: "author-date", custom-drivers: (…), label: "ay")`）。不需要新 API。

**第 2 层：同一份模板*内部*按制度分支——做不到。** 模板的 `opts` 里只有 `skip-date` /
`skip-creator`，**没有制度这个词**；守卫的谓词能问 `mark` / `medium` / `entry-type` / bib 字段，
问不了制度。于是「两制只差一小段」时只能整份复制一遍模板。

**提案**：守卫加一个包算量谓词 `<bib-style=author-date => …>` / `<bib-style=numeric => …>`。
名字必带连字符（既有规则：*带连字符的是包算出来的量，不带连字符的一律是 bib 字段*）。
零新结构——`custom-drivers` 的形状不变，键还是类型、值还是串。

**第 3 层：著者-出版年制下责任者与年份的*位置*是引擎写死的——模板动不了。**
AY 下引擎把「责任者，年份」提到最前，再给模板传 `skip-creator` / `skip-date`，
模板里的 `author` 与 `date` token 恒返回空。所以没法在 AY 模板里把年份放到别处
（`责任者. 题名（2020）.`）。要动它得把「责任者-年份块」也做成可放置的 token，
并让引擎在模板显式用了它时不再自动提升。
**倾向不做**——GB 的 AY 制本来就规定了这个位置，偏离它就不是 GB 了。

**待裁决**：做第 2 层吗？

---

## ✅ #12　空 token 两侧的字面量塌缩：段间句点被吃掉 / 绑定符冒充段分隔符〔已修〕

**症状**（用手册自己的内建格式串，两个面）

```
模板 title<mark-medium>. <（date）>urldate.      @online 有 urldate 无 date
实际 中国国家博物馆[EB/OL][2025-05-06].          ← 段间的「. 」整个丢了
内置 中国国家博物馆[EB/OL]. [2025-05-06].

模板 edition. address：publisher，date：pages     @book 无 address
实际 题名[M]. 2 版：社，2020.                     ← 孤儿冒号（段内绑定符冒充了段分隔符）
内置 题名[M]. 2 版. 社，2020.
```

**根因**　join 的归属模型反了。旧规则是「空 token *之前*的分隔符丢掉，让*右边*那个来收敛」，
它有两个前提，现实里都不成立：

- 右边*什么都没有*时 → 段间句点整个丢失；
- 右边是*段内绑定符*（`：` `，`）时 → 绑定符冒充段分隔符。

**已修**　改成按 **GB 自己的标点层级**塌缩：句点 `.` 分「著录项目」（段），其余（`，` `：` `//`、
括号）在项目*内部*绑定。于是——

- 空 token 两侧只要有*段间句点*，就留那个句点（它标的是两个*段*的边界，与消失的那个 token 无关）；
- 都没有句点，就留*右边*那段（它是下一个 token 的前导，如页码前的 `：`）；
- 下一段内容*自带段边界*（析出符 `//` 开头）时，前面不补任何分隔符（GB：`析出题名[M]//母体`）。

**连带修的三处**

1. `_first-character` 只认 `str`，对 `content` 一律返回 `none` → 靠「下一段首字符」判断的规则
   （软空格贴合、`//` 自带边界）**对 content 全都失灵**。补了 `punct.leading-text`（与 `trailing-text` 对称）。
   矩阵 golden 里 `Journal of Examples （12 , 4）` → `Journal of Examples（12, 4）` 就是它修好的。
2. 手册的 `@map` 串靠旧规则的错误**碰巧蒙对**：内置把标识码挂在「题名与比例尺里最后有的那个」上，
   而 `title. scale<mark-medium>` 表达不了这个条件。现在用空非空谓词真写出来：
   `title<!scale => mark-medium>. <scale => scale<mark-medium>>` —— **这是那个谓词第一次派上真用场**。
3. 裸括号不包组时的残留（`题名]. 社`）被句点塌缩顺手清掉了。但组尾（后面没有段可分隔）仍会留下
   `）` —— 所以规矩不变：**要括号跟内容同进同退就包组**。

**为什么自己的闸没红**　twins 语料里 `@online` 只有「date 与 urldate 都有」和「都没有」两条，
**「有 urldate 无 date」这个形状一次都没走到**。已补 `online-nodate` 与 `book-noloc`。
（外部报告里说的「online 卡片没被抽进闸」已不成立——上一轮已改成从手册现抽 14 张卡片。）

---

## ✅ #13　用户手写的 `[S.l.]` / `[s.n.]` 占位符被吞掉〔已修〕

**现象**（`06-display/show-sine-loco.typ` 的第三条语料 `im-placeholder`）

`.bib` 里写了 `address = {[S.l.]}, publisher = {[s.n.]}`，`show-sine-loco` 开关的**两档都不著录它们**：

```
[3] 庚. 用户手写占位符[M]. 2020.
```

这个用例的 `expect` 一直写着「两档都原样著录（用户手写的字段文本不受本参数管）」——**golden 与 expect 早就矛盾，闸没抓到**：矩阵闸只比 golden，不比 expect。

**根因**　`imprint.format` 把「像占位符的值」（`_missing-set`）当作「缺失」，先归一成 `none` 再决定补不补。
要补的类型下会用规范形式生成回来，看着没事；**不补的类型（`mark` A、D、S 与电子资源）就纯丢失**。

**已修**　`is-missing` 只用来判定「要不要替用户补」，不再吞值。§7.5.2.3 的「[出版地不详]」「[S.l.]」
本来就是标准规定的著录形式——用户写了它就是数据，原样著录（与「`custom-punct` 覆写值不受矫正」同一条契约）。
`show-sine-loco` / `show-sine-nomine` 管的只是「字段真的没有时补不补」。

---

## ✅ #14　电子资源缺出版年时，引文页码被摆到出版年的逗号位上〔已修〕

**现象**　`@online` 有出版者、无 `year`、有 `pages`（2015 档）：

```
甲. 题名[EB/OL]. 北京: 某社，12-15[2024-01-01].     ← 12-15 看着像出版年
```

**根因**　`built-in.electronic` 自己拼了一份「出版地: 出版者, 出版年」，与 `imprint.format` 平行。
它的 `year-pages` 槽在无出版年时让**页码顶上出版年的位置**，于是前面跟的是逗号而不是冒号。

**已修**　三个驱动（`electronic` / `preprint` / `serial`）的出版信息组装收编到 `imprint`，
页码一律用冒号接在出版年后（§8.2.2「出版年: 引文页码」），出版年缺位也是冒号。
语料 `im-online-nopubyear` 进 `edge.bib` 盯住这条路径。

## ⏳ #15　`et-al-subsequent-min` / `et-al-subsequent-use-first`（待办，非缺陷）

CSL 的「后续引用换一套更紧的截断阈值」：条目**之前已被引用过**时，`et-al-min` / `et-al-use-first`
换成 subsequent 版本（citeproc-node-names.lua:191-199，判据 `position_level >= Position.Subsequent`）。

语料里真正生效的**只有一个**：

| 样式 | 制式 | 首引 | 再引 |
|---|---|---|---|
| 中外法学 | `class="note"`（脚注制） | `min=4 use-first=2` | `min=2 use-first=1` |
| 澳門科技大學 | `class="in-text"` | `<name min=3 use-first=1>` | `min=3 use-first=1` ← **两套值相同，写了等于没写** |

即：首引「张三，李四，等」→ 再引「张三等」。法学引注的惯例。

**实现分歧点在制式**：

- *脚注制*：判定现成——`src/citation/footnote.typ` 已经在 query 之前所有引用锚点算 `adjacent`
  （≈ CSL 的 Ibid），「这条之前引过没有」（≈ Subsequent）就在同一份数据里。成本很低。
- *著者-出版年制*：**没有**这个判定。要加就得给每个 cite 引入「已引过的 key 集合」状态——而这是
  性能命脉（cite 的 O(N²) 专门治过，见 `cite-counter-rewrite` 记忆）。而且语料里唯一的 in-text
  用例是无效设置，**没有真实需求**。

三条路（待裁决）：
- **A** 只做脚注制。覆盖唯一真实用例，复用现成判定。代价：AY 制下该参数无效——须 panic 明示
  「只对脚注制生效」，不能静默失效。
- **B** 两制式都做。完整对齐 CSL，但要给 AY 制加 per-cite 状态，性能须先实测。
- **C** 不做。GB 无此规定，一个样式的需求。

## ⏳ #16　西文刊名未做「实词首字母大写」（真缺陷，待办）

国标要求西文刊名**每个实词首字母大写**，两版都有条款：

- 2015 §3.5-2（陈浩元解读，编辑学报 2015, 27(4)）：「刊名可采用缩写，并省略缩写点，**每个实词的
  首字母大写**」——条款有，但 2015 标准正文的示例全印成了「第 1 个词首字母大写、其余小写」。
- 2025 §2.5（陈浩元解读，编辑学报 2026, 38(2)）：把它列为**规则新点**，明说 2015 的示例「严格地说
  这是一个失误」，2025 已把**所有示例都改成每个实词首字母大写**，并把条款改成要求型（「大写字母的
  使用**应**符合信息资源本身文种的习惯用法」）。依据是《科技文体与规范》（国际科学编辑委员会）
  「每一单词的首字都大写」+ ISO 690:2021 的全部示例。

实测（`version: 2025`）：

    我们   bulletin of the geological survey of japan
    国标   Bulletin of the Geological Survey of Japan

`titles-text-case` 管的是**题名**，刊名（`journaltitle`）**没有这个轴**。

要定的：
- 参数名（`journal-text-case`？还是把 `titles-text-case` 的键扩到 `journal`？）
- 默认值：2025 起条款是要求型，默认就该开 `"title"`；但 **2015 版下要不要开**——条款有、官方示例
  却是第 1 词大写，起草人自己说那是失误。
- title-case 的停用词表（of / the / and / in…不大写）——这一项与挂账中的「title-case 深化四项」重叠。

## ✅ #17　无责任者、同年的条目全被踢出年份后缀分配〔已修〕

**现象**（著者-出版年制，三条无责任者、同年）

```
正文：(佚名, 2013, 2013, 2013)      ← 三个一模一样，读者对不回文献表
佚名，2013. 甲书[M]. 京：社.        ← 文献表也无后缀
佚名，2013. 乙书[M]. 京：社.
佚名，2013. 丙书[M]. 京：社.
```

**根因**　`245c94c` 把消歧分组键改成 `_escalated-label(...)`，键取自 `author-short`。而 `author-short`
对无责任者返回 `none`（`principal-names` 空即早退），`_escalated-label` 于是 `return none`，主循环
`if disambiguation-key == none { continue }` 把三条全踢出后缀分配。可它们*渲染出来*是同一个
`佚名, 2013`——标签相同却没参与消歧，违反「标签与著录同源」。

**权威**　citeproc-lua + 官方 GB 著者-出版年制 CSL 实测：三条无责任者同年 → `（佚名，2013a/b/c）`，
正文与文献表一致。CSL 对无责任者同年就是加后缀的。

**修法**（`author-date.typ` 的 `_escalated-label`）　`author-short` 返回 none 时不再一律 `return none`，
按渲染时的兜底同源分档：`label` 域 → 不分组（自定义标签，不走年份消歧）；`@set` → 不分组（无年份）；
真·无责任者 → 键用 `terms.anon(entry)`（按*条目语言*的「佚名 / Anon」占位词）+ 年，同语言同年归一组
落 a/b/c。键只求「同样渲染的条目落同一格」，不必逐字等于渲染文本——所以 `show-anon` / `terms-lang`
都不必透进消歧模块（单函数改动，签名不变）。

**边界**（已实测）　混合语料：中文匿名 `佚名 2013a/b`、英文匿名 `Anon 2013`（占位词不同不撞、独立
无后缀）、有作者条目与不同年条目均无后缀、`@set` 与 `label` 域不误加。
**已知小限**：`show-anon: false` + 混语言匿名同年时，键仍按语言分组（中文出 `2013a/b`、英文出 `2013`）
——非默认 + 极罕见，且只是少一个后缀、不会误导（那条英文匿名仍是唯一的 `2013`）。

**矩阵**　`05-sort/disambiguate.typ` 加 d11/d12（两条无责任者同年）+ 专门 case，golden 锁住。

## ✅ #18　电子资源驱动的出版年槽绕过 edtf-year，EDTF 波浪号漏进版面〔已修〕

**现象**（电子资源缺出版年 + `date-fallback: "urldate"`）

```
（2025~）[2025-05-06]     ← 波浪号原样漏出，应为 （[2025]）
```

**根因**　`date-fallback` 往 `year` 注入带 EDTF「约」标记的推定值（`2025~`），靠 `edtf-year` 转成
方括号 `[2025]`（§7.5.4.3 估计的出版年置于「[]」内）——书驱动走 `publication-date.year` 会过
`edtf-year`，但电子资源驱动（EB / DS / PP 平台式）的出版年槽是 `str(year-field)` **直出**，注释还
写着「只有年份，转 str 直接输出」。波浪号于是漏进版面。用户 .bib 手写的 `year=2020~` 同病。

**修法**（`built-in.typ` 电子资源驱动）　`publication-year` 从 `str(year-field)` 改为
`publication-date.edtf-year(str(year-field))`——`edtf-year` 已 import（§7.6 的 `modified` 早在用它），
无 `~` 的年份原样返回，不影响正常条目。

**边界**（已实测）　有真出版年（无 `~`）不变；bib 手写 `year=2020~` 也一并出 `[2020]`；
`date-fallback: none` 缺年就是缺年、不注入；普通书 `year=2019~` 走另一路径，不受影响。

**矩阵**　`03-names/date-fallback.typ` 加 f5（`@online` 缺出版年）+ 2025 版平台式 case，golden 锁住。

**后续（原「遗留」已解决）**　`（[2025]）` 那个「方括号套圆括号」进一步查明是更实质的问题：
citeproc-lua + 官方 2025 CSL 实测，网页 / 数据集 / 预印本缺出版年**根本不推定**，只出 `[引用日期]`
（网页走 `creation-accessed-date` 宏，无 accessed→issued 兜底；兜底只在图书类的 `date` 宏里）。
已修（后一个提交）：`date-fallback` 跳过 2025 版平台式电子资源（EB / DS / PP），只对有传统出版年槽的
类型（图书、联机图书等）推定。三类电子资源缺年现在都只出 `[引用日期]`，与 citeproc 一字不差。
