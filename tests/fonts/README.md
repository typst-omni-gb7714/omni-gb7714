# 固定测试字体

首次运行测试前执行：

```sh
python3 tests/fonts/setup.py
```

它下载约32 MiB的Noto Sans CJK SC Regular／Bold和OFL许可，保存在本目录，不安装系统字体。版本固定为noto-cjk Sans2.004，commit `523d033d6cb47f4a80c58a35753646f5c3608a78`；文件按该commit的Git blob摘要核对。已有文件摘要不符时报错，不覆盖用户文件。

`setup.py --check`只核对本地文件，不联网。测试入口通过`env.sh`设置`TYPST_FONT_PATHS`，优先加载这份固定副本。重复source不会重复追加路径。

测试字体栈统一定义在`tests/_fixture/fonts.typ`：

1. Typst内置Libertinus Serif：西文、俄文及原有西文斜体／粗体；
2. Noto Sans CJK SC 2.004：中文、日文、韩文、粗体和圈码；
3. Typst内置DejaVu Sans Mono：箭头、警告、方括号等补充符号。

矩阵额外使用`--ignore-system-fonts`，避免用户安装的符号字体参与自动回退。专门验证Times／SimSun等指定字体的几何用例仍使用其原设置；不对整套测试关闭系统字体。

编辑器或手动单文件编译需要把本目录加入字体搜索路径：

```sh
TYPST_FONT_PATHS="$PWD/tests/fonts" tests/bin/typst-0.14.2 compile --root . tests/fonts/specimen.typ specimen.pdf
```

`contract/fonts/run.sh`使用同一份样张，关闭系统字体后分别验证主版本和0.15的真实PDF：覆盖中日韩、西文、俄文、粗体、①至㊿和必要符号，核对文本与实际嵌入的字体来源。固定字体文件摘要也参与检查，避免仅凭“提取文字正常”接受错误字形。

字体变化会影响精确排版基准。更换版本前应保存旧基准、逐项审阅新输出，再更新golden；不要只为测试变绿而刷新。2026-11-12本次51项已审阅差异见`reports/test-fonts-2026-11-12/`。
