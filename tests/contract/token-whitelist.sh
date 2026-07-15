#!/usr/bin/env bash
# 模板 token 白名单的双向对齐：`fields/built-in.typ` 里
#   ① 白名单 `built-in-token-names`（模板引擎先查它，再派发）
#   ② `resolve-built-in-token` 里实际处理的分支名（`name == "x"` / `name in ("x", ..)`）
# 必须互相盖满。
#
# 这道检查是被一个真 bug 逼出来的：`location` 分支写了、白名单忘了登记，于是那条分支*永远走不到*，
# 手册里写着能用的 token 一写就报「未知 token」。文件里本来就有一行注释写着这条不变量
# （「在 resolve-built-in-token 里增删 if name == ... 分支时，必须同步更新这份集合」）——
# 注释靠人记，检查靠机器。
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$ROOT" <<'PY'
import re, sys
root = sys.argv[1]
s = open(f'{root}/src/fields/built-in.typ').read()
m = re.search(r'#let built-in-token-names = \((.*?)\n\)', s, re.S)
if not m:
    print("FAIL: 找不到 built-in-token-names 白名单（改名了？）"); sys.exit(1)
declared = set(re.findall(r'"([a-z0-9-]+)"', m.group(1)))
body = s[m.end():]
handled = set(re.findall(r'name == "([a-z0-9-]+)"', body))
for g in re.findall(r'name in \(([^)]*)\)', body):
    handled |= set(re.findall(r'"([a-z0-9-]+)"', g))
KNOWN_BROKEN = {}   # 空的：漏网全修完了。再有新的漏网直接报红。

ghost = sorted(handled - declared)   # 有分支、没登记 → 分支是死代码，token 一写就 panic
dead  = sorted(declared - handled)   # 登记了、没分支 → 落到兜底，多半不是本意
for t in list(ghost):
    if t in KNOWN_BROKEN:
        print(f"  ⚠️  {t}：{KNOWN_BROKEN[t]}")
        ghost.remove(t)
fail = 0
if ghost:
    print("FAIL: 这些 token 有处理分支、但白名单没登记（分支永远走不到，用户一写就报「未知 token」）：")
    for t in ghost: print(f"  - {t}")
    fail = 1
if dead:
    print("FAIL: 这些 token 登记在白名单里、但没有处理分支（会落到兜底）：")
    for t in dead: print(f"  - {t}")
    fail = 1
if not fail:
    n_known = len(KNOWN_BROKEN)
    tail = f"（{len(declared)} 个；另有 {n_known} 个已记账未修）" if n_known else f"（{len(declared)} 个）"
    print(f"  ✅ 模板 token 白名单与处理分支双向对齐{tail}")
sys.exit(fail)
PY
