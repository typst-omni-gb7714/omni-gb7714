#!/usr/bin/env bash
# omni-gb7714 测试总入口。一处跑全部，逐层汇报，任一失败即非零退出。
#
#   bash tests/run.sh              跑全部
#   bash tests/run.sh matrix       只跑某一层（matrix / contract / parity / unit）
#   bash tests/run.sh matrix 03-names   只跑矩阵的某一组
#
# 四层，各管一头：
#
#   matrix/    **参数 × 取值**。一个参数 = 一个文件 = 一份 golden。
#              渲染结果抽成文本与 golden 逐行比对——*差异就是该人工审核的地方*。
#              这是发布前的主闸：改了 src，这里出的 diff 就是行为变化的完整清单。
#
#   contract/  **契约与不变量**。不看渲染结果，看结构性的约定：
#              公共参数有没有被测全、转发层有没有漏参数、错误表有没有死条目、
#              模板 token 白名单与分支是否对齐、非法取值有没有按约定报错、
#              HTML 语义标签在不在位、文献表是不是单个 block、
#              以及字形开关（斜体 / 粗体 / 上标 / 超链接——文本 golden 看不见它们）到底有没有在做事。
#
#   parity/    **对拍**。跟外部权威比：typst 原生 CSL 路由、真 biblatex 的 LaTeX 渲染与笔画序、
#              手册里的内建格式串、国标原文复刻件。
#
#   unit/      **单元**。直接测内部算法（语言判定准确率、姓名 CJK↔拉丁间距）——
#              这些从公共 API 看不见。`tests/` 里唯一允许 import src/ 的地方。
#
#   integration 整个仓库还编不编得动：手册（PDF + HTML）、benchmark 的双驱动、
#              发布版打包的四道闸（语法 / 等价 / 保留 / 幂等）。
#              「等价」那道闸就是拿*剥完注释的包*重跑一遍矩阵——剥注释一旦动到代码，golden 必红。
#
# 环境依赖缺了就跳过（打 ⏭），不算失败：
#   typst 0.15+（tests/bin/typst-0.15.0）→ parity/native 与矩阵里带 `//! typst: 0.15` 头的用例
#   latexmk（xelatex + biber）           → parity/stroke-sort
#   citeproc-lua + xelatex               → parity/disambiguate、parity/et-al-use-last（与真 CSL 引擎对拍）
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TYPST="${TYPST:-typst}"
TYPST15="$ROOT/tests/bin/typst-0.15.0"
LAYER="${1:-all}"
GROUP="${2:-}"
fails=0; skips=0

sec()  { echo; echo "── $1 ──"; }
bad()  { echo "   ❌ $1"; fails=$((fails+1)); }
skip() { echo "   ⏭  跳过：$1"; skips=$((skips+1)); }

want() { [ "$LAYER" = "all" ] || [ "$LAYER" = "$1" ]; }

if want matrix; then
  sec "matrix（参数 × 取值 · golden 对照）"
  TYPST15="$TYPST15" bash tests/matrix/run.sh $GROUP || bad "矩阵与 golden 有差异（上面列出了是哪些）"
fi

if want contract; then
  sec "contract（契约与不变量）"
  bash tests/contract/api-coverage.sh   || bad "有公共参数没被矩阵覆盖"
  bash tests/contract/config-sync.sh    || bad "lib.typ 转发层与工厂签名漂移"
  bash tests/contract/errors-sync.sh    || bad "错误表与调用点漂移"
  bash tests/contract/token-whitelist.sh || bad "模板 token 白名单与处理分支漂移"
  bash tests/contract/no-src-import.sh  || bad "有测试伸手进了 src/ 内部"
  bash tests/contract/panic/run.sh      || bad "报错用例不按预期报错"
  bash tests/contract/structure/run.sh  || bad "渲染结构不变量被破坏"
  bash tests/contract/typography/run.sh || bad "有字形 / 几何开关悄悄失效了"
fi

if want parity; then
  sec "parity（与外部权威对拍）"
  if [ -x "$TYPST15" ]; then
    TYPST="$TYPST15" bash tests/parity/native/run.sh >/dev/null 2>&1 \
      && echo "   ✅ 原生 CSL 路由 / 编号不变量一致（26 例）" \
      || { bad "与 typst 原生的对拍失败"; TYPST="$TYPST15" bash tests/parity/native/run.sh 2>&1 | grep FAIL | sed 's/^/     /'; }
  else
    skip "无 typst 0.15+（tests/bin/typst-0.15.0）→ parity/native"
  fi
  out=$(bash tests/parity/latex/run.sh 2>&1) && echo "   ✅ $(echo "$out" | tail -1 | sed 's/^ *//')" || { echo "$out" | grep -i fail | sed 's/^/     /'; bad "LaTeX 渲染与 biblatex 不一致"; }
  out=$(bash tests/parity/format-twins/run.sh 2>&1) && echo "   ✅ $(echo "$out" | tail -1 | sed 's/^ *//')" || { echo "$out" | grep -i fail | sed 's/^/     /'; bad "手册里的内建格式串与内置渲染脱钩"; }
  bash tests/parity/facsimile/run.sh || bad "国标复刻件编译失败"
  if command -v latexmk >/dev/null 2>&1; then
    bash tests/parity/stroke-sort/run.sh >/dev/null 2>&1 \
      && echo "   ✅ 中文姓名笔画序与 biblatex 一致" \
      || bad "笔画排序与 biblatex 不一致"
  else
    skip "无 latexmk（xelatex + biber）→ parity/stroke-sort"
  fi
  if command -v citeproc-lua >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1; then
    out=$(bash tests/parity/disambiguate/run.sh 2>&1) \
      && echo "   ✅ $(echo "$out" | tail -1)" \
      || { echo "$out" | sed 's/^/     /'; bad "消歧梯子与 citeproc-lua 不一致"; }
    out=$(bash tests/parity/et-al-use-last/run.sh 2>&1) \
      && echo "   ✅ $(echo "$out" | tail -1)" \
      || { echo "$out" | sed 's/^/     /'; bad "et-al-use-last 的省略结果与 citeproc-lua 不一致"; }
  else
    skip "无 citeproc-lua（TeX Live 的 citation-style-language）→ parity/disambiguate、parity/et-al-use-last"
  fi
fi

if want unit; then
  sec "unit（内部算法）"
  bash tests/unit/run.sh || bad "内部算法探针失败"
fi

if want integration; then
  sec "integration（手册 · benchmark · 发布打包）"
  TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
  if ./easy-zh-manual/web/build.sh >/dev/null 2>&1; then
    echo "   ✅ 手册 PDF + HTML 构建"
    grep -qo '\[1\]' easy-zh-manual/web/dist/index.html \
      && echo "   ✅ HTML 文献表标号在位" \
      || bad "HTML 文献表标号缺失"
  else
    bad "手册构建失败"
  fi
  if ( cd easy-zh-manual/web/dist/benchmark \
       && $TYPST compile --root . main-omni.typ "$TMPD/bm.pdf" >/dev/null 2>&1 \
       && $TYPST compile --root . main-hayagriva.typ "$TMPD/bmh.pdf" >/dev/null 2>&1 ); then
    echo "   ✅ benchmark 双驱动编译"
  else
    bad "benchmark 驱动编译失败"
  fi
  if python3 scripts/make-preview.py --check >"$TMPD/mp.log" 2>&1; then
    echo "   ✅ 发布版打包：语法 / 等价 / 保留 / 幂等 四闸通过"
  else
    bad "发布版打包未通过"
    tail -12 "$TMPD/mp.log" | sed 's/^/     /'
  fi
fi

echo
echo "════════════════════════════════════════════════════════════"
if [ "$fails" -eq 0 ]; then
  echo "  ✅ ALL GREEN（跳过 $skips 个需外部依赖的）"
else
  echo "  ❌ $fails 处失败（跳过 ${skips}）"
fi
echo "════════════════════════════════════════════════════════════"
[ "$fails" -eq 0 ]
