# 笔画排序双驱动对照（biblatex ↔ omni-gb7714）

验证著者-出版年制下中文姓名**笔画排序**在 biblatex-gb7714-2015（胡振震样式，参照实现）
与 omni-gb7714 两个引擎下行为一致。

## 文件

| 文件 | 作用 |
|---|---|
| `refs.bib` | 共用书目：9 个中文条目（姓氏笔画数 2/4/5/6/7/8/9/10/11 互不相同）+ 2 个英文条目；书写顺序刻意打乱 |
| `biblatex.tex` | 驱动一：`style=gb7714-2015ay` + `sortlocale=zh__stroke`，xelatex + biber |
| `omni.typ` | 驱动二：`gb7714(.., style: "author-date", sort-zh-by: "bihua")` |
| `run.sh` | 编译两个驱动、从 PDF 提取著录顺序、逐项比对 |

## 运行

```sh
bash run.sh
```

依赖：`xelatex` + `biber`（`latexmk`）、`typst`、`biblatex-gb7714-2015` 样式。不纳入 `verify-all.sh`
（LaTeX 工具链非人人具备），按需手动运行。

## 预期

中文段按笔画升序、英文段按字母序、中文在前：

```
丁文江 王国维 田汉 刘半农 张元济 周作人 赵元任 徐志摩 黄宾虹 BROWN SMITH
```

两驱动应得此同一顺序。`run.sh` 末尾打印 `✅ 两驱动渲染顺序完全一致` 即通过。

## 已知差异边界

本对照用的 9 个姓氏笔画数互不相同，故顺序唯一确定、两驱动必然一致。
若书目含**同笔画数**的姓氏，其并列次序两驱动可能分歧：
biblatex `sortlocale=zh__stroke` 走 Unicode CLDR `zh-stroke` collation，
omni 的 `auto-bihua` 走 Unihan 笔画数 + cnchar 笔顺。多音字两边均可用 `sortkey` / `key` 域手动指定。
