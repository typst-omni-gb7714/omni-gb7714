# 矩阵测试暴露的问题

重构测试套件时，穷举参数取值暴露出来的真实缺陷。

**已修**：#1 / #2 / #3 / #4 / #5 / #6 / #7 / #8 / #9 / #12 / #13 / #14 / #17 / #18 / #20 / #21 / #22 / #23。
**待办**：#16（西文刊名实词首字母大写——唯一的真合规缺陷）。
**待裁决**：#10 / #11——不是纯 bug，是「加不加能力」先要定下来。
**延后**：#15（2026-07-22 定；不是否决，触发条件 = 「重复位模板化 / 自定义脚注形状」落地）。
**搁置**：#19（无稳定复现用例）。

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

## ✅ #10　模板表达不了年卷期的**区间解析**〔已做 · `serial-block` token · 出版年段剩余〕

**✅ 已做（2026-07-30）**：加了 `serial-block` token（照 `imprint-block` / `series-block` 模式——`fields/built-in.typ`
白名单 + 分支调 `built-in-driver.serial-year-volume`）。内置 serial 驱动里「拆年卷期、交叉重排」那段抽成独立
函数 `serial-year-volume(entry, opts)`（返回 `(block, start-year, end-year)`），驱动与 token 共用，逐字节不变
（twins 逐字复现内置 + matrix 全绿）。模板可写 `author. title<mark-medium>. <serial-block>. …`，输出
`1957，1（1）—1990，15（4）`（原来单 token 拼不出、只出 `1957/1990，1-15（1-4）`）；只对连续出版物有值，图书等出空。
手册 periodical 的 bib-fields 改用 `<serial-block>`，token 速查表 + extra 更新，字段说明补 EDTF 写法（约标记 / 区间 /
开区间 / BCE）。**剩余（次要）**：出版项末尾的出版年区间段（`1957—1990`）模板仍取起始年示意（`<date{—}>`），真区间
`@periodical` 的完整 twins 待第二个「出版年区间」token——它罕见（整本连续出版物少单独著录、通常著录析出文献），暂不做。

原始记录（提案背景）如下——

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

## ⏸ #15　`et-al-subsequent-min` / `et-al-subsequent-use-first`〔延后 · 依赖「重复位模板化」〕

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

三条路：**A** 只做脚注制 / **B** 两制式都做 / **C** 不做。

**2026-07-22 定：延后，不是否决。触发条件 = 「重复位模板化（自定义脚注形状）」落地。**

理由是下面这条**结构性**结论：现在做，本功能在包里**没有可截断的对象**——国标规定的重复引用形态
不含责任者，而那些真需要它的样式的形态我们又渲染不出来。等模板化落地、用户能自定义出「责任者 +
首注号」这类重复位形状之后，阈值才有意义。届时按本节末尾的方案实施。

### 依据一：现在做的话，国标体系内没有这个功能的作用对象

四步实测（语料 `redleafnew/Chinese-STD-GB-T-7714-related-csl`，345 个方言）：

| 步骤 | 结果 |
|---|---|
| ① 按「有无 `type-id` / `medium-id` 宏」判国标系 | **219 个**。判据自检通过：官方 GB 样式在集内，中外法学 / 西南政法大学在集外 |
| ② 219 个国标系里用 `et-al-subsequent-*` 的 | **0 个** |
| ③ 219 个里连 `position="subsequent"` 分支都有的 | **仅 4 个**（官方 GB—2015 注释双语的四个变体） |
| ④ 这 4 个的再引分支渲染的责任者名单数 | **全部 0** |

第 ④ 步是关键，它们的再引分支体是：

```xml
<else-if position="subsequent">
  <group delimiter=": ">
    <text variable="first-reference-note-number" prefix="同"/>   <!-- 同N -->
    <text variable="locator"/>                                    <!-- 页码 -->
  </group>
</else-if>
```

**「同N: 页码」，一个责任者都不出。没有名单就没有可截断的对象。** GB §9.2.1.3 规定的重复引用形态
（标注首次引用序号 + 引文页码）本就不含责任者，本功能在国标体系内无处安放。我们的 `number` 档
已完整实现它——且实现了官方 CSL 自认做不到的圈码 ①（其源码注释原话：「国标要求提供的示例中
注释编号是用圈码，在 CSL 中无法实现」）。

### 依据二：现在用这个功能的样式全部非国标（两条独立方法一致）

全语料 345 个里只有 **1 个**用了 `et-al-subsequent-*`（中外法学）。连同其余 11 个「重复位另作
处理」的样式：

- **方法一 · 结构相似度（带基线自证）**：官方 GB 两个变体互比 = **57%** 宏名重合；中外法学 /
  西南政法大学 / 法学引注手册 = **0%**（46 / 69 / 69 个宏零共有）；世界历史等 5 个 = 14–20%，
  且唯一共有的宏是最通用的 `author`。宏体系架构也不同：母版是 `entry-layout` / `note-layout` /
  `type-id` / `medium-id`，法学系是「功能 × 语种」三联（`author-short-zh` / `citation-layout-de`…）。
- **方法二 · 文献类型标识**：这 12 个一个都不发 `[M]` / `[J]`，而 §8 每条格式串都要求它。

⚠️ `<link rel="template">` 出处元数据在本语料**不可用**——连官方 GB 样式自己都没声明。

### 补扫的第二种编码方式

「首引 / 再引两套阈值」除了 `<citation>` 上的 `et-al-subsequent-*`，还可写成 `position="subsequent"`
分支调用自带 `et-al-min` 的 `<names>` / `<name>`。`<name et-al-min=>` 在语料里出现 **332 次、涉及
44 个文件**，但那只是「在哪里设阈值」的常规写法；**国标系里没有任何一个把它用成首引 / 再引两套值**。

### 为什么是「先模板化、后本项」这个顺序

- **单做本项覆盖不了那些法学样式**：中外法学的再引形态是「责任者，见前注〔N〕，页码」，我们四档
  都没有（`number` 无责任者、`shortened` 出题名不出首注号）。**先卡住的是形态、不是阈值**——所以
  「重复位模板化」是本项的**前置项**（见记忆 `footnote-repeat-position-template`）。模板化落地后，
  用户能写出带责任者的重复位形状，本项的阈值才有可截断的对象。
- **B 分支仍单独否决**（与延后无关，将来实施时也不走 B）：著者-出版年制没有「之前引过没有」的判定，
  要加就得给每个 cite 引入跨全文的已引 key 集合，碰性能命脉；而语料里 in-text 唯一用例
  （澳門科技大學）首引与再引两套值相同，写了等于没写。**将来实施时仍按 A（只做脚注制）。**

### 触发条件满足后，A1 按此实施

「重复位模板化」落地后（届时用户可自定义出带责任者的重复位形状，阈值才有作用对象），按此实施：参数名
`footnote-repeat-et-al-min` / `footnote-repeat-et-al-use-first`（**不含 `shortened`**——那是另一个
参数的取值、且是实现进度不是语义边界）；只作用于 `shortened` 档（`_short-body` 里
`creators.principal` 单一调用点）；取值走 `creators.resolve-et-al` 三档（标量 / 语种字典 /
角色×语种字典）；校验须用 (新 min, 新 use-first, **继承的** use-last) 走 `resolve-et-al-triple`
——会产生「首引配置合法、重复位配置也合法、组合才违反前置条件」的新报错，须在 doc 写明。

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

## ⏳ #19　`#cite(style:"author-date")` 在多区块顺序编码制文档里触发消歧 → 不收敛（既有，非本次引入）

**现象**　一个含多个 `#show: gb7714.with(..)` 区块的文档（如 matrix 测试文件），全局顺序编码制，
其中一处用 `#cite(<key>, style: "author-date")` 覆写、且被引条目同责任者同年（触发 a/b 后缀消歧），
编译报 `document did not converge within five attempts`（警告，退出码 0）。单区块文档不复现。

**根因**（初判）　per-cite 的 `style` 覆写走 `_cite-style-state`（markup 层 state），文献表渲染读
state-受影响的值算消歧后缀存回 `_list-suffix-map`，cite 标签又读它——多区块下这条 state 往返在
布局迭代间反复，5 轮内收敛不下来。

**与性能优化的关系**　**无关，早于本次优化**：完全原始代码（无 `_need-global-disambig` /
`_uses-ad-label` 任何门控）+ 同一用例照样不收敛。性能优化（消歧门控）的收敛安全性已由全套验证
（含单区块 `style-ad-override.typ` 回归、check-clean 门）。本条是撞出来的独立既有 bug。

**规避**　回归用例 `tests/matrix/14-per-cite/style-ad-override.typ` 隔离成*单区块*，绕开此隐患。

**待办**　真正修它要拆 per-cite `style` 覆写的 state 往返（可能改成 markup 层一次定、不经文献表
回读），或让消歧后缀不依赖 per-cite state。牵涉命脉，另立。

**2026-07-16 探索结论：不做「位置态→载荷通道」重构。** 起初以为把 14 个 per-cite 覆写轴从
`_cite-*-state` 位置态换成 supplement/旁车载荷能顺带提速命脉。子代理全量测绘 + `--timings` 火焰图
（500 cite 基准）推翻了：`state.at` 只占 **0.12%**（6.1ms / 5.2s，1.2µs×5049 次），`realize`（版面）
占 87.6%、`func call` 占 7.9%。**换通道省不出可感知速度，还可能因载荷解析微微变慢**——过不了「必须提速」
的线。且那 14 轴里值钱的几个（`merge`/`sort`/`collapse`/`compress`/`style`/`bib-label`）需全文知识、
**无法 markup 烘焙**，重构只是换通道不减读。#19 的收敛警告用 10+ 种多区块结构（含渲染 bib 的 `case`）
**当前复现不出**（三道缓冲——单调闩锁、文档序、主表写进后缀表——把环压住了），没有稳定失败用例＝无法
验证修复。故搁置。详见 issue 与 [[host-separator-term-plan]] 记忆里的 terms→punct 病态旁注。

## ✅ #20　多区块下 author-date 后缀丢失 / 串表（浅：per-cite 覆写；深：两 AD 主表）〔已修 · 按 bib 实例建键〕

**现象**（MWE，退出码 0、无警告）
```typ
#import "/lib.typ": *
#let b = bytes("@article{ov1, author={钱一}, title={甲}, journaltitle={刊}, year={2021}, volume={1}, pages={1}, langid={chinese}}\n@article{ov2, author={钱一}, title={乙}, journaltitle={刊}, year={2021}, volume={2}, pages={2}, langid={chinese}}")
#show: gb7714.with()
块一 #cite(<ov1>, style: "author-date") #cite(<ov2>, style: "author-date")
#bibliography(b, full: false, title: none)

#show: gb7714.with()
块二引任意条目 #cite(<ov1>)
#bibliography(b, full: false, title: none)
```
块一输出 `(钱一, 2021, 2021)`——**a/b 后缀丢了**，应为 `(钱一, 2021a, 2021b)`。只有块一（无块二）时正确。
块二引的是不是同一 key 无关（引无关条目 `ov3` 也照丢）。

**根因**（已证）　`_list-suffix-map`（api.typ:1431）是按 list-label 建键的全局 state；主表都用空串 `""`。
块二那张 numeric 文献表渲染时消歧门控 false → 往 `_list-suffix-map[""]` 写**空后缀**（api.typ:2415），
且它在文档序里最后。cite 标签读 `_list-suffix-map.final()`（api.typ:2913）拿到的是**最后一次写＝空**，
于是块一的 cite 丢了后缀。两张不同主表共用 `""` 键 → 后写覆盖先写。

**修法（B，按 bib 实例建键，已落地——浅深两层一并根治）。** 起初做过窄修 A（空写不覆盖非空），只堵浅层；
后来发现**多张文献表本就触发 0.15 原生模式**（`_is-native-mode` 在 `bibs.len() > 1` 即真，native-aux.typ:18），
而原生路由**早已把每个 cite 分派到某张 bib**（`_native-route-table` 给出 `bib-index`，api.typ:2726 把它烘焙进
marker 的 `_ML` 槽）——**实例身份一直存在**，我先前「主表 cite 无实例身份」的判断是错的（漏看了 native 路径）。

落点三处：
1. `bibliography()` 壳（lib.typ）native 模式把 `my-bib-index` 传进 print-bib（新参 `native-bib-index`）；
2. **写侧**（print-bib，api.typ:`_list-suffix-map.update`）native 时按 `"\u{0}b" + bib-index` 建键，各主表互不覆盖；
3. **读侧**（group 渲染器，api.typ:`_list-disambiguation`）native 时按*本组的 bib-index*（`my-list-id`，与写侧
   同源的文档序 bib 位置）取*所属表那一份*后缀，**不合并**。⚠️曾用「合并所有表」（merge），错：**同一个 key
   跨表引用时后缀不同**——如 a1 在表一同年对里是 `2020a`，在表二单独出该是 `2020`。合并会让 a1 在表二也拿
   `2020a`，与表二著录 `2020` 打架，还因与表一同形被下游去重丢掉（cite 整个不显示）。按表取后各随各表、对齐原生。

非 native（单表 / 命名列表 `set-bib-label`）走原 list-label 键，零改动。A 的「空写不覆盖非空」判据保留作兜底
（native 下键已互斥、无碰撞，A 逻辑天然不触发）。

**依据**：原生 std.bibliography（`gb-7714-2015-author-date`）实测就是**逐表消歧**——单表两同年 → a/b；同年对
分居两表 → 两边都无后缀；a1 跨两表 → 表一 `2020a`、表二 `2020`。parity 案例 `native/27-ay-multibib-disambig`
（native 与 ours 成对）锁住此对齐。

**验证**：浅 MWE `(钱一,2021,2021)→(钱一,2021a,2021b)`；深 MWE 两块各得 `钱一2021a/b`/`孙三2018a/b`；跨表同 key
a1 表一 `2020a`、表二 `2020`（与各自著录一致，15/15 稳定、零掉条零未收敛）；**142 条既有 golden 逐字节不变**；
全套件 ALL GREEN（disambiguate 对拍 citeproc-lua、native parity 27、发布四闸、check-clean）；回归
`style-ad-override-multiblock.typ`（四块）+ `parity/native/{native,ours}-27`。#19 收敛警告仍独立、当前复现不出，搁置。

## ✅ #21　native 多表下 cite 不继承所属表的样式（混排 numeric + author-date 表）〔已修 · 对 Typst 源码审计发现〕

**现象**　同一文档混排「一张 author-date 表 + 一张 numeric 表」（`bibliography(style: "author-date")` /
`"numeric"`，或 CSL 全名 `gb-7714-2015-*`）时，author-date 表的 cite 应出 `(Alpha, 2020)`，实际错出 `[1]`。

**依据**（Typst 0.15 源码 `model/bibliography.rs`）　`prepare_cite_group` 里每条 cite 的样式 =
`citations.first().style` 缺省时 `?? bib.style`——**cite 无自己的 `style` 时继承所属 bibliography 的 `style`**。
（同源确认：Typst 消歧**逐表**、无跨表协调；`#cite(style:)` 原生也支持并可覆盖 bib 样式。这条印证 #20 逐表方向。）

**根因**　native 模式 cite 的 `my-list` 恒 `none`，`eff-style` 读主列表共享的 `gb7714-main-list-style`
（last-write-wins）；两张不同样式的主表下 `main-list-style.final()` = 最后一张（numeric），所有 cite 都用它。

**修法**（与 #20 后缀同一手法：per-bib 状态按 bib 实例索引存 / 取）　写侧 print-bib 在 `native-bib-index != none`
时把本表 `eff-cite-style` 存进 `_list-style-map["\u{0}b"+index]`；读侧 cite 在 native 且 `my-list-id != none`
时按其 marker 携带的 bib-index 取所属表样式，回落 `global-style-cite`。142 golden 逐字节不变；全套件 ALL GREEN；
新增 parity `parity/native/{native,ours}-28-mixed-style-cite`。

**边角审计结论（对 Typst 0.15 源码 + 成对实测）**：多表的**路由**（后续→前置 auto，`select_auto_bib`）、
**逐表消歧**、**编号**（group offset，仅 `displays_citation_number` 的表推进）、**条目收集**（cited + full）、
**per-cite `#cite(style:)` 覆盖**——ours 全部逐条对齐原生。本 #21 是审计中唯一发现的分歧，已修。

## ✅ #22　跨 bib 的相邻 cite 组不拆 subgroup（整组用首项样式）〔已修 · 对 Typst 源码审计发现〕

**现象**　一个相邻 cite 组跨两张不同表：`@a @b`（a→表一 author-date、b→表二 numeric）。应出
`(Alpha, 2020)[1]`（各随所属表），实际 ours 出 `(Alpha, 2020; Beta, 2021)`——b 错用了首项 a 的 author-date。

**依据**（Typst 0.15 `model/cite.rs` 的 `CiteGroup` doc + `bibliography.rs` `prepare_cite_group`）　相邻 cite
先无差别成组，再在 `Works::generate` 里**按归属 bib 拆成 subgroup**（`prepare_cite_group`：归属 bib 一变就
flush 当前 subgroup，组间空格保留），每个 subgroup 各自交 hayagriva 渲染。subgroup 连续——非连续的同 bib
cite（`@a@b@a`，b 在中间）各自成段。

**根因**　ours 组渲染器 `_render-inline-cite-run` 用*首项* bib-index（`my-list-id`）定整组的样式 / 后缀。

**修法**　函数开头按每项 `it.list`（bib-index）把 items 切成*连续段*，多段则每段递归本函数（每段 bib 均匀→
`my-list-id` / `_list-style-map` / `_list-suffix-map` 各随其表）、相邻拼接。单 bib 组短路走原逻辑。142 golden
逐字节不变；实测 `@a@b@c`（跨三表）、`@a@b@a`（非连续）都逐条对齐原生。新增 parity native/29-crossbib-group。

## ✅ #23　`#cite(form: "full")` 原位完整条目〔已修 · 审计发现〕

Typst `cite.rs` 的 `CitationForm::Full`「Mimics a bibliography entry, with full information」——`#cite(<k>, form:"full")`
在 cite *原位*（非脚注）渲染完整著录条目（顺序编码制 `[1] 著录`、著者-出版年制带「作者，年」前缀），条目在
正文原位再现一份、文献表照样保留。原生实测确认是**原位行内**，不是脚注（与 `footnote:true` 两条独立路径）。

**修法**　`errors.typ` 的 `cite-form` 白名单加 `"full"`；组渲染器 `_render-items` 加 `form == "full"` 分支，每条
复用 `_emit-entry`（numeric，带 `[N]`）/ `_emit-entry-author-date`（author-date）——与文献表同一渲染，多条以
文档分隔符连接。两制式逐字节对齐原生；142 golden 不变；`errors-sync`/`api-coverage` 过；parity native/30-form-full。

---

### 多 bib 行为边角审计小结（2026-07 · 对 Typst 0.15 源码 `bibliography.rs`/`cite.rs` 逐函数比对 + 成对实测）

**逐条对齐原生**：路由（后续→前置 auto，`select_auto_bib`）· 逐表消歧（每表独立 driver，#20）· 编号偏移
（group none/auto/named，仅 `displays_citation_number` 表推进，S2/S11/D）· 条目收集（cited+full，S1）·
form prose/author/year/**full**（#23）· per-cite `#cite(style:)`（cite.style ?? bib.style，#21）· 跨 bib 组 subgroup 拆分（#22）。
**ours 更 GB-faithful 处**：supplement 引文页码 ours 出、社区 CSL 不出（§9.2.1.3）。**该轮审计的全部分歧（#21/#22/#23）均已修，多 bib 行为逐条对齐原生。**
