# 笔画排序双驱动对照（biblatex ↔ omni-gb7714）

验证著者-出版年制下中文姓名**笔画排序**在 biblatex-gb7714-2015（胡振震样式，参照实现）
与 omni-gb7714 两个引擎下行为一致。

## 文件

| 文件 | 作用 |
|---|---|
| `refs.bib` | 共用书目：9 个中文条目（姓氏笔画数 2/4/5/6/7/8/9/10/11 互不相同）+ 2 个英文条目；书写顺序刻意打乱 |
| `biblatex.tex` | 驱动一：`style=gb7714-2015ay` + `sortlocale=zh__stroke`，xelatex + biber |
| `omni.typ` | 驱动二：2015版、`style: "author-date"`、`bib-sort-zh-by: "bihua"`，固定测试字体 |
| `run.sh`、`run.py` | 隔离编译两个驱动，校验作者完整性、唯一性及预期次序 |

## 运行

```sh
TYPST="$PWD/tests/bin/typst-0.14.2" bash tests/parity/stroke-sort/run.sh
```

在仓库根执行上述命令，也可从任意目录调用脚本；默认使用项目内Typst 0.14.2，`TYPST`可覆盖。
依赖`xelatex`、`biber`、`latexmk`、`pdftotext`及TeX中的`biblatex-gb7714-2015`和Fandol字体。
本项已纳入`tests/run.sh`的parity层，不能将顺序差异当成成功。

默认使用每次独立的临时目录，不读取或改写本目录已有的PDF、BBL。需要保留日志与PDF时，指定尚不存在的输出目录：

```sh
bash tests/parity/stroke-sort/run.sh --output "$PWD/reports/my-stroke-run"
```

LaTeX显式使用TeX自带Fandol，避免ctex在macOS探测系统字体时触发下载等待。若macOS版Biber的通用启动器因
`lipo`架构解包失败，runner仅在本次临时目录提取同一可执行文件的本机架构，并复核其版本；不替换系统工具。
其他Biber启动失败直接报错，不自动忽略。可用`BIBER`指定其他可执行文件路径。

## 预期

中文段按笔画升序、英文段按字母序、中文在前：

```
丁文江 王国维 田汉 刘半农 张元济 周作人 赵元任 徐志摩 黄宾虹 BROWN SMITH
```

每个作者必须各出现一次，两个驱动都必须与上述11条完整预期一致，不能仅比较两个不完整结果是否相同。
编译失败、超时、缺字、缺条、重复或次序错误均非零退出；Typst编译警告也判失败。

## 已知差异边界

本对照用的 9 个姓氏笔画数互不相同，故顺序唯一确定、两驱动必然一致。
若另外增加**同笔画数**的姓氏，其并列次序两驱动可能分歧，应为新语料明确制定预期：
biblatex `sortlocale=zh__stroke` 走 Unicode CLDR `zh-stroke` collation，
omni 的 `auto-bihua` 走 Unihan 笔画数 + cnchar 笔顺。多音字两边均可用 `sortkey` / `key` 域手动指定。
