# omni-gb7714 测试

```
bash tests/run.sh                    # 全部
bash tests/run.sh matrix             # 只跑某一层（matrix / contract / parity / unit / integration）
bash tests/run.sh matrix 03-names    # 只跑矩阵的某一组
bash tests/matrix/run.sh --update    # 改完 src、审完差异之后，重新生成 golden
```

发布前跑 `bash tests/run.sh`。**矩阵出的每一处 diff 都是一处行为变化**，逐条审过再发。

---

## 五层，各管一头

| 层 | 管什么 | 失败意味着 |
|---|---|---|
| `matrix/` | **参数 × 取值**。一个参数 = 一个文件 = 一份 golden | 渲染结果变了 |
| `contract/` | **契约与不变量**。参数有没有被测全、转发层有没有漏、报错文案对不对、HTML 语义在不在、字形开关有没有在做事 | 结构性的约定被破坏了 |
| `parity/` | **对拍**。typst 原生 CSL、真 biblatex、手册的内建格式串、国标复刻件 | 跟外部权威不一致了 |
| `unit/` | **单元**。直接测内部算法（语言判定、姓名间距）——从公共 API 看不见的东西 | 内部算法回归了 |
| `integration` | 整个仓库还编不编得动：手册（PDF + HTML）、benchmark 双驱动、发布打包四闸 | 仓库级的东西坏了 |

`integration` 的「等价」那道闸，就是拿*剥完注释的发布包*重跑一遍矩阵——
剥注释一旦动到代码，135 份 golden 里必有一份出差异。

外部依赖缺了就跳过（打 ⏭），不算失败：
`tests/bin/typst-0.15.0` → `parity/native` 与矩阵里带 `//! typst: 0.15` 头的用例；
`latexmk`（xelatex + biber）→ `parity/stroke-sort`。

---

## matrix：一个参数 = 一个文件 = 一份 golden

这一层是主闸，也是**以后追加测试必须遵守的规矩**。

**形态**：文件里穷举该参数的*全部*取值，每个取值渲成一个区块（取值名 + 正文标注 + 文献表），
渲染结果抽成文本存进 `_golden/`。**golden 是一张人能直接判对错的对照表**——它不是给机器看的
校验和，是给人看的。改了 src，`bash tests/run.sh` 出的 diff 就是行为变化的完整清单。

**文件头必须写清三件事**（`contract/api-coverage.sh` 会检查头在不在）：

```typst
//! param: show-anon
//! values: auto, true, false
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "show-anon", controls: "责任者不明时是否补占位词（佚名 / Anon）。",
  expect: [ …现在期望的行为，以及依据（国标条款 / 官方 CSL / biblatex 实测）… ])
#case("auto · 著者-出版年制（→ true）", gb7714.with(style: "author-date"), cites: (<bm-noauthor>,))
```

`expect` 写**现在期望的行为**，不写「曾经怎样」。审 golden 的人不用回翻代码就该知道这里该长什么样。

`spec` 必须作为 **show 规则**用（`#show: spec.with(..)`）：`set` 只对函数*自身产出的内容*生效，
写成 `#spec(..)` 的话 `set text(lang: "zh")` 管不到后面的区块，整篇文档的语言就还是 typst 缺省的
`en`（`title: auto` 会出 "Bibliography"、`by-doc-*` 标点档会走半角）。

**分组**：目录名即职责。动了某个 API，去它所在的那一组改测试。

```
01-style      style / version / full / cite-completion
02-cite       cite-* 一族（标注形态、合并、压缩、脚注、排序…）
03-names      姓名与责任者（八维字典、截断词、占位词、前缀、idem…）
04-layout     文献表版式（标题、编号、缩进、行距、断字）
05-sort       排序与消歧（键、文种、拼音笔画、置顶）
06-display    show-* 显示控制一族
07-pid-url    永久标识符与 URL（show-pid / pid-priority / 去重 / 断行）
08-punct      标点（风格档、覆写、矫正、末尾句点、页码）
09-typography 字形（斜体、粗体、大小写）
10-latex      LaTeX 严格模式
11-footnote   脚注制的梯子（重复引用、同上、重置界、圈码）
12-custom     五个 custom-* 扩展入口（custom-drivers 的模板语言单开子目录）
13-per-list   bibliography(..) 的逐表参数
14-per-cite   cite(..) 的逐次参数
15-types      文献类型（附录 A 全码 × 三版本）与各份语料的基准像
16-combo      联动：从实现反查出来的真实交叉（不是拍脑袋组合）
17-parse      载入 / 解析层（字段别名、crossref/xdata、namea、健壮性、预印本、排序代理）
18-structure  @set 条目集、局部作用域
```

**语料**在 `_fixture/`，六份，各有分工：

| 文件 | 覆盖 |
|---|---|
| `main.bib` | 八大类型 × 中英 × 有无年 / 责任者 / 获取路径——绝大多数用例的底本 |
| `edge.bib` | 边角：姓名 / 题名 / 出版项 / 卷期页 / 日期 / 结构 / PID / 取码链 |
| `lang.bib` | 六语种 + 缺 langid + 中西混排 + 中文排序四条 |
| `latex.bib` | LaTeX 命令、转义、重音、数学、verbatim、CJK 紧贴 |
| `types.bib` | 附录 A 每个标识码各一条 + 驱动要认的其余 entry_type |
| `parse.bib` | 载入层：字段别名、crossref / xdata、namea、畸形键、NFD、pubstate、sortkey |

**一篇文档只有一套 bib 数据**——`gb7714()` 把全文所有 `bibliography()` 的源拼起来*一次*解析。
所以同一个矩阵文件里不能混用两份含相同 key 的语料（会报 `duplicate key`）。

**golden 用 `pdftotext -layout` 抽**：它保留水平位置，所以悬挂缩进、编号列宽、对齐这类*几何*
变化也会留下痕迹。但它**看不见字形**（斜体 / 粗体 / 上标 / 超链接）——那部分由
`contract/typography/` 兜底（断言「开」与「关」的 SVG 必须不同，证明开关确实在做事）。

---

## contract：机器来管那些「人会忘」的约定

- `api-coverage.sh` —— 三个公共入口（`gb7714` / `bibliography` / `cite`）的**每一个参数**都必须在
  矩阵里出现过。参数清单从 `lib.typ` 的签名**现抽**，不写死路径：src 怎么拆模块都不影响它。
  加了新参数忘了加测试 → 红。
- `config-sync.sh` —— `lib.typ` 的转发字典与 `gb7714` 工厂签名逐一对应。漏转发一个参数，
  引擎会静默用自己的默认值、**不报错**——这道闸把它变成硬失败。
- `errors-sync.sh` —— `_MESSAGES` / `_ENUMS` 两张手写表与调用点、doc-comment 双向比对。
- `token-whitelist.sh` —— 模板 token 的白名单与处理分支双向比对。
  （这道闸是被一个真 bug 逼出来的：`location` 的分支写了、白名单忘了登记，那条分支*永远走不到*，
  手册里写着能用的 token 一写就 panic。见 `BUGS.md` #5。）
- `no-src-import.sh` —— 测试只许走公共 API。唯一例外是 `unit/`。
- `panic/` —— 32 个**必须报错**的用例，且报错文案要对得上。
  报错文案是面向用户的 API，改了文案就该改这里。
- `structure/` —— 文献表是单个 block、show 规则只命中正文不碰编号列、HTML 语义标签在位。
- `typography/` —— 字形与几何开关「开与关的渲染结果必须不同」。

---

## 追加测试的规矩

1. **改了哪个 API，就去它那一组**改 / 加文件。一个参数一个文件，别塞进别人的文件里。
2. 新参数 → 新文件，**穷举取值**，写清 `//! param:` 头与 `expect`（现在期望什么、依据是什么）。
3. 新的**联动**（两个参数交叉出新行为）→ 进 `16-combo/`，文件头写清这个联动**从哪看出来的**
   （实现里的哪一处、哪条国标、哪个权威样式）。
4. 非法取值 / 报错 → 进 `contract/panic/`（矩阵里的文件都得编得过，它们要产出 golden）。
5. 跑 `bash tests/matrix/run.sh --update`，**逐行审一遍新出的 golden**，再提交。

## 约定

- 所有 `run.sh` 都 `cd "$(dirname "$0")"`，从任意 cwd 跑都可以；失败非零退出。
- 临时文件一律 `mktemp -d`。写死的 `/tmp` 路径会被并发跑的另一个测试进程覆写，
  静默串台成假红（实测过：一个套件读到的是另一进程刚写进去的文件）。
- 判编译成败**必须查退出码**。`layout did not converge` 是*警告*、退出码仍是 0，
  grep 关键词那种判法抓不住它。
- 本 `tests/` 目录是开发期测试套件，已 gitignore，不随包发布。

## 已知未修

`BUGS.md` —— 重构测试套件时穷举取值暴露出来的真实缺陷，逐条记着现象、根因、最小复现，
以及矩阵里哪个取值正印着这个现象。
