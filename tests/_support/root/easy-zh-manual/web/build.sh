#!/usr/bin/env bash
# 生成手册 PDF + HTML 双输出
#
# 用法：在仓库根目录运行
#   ./easy-zh-manual/web/build.sh         # PDF + HTML
#   ./easy-zh-manual/web/build.sh pdf     # 仅 PDF
#   ./easy-zh-manual/web/build.sh html    # 仅 HTML
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/easy-zh-manual/template/main.typ"
OUT_DIR="$ROOT/easy-zh-manual/web/dist"
mkdir -p "$OUT_DIR"

# 先重建示例截图（egN.typ → egN.pdf），供手册 #image 引用
bash "$ROOT/easy-zh-manual/examples/build.sh"

build_pdf() {
  echo "[build.sh] Compiling PDF…"
  # 不过滤编译警告；目录和实时示例应在 Typst 的五轮布局计算内收敛。
  typst compile --root "$ROOT" "$SRC" "$OUT_DIR/manual.pdf"
  echo "[build.sh] → $OUT_DIR/manual.pdf"
}

build_html() {
  echo "[build.sh] Compiling HTML…"
  typst compile --features html --format html --root "$ROOT" \
    --input target=html "$SRC" "$OUT_DIR/index.html.raw" 2>&1 | grep -v "ignored during HTML export" || true

  # 先拷资源，再据内容算版本号注入 ?v=——浏览器对 <link>/<script>/动态 import 缓存极狠，
  #   没版本号时改了 site.js/style.css/benchmark.js 也看不到更新（须手动硬刷新）。内容哈希=只有真改了才换号。
  cp "$ROOT/easy-zh-manual/web/style.css" "$OUT_DIR/style.css"
  cp "$ROOT/easy-zh-manual/web/site.js"   "$OUT_DIR/site.js"
  cp "$ROOT/easy-zh-manual/web/benchmark.js" "$OUT_DIR/benchmark.js"
  cp "$ROOT/easy-zh-manual/web/brand-icon.png" "$OUT_DIR/brand-icon.png"

  # 注入 <link>/<script>（带 ?v= 内容哈希）到 index.html，并把 site.js 里对 benchmark.js 的动态 import 也打上同号。
  python3 -c "
import sys, hashlib
out = sys.argv[3]
ver = hashlib.sha1(b''.join(open(out+'/'+n,'rb').read() for n in ('style.css','site.js','benchmark.js'))).hexdigest()[:8]
with open(sys.argv[1]) as f: html = f.read()
css = f'<link rel=\"stylesheet\" href=\"style.css?v={ver}\">'
js  = f'<script defer src=\"site.js?v={ver}\"></script>'
html = html.replace('</head>', f'    {css}\n    {js}\n  </head>', 1)
with open(sys.argv[2], 'w') as f: f.write(html)
# 动态 import('./benchmark.js') 不经 <script>，单独打版本号
sj = out + '/site.js'
s = open(sj).read().replace(\"import('./benchmark.js')\", f\"import('./benchmark.js?v={ver}')\")
open(sj,'w').write(s)
print(f'[build.sh] 资源版本号 ?v={ver}（site.js / style.css / benchmark.js）')
" "$OUT_DIR/index.html.raw" "$OUT_DIR/index.html" "$OUT_DIR"

  rm -f "$OUT_DIR/index.html.raw"
  # WASM 性能基准用到的素材：gb7714 包源码（薄壳 + src/ 模块 + quan/ 依赖 + vendored citegeist）+ 280 条真实文献 bib + 两个驱动 main
  mkdir -p "$OUT_DIR/benchmark"
  cp "$ROOT/lib.typ"             "$OUT_DIR/benchmark/lib.typ"
  rm -rf "$OUT_DIR/benchmark/src" "$OUT_DIR/benchmark/quan" "$OUT_DIR/benchmark/citegeist"
  cp -R "$ROOT/src"                 "$OUT_DIR/benchmark/src"
  # vendored 魔改 citegeist：src/api.typ `#import "/citegeist/lib.typ"` + lib.typ 内 `plugin("citegeist.wasm")`。
  #   不再是 @preview 包，故必须随基准挂进虚拟 FS：lib.typ 走 manifest（文本 addSource），
  #   citegeist.wasm 是二进制由 benchmark.js 单独 mapShadow（addSource 只能挂文本）。
  mkdir -p "$OUT_DIR/benchmark/citegeist"
  cp "$ROOT/citegeist/lib.typ"        "$OUT_DIR/benchmark/citegeist/lib.typ"
  cp "$ROOT/citegeist/citegeist.wasm" "$OUT_DIR/benchmark/citegeist/citegeist.wasm"
  # 生成文件清单：WASM 虚拟 FS 需逐文件挂载 lib.typ + 全部 src 模块 + citegeist/lib.typ（benchmark.js 据此 addSource）。
  #   main-omni.typ 经 `#import "/lib.typ"` 触发，lib.typ 再函数内 `import "src/.."` 与 `/citegeist/lib.typ`，故整棵源码树都要在位；
  #   其余 @preview 依赖（mitex / auto-pinyin / quan 等）由 typst.ts 自动从包 registry 拉取，不进清单。
  python3 - "$OUT_DIR/benchmark" <<'PY'
import os, json, sys
base = sys.argv[1]
# os.walk 递归：src/ 已模块化成子目录（marks/ elements/ bib/ cite/ driver/ parse/ …），
# 只列顶层会让 WASM 虚拟 FS 缺子目录模块 → 浏览器端 import 失败。
files = ['lib.typ'] + sorted(
    os.path.relpath(os.path.join(dp, fn), base)
    for dp, _, fns in os.walk(os.path.join(base, 'src'))
    for fn in fns if fn.endswith('.typ'))
files.append('citegeist/lib.typ')
with open(os.path.join(base, 'manifest.json'), 'w') as f:
    json.dump(files, f)
print('[build.sh] → benchmark/manifest.json (%d typ files)' % len(files))
PY

  [ -d "$ROOT/quan" ] && cp -R "$ROOT/quan" "$OUT_DIR/benchmark/quan"
  cp "$ROOT/easy-zh-manual/web/benchmark/refs.bib" "$OUT_DIR/benchmark/refs.bib"
  # 真实文档驱动:不再用「裸参考表 full:true 无正文引用」(那把 omni 最贵的*正文引用*处理藏掉、
  #   且 warm 循环又把 bib 解析 comemo 缓存掉 → 实测远低估真实成本)。改为生成贴近真论文的文档:
  #   多章正文 + 散落的 #cite + 文末参考表(full:false 只列被引条目),omni/native 同体对照、仅引擎不同。
  #   引用 key 从 refs.bib 现取(始终有效);两个驱动正文逐字相同。
  python3 - "$OUT_DIR/benchmark" <<'PY'
import os, re, sys
base = sys.argv[1]
keys = re.findall(r'^@[a-zA-Z]+\{([^,]+),', open(os.path.join(base, 'refs.bib')).read(), re.M)
NDIST = min(60, len(keys))           # 被引去重条目数(参考表 full:false 即列这些)
para = ("本节回顾相关研究进展并讨论其在国标著录场景下的适用性。已有工作从数据建模、规范对齐与"
        "排版实现等多个角度展开探讨，为后续分析奠定基础；综合来看各方法各有侧重，值得统一比较。")
def body():
    out, n = [], 0
    for sec in range(1, 9):          # 8 章
        out.append(f"= 第 {sec} 章 相关工作\n")
        for sub in range(1, 4):      # 每章 3 节
            out.append(f"== {sec}.{sub} 小节\n")
            for _ in range(2):       # 每节 2 段、每段 2 引用(部分复用,贴近真实)
                k1 = keys[n % NDIST]; k2 = keys[(n + 1) % NDIST]; n += 2
                out.append(para + f'#cite(label("{k1}"))#cite(label("{k2}"))。\n')
    return "\n".join(out)
B = body()
omni = ('// 自动生成:真实论文场景(正文 + 散落 #cite + 文末参考表)的 omni 驱动。\n'
        '#import "/lib.typ": *\n#show: gb7714()\n\n' + B
        + '\n\n= 参考文献\n#bibliography(read("/refs.bib"), title: none, full: false)\n')
hay = ('// 自动生成:同正文的原生 Hayagriva 对照驱动(gb-7714-2015-numeric)。\n' + B
       + '\n\n= 参考文献\n#bibliography("/refs.bib", title: none, style: "gb-7714-2015-numeric", full: false)\n')
open(os.path.join(base, 'main-omni.typ'), 'w').write(omni)
open(os.path.join(base, 'main-hayagriva.typ'), 'w').write(hay)
print('[build.sh] → benchmark/main-{omni,hayagriva}.typ (真实文档:8章 %d引用/%d条目)' % (8*3*2*2, NDIST))
PY
  echo "[build.sh] → $OUT_DIR/index.html"
  echo "[build.sh] → $OUT_DIR/style.css"
  echo "[build.sh] → $OUT_DIR/site.js"
  echo "[build.sh] → $OUT_DIR/benchmark.js"
  echo "[build.sh] → $OUT_DIR/brand-icon.png"
  echo "[build.sh] → $OUT_DIR/benchmark/{lib.typ,src/,citegeist/lib.typ+wasm,refs.bib,main-*.typ}"
}

case "${1:-all}" in
  pdf)  build_pdf ;;
  html) build_html ;;
  all)  build_pdf; build_html ;;
  *)    echo "Usage: $0 [pdf|html|all]"; exit 1 ;;
esac

echo "[build.sh] done."
