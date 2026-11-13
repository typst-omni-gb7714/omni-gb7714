# 发布包测试

本目录同步开发套件，运行代码只取自`preview/0.1.0/`。入口会在独立临时目录重建测试布局，补齐手册、格式串及打包工具等支持材料；不会用开发仓库的lib/src替换发布代码。支持材料不属于用户下载包。

准备Typst 0.14.2和0.15.0，放入`tests/bin/`，或设置`TYPST`／`TYPST15`为绝对路径。二进制不提交。
Python探针需要pypdf、pypdfium2、Pillow、NumPy；原生、TeX对拍及复刻件的外部字体要求与开发套件相同。

```sh
python3 tests/fonts/setup.py
bash tests/run.sh
bash tests/run.sh matrix 03-names
bash tests/run.sh contract
```

固定测试字体约32MiB，保存在本目录，不安装系统字体；字体文件不提交，由setup.py按固定版本和摘要下载。
需要保留日志及测试工作区时传`--workdir`，目标须不存在：

```sh
TYPST=/absolute/typst-0.14.2 TYPST15=/absolute/typst-0.15.0 bash tests/run.sh --workdir /path/to/new-workspace
```

完整入口保留matrix／contract／parity／unit／integration五层，包括真实发布包上的手册和打包验证。不要在发布仓根直接运行原子脚本；单层检查经本入口传参。开发套件说明留在`_support/development-README.md`，其中直接访问根lib/src的命令针对重建后的工作区。
