#!/usr/bin/env python3
"""打发布版包：把源码剥成发布形态，写进 omni-gb7714/preview/<version>/，再跑四道验收闸。

用法：
    python3 scripts/make-preview.py            # 版本取 typst.toml，写盘
    python3 scripts/make-preview.py --install  # 写盘并同步到 @local（常用：一步到位，不会再拿到旧引擎）
    python3 scripts/make-preview.py 0.2.0      # 指定版本（同时改写产物里的 typst.toml）
    python3 scripts/make-preview.py --check    # 只验，不写盘、不装（给 verify-all 用）

`@local` 里的包是拷贝不是软链，源码一迭代它就旧了——旧到拿它编译会撞上「未知参数」。所以不加
`--install` 时，脚本会主动比对并提醒。

设计要点：脚本不认识任何具体的文件名或目录名，全靠三条推导——
  · 包含哪些文件：从 typst.toml 的 entrypoint 出发**走 import 图**，顺带收 plugin()/read() 的资源。
    src/ 结构将来怎么改、加几层、换名字，都不用动这个脚本。
  · 哪个文件是「暴露给用户的入口」：typst.toml 的 entrypoint 说了算。
  · 哪个文件是「手册的文档源」：扫手册模板里的 read()，落在包内的 .typ 就是。手册将来改从别处抽，
    脚本跟着变。
"""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from importlib import import_module

strip_mod = import_module("strip-comments")

ROOT = Path(__file__).resolve().parent.parent
MANUAL_DIR = ROOT / "easy-zh-manual"

# 包里除了 import 图能走到的 .typ 之外，还要带上的东西（有就带，没有就跳过并提醒）。
# quan/LICENSE：包内暂存的 quan 0.3.0 副本（MIT 要求随副本附带版权声明）；上架后删掉 quan/ 时一并去掉
EXTRA_FILES = ["README.md", "LICENSE", "NOTICE", "quan/LICENSE", "citegeist/LICENSE"]


def local_package_dir(name, version):
    """typst 的本地包目录（`@local/<name>:<version>` 从这里读）。"""
    if sys.platform == "darwin":
        base = Path.home() / "Library/Application Support/typst/packages/local"
    elif sys.platform.startswith("win"):
        base = Path.home() / "AppData/Roaming/typst/packages/local"
    else:
        base = Path.home() / ".local/share/typst/packages/local"
    return base / name / version


def same_tree(a, b):
    if not b.exists():
        return False
    fa = {f.relative_to(a) for f in a.rglob("*") if f.is_file()}
    fb = {f.relative_to(b) for f in b.rglob("*") if f.is_file()}
    if fa != fb:
        return False
    return all((a / r).read_bytes() == (b / r).read_bytes() for r in fa)

IMPORT_RE = re.compile(r'#?(?:import|include)\s+"([^"]+)"')
ASSET_RE = re.compile(r'(?:plugin|read)\s*\(\s*"([^"]+)"')


def code_only(src):
    """只留代码段——注释里的示例（doc 注释里的 `read("refs.bib")`）不是真依赖，别当成包文件收进来。"""
    return "\n".join(src[s:e] for kind, s, e in strip_mod.scan(src) if kind == "code")


def parse_manifest():
    text = (ROOT / "typst.toml").read_text(encoding="utf-8")

    def field(key):
        m = re.search(rf'^{key}\s*=\s*"([^"]*)"', text, re.M)
        if m is None:
            sys.exit(f"typst.toml 缺 {key}")
        return m.group(1)

    return field("name"), field("version"), field("entrypoint")


def resolve(spec, from_file):
    """把 import / read 的路径解析成仓库内的绝对路径；外部包与仓库外的路径返回 None。"""
    if spec.startswith("@"):
        return None
    target = (ROOT / spec.lstrip("/")) if spec.startswith("/") else (from_file.parent / spec)
    try:
        target = target.resolve()
        target.relative_to(ROOT)
    except (OSError, ValueError):
        return None
    return target if target.exists() else None


def walk_imports(entry):
    """从入口出发走 import 图，返回 (typ 文件集合, 资源文件集合)。"""
    typs, assets, queue = set(), set(), [entry]
    while queue:
        cur = queue.pop()
        if cur in typs:
            continue
        typs.add(cur)
        src = code_only(cur.read_text(encoding="utf-8"))
        for spec in IMPORT_RE.findall(src):
            target = resolve(spec, cur)
            if target is not None and target.suffix == ".typ":
                queue.append(target)
        for spec in ASSET_RE.findall(src):
            target = resolve(spec, cur)
            if target is not None and target.suffix != ".typ":
                assets.add(target)
    return typs, assets


def find_doc_sources(package_typs):
    """手册用 read() 读的包内 .typ 就是文档源——它的 doc-comment 要留给手册抽取。"""
    doc_sources = set()
    if not MANUAL_DIR.exists():
        return doc_sources
    for f in MANUAL_DIR.rglob("*.typ"):
        for spec in ASSET_RE.findall(code_only(f.read_text(encoding="utf-8"))):
            target = resolve(spec, f)
            if target is not None and target in package_typs:
                doc_sources.add(target)
    return doc_sources


def build(dest, version, entry, typs, assets, doc_sources):
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)

    for f in sorted(typs):
        rel = f.relative_to(ROOT)
        mode = "entrypoint" if f == entry else ("doc-source" if f in doc_sources else "internal")
        out = dest / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(strip_mod.strip(f.read_text(encoding="utf-8"), mode), encoding="utf-8")

    for f in sorted(assets):
        out = dest / f.relative_to(ROOT)
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, out)

    # typst.toml：版本号按参数改写，其余原样。
    manifest = (ROOT / "typst.toml").read_text(encoding="utf-8")
    manifest = re.sub(r'^version\s*=\s*"[^"]*"', f'version = "{version}"', manifest, count=1, flags=re.M)
    (dest / "typst.toml").write_text(manifest, encoding="utf-8")

    missing = []
    for name in EXTRA_FILES:
        src = ROOT / name
        if src.exists():
            (dest / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest / name)
        else:
            missing.append(name)
    return missing


# ---- 验收闸 ---------------------------------------------------------------------


def gate_syntax(dest, entry_rel):
    """闸一：剥完的包还能编译。"""
    with tempfile.TemporaryDirectory() as tmp:
        smoke = dest / "_smoke.typ"
        smoke.write_text(
            f'#import "/{entry_rel}": *\n#show: gb7714\n'
            '#bibliography(bytes("@book{a, author={Li, M.}, title={T}, publisher={P}, '
            'address={NY}, year={2020}}"), full: true)\n',
            encoding="utf-8",
        )
        r = subprocess.run(
            ["typst", "compile", "--root", str(dest), str(smoke), f"{tmp}/s.pdf"],
            capture_output=True, text=True,
        )
        smoke.unlink()
    if r.returncode != 0:
        return f"剥完的包编译失败：\n{r.stderr[:400]}"
    return None


def gate_equivalence(dest):
    """闸二（核心）：拿剥完的包跑整套矩阵，必须与 golden 0 差异。

    做法：把仓库整棵树复制到临时目录，用剥完的 lib.typ / src 覆盖进去，再在那棵树里跑
    tests/matrix/run.sh——它自己会 cd 到那棵树，于是比对的是「剥完的包 vs 源码包的 golden」。
    剥注释一旦动到代码，矩阵 golden 就会报出差异。
    """
    gold = ROOT / "tests/matrix/_golden"
    if not gold.exists():
        return "缺矩阵 golden（先跑 bash tests/matrix/run.sh --update），等价闸无法执行"
    with tempfile.TemporaryDirectory() as tmp:
        tree = Path(tmp) / "tree"
        subprocess.run(
            ["rsync", "-a",
             "--exclude=.git", "--exclude=omni-gb7714", "--exclude=csl2omni", "--exclude=reports",
             "--exclude=citegeist/plugin/citegeist/plugin/target",
             f"{ROOT}/", f"{tree}/"],
            check=True, capture_output=True,
        )
        for rel in ("lib.typ", "src"):
            target = tree / rel
            if target.is_dir():
                shutil.rmtree(target)
            elif target.exists():
                target.unlink()
            source = dest / rel
            if source.is_dir():
                shutil.copytree(source, target)
            else:
                shutil.copy2(source, target)
        r = subprocess.run(
            ["bash", str(tree / "tests/matrix/run.sh")],
            capture_output=True, text=True, errors="replace",
        )
    tail = (r.stdout + r.stderr).strip().splitlines()
    if r.returncode != 0:
        return "剥完的包输出与 golden 不一致（说明剥注释动到了代码）：\n" + "\n".join(tail[-10:])
    return None


def gate_retention(dest, entry, typs, doc_sources):
    """闸三：该留的都在，不该留的一个不剩。"""
    problems = []
    for component in ("quan", "citegeist"):
        if any(f.relative_to(ROOT).parts[0] == component for f in typs):
            license_file = Path(component) / "LICENSE"
            if not (dest / license_file).is_file():
                problems.append(f"随包依赖缺许可证：{license_file}")

    entry_out = (dest / entry.relative_to(ROOT)).read_text(encoding="utf-8")
    src_public = [
        m.group(2) for m in strip_mod.LET_RE.finditer(entry.read_text(encoding="utf-8"))
        if m.group(1) == "" and not m.group(2).startswith("_")
    ]
    for name in src_public:
        if not re.search(rf"(?:^|\n)#?let\s+{re.escape(name)}\(", entry_out):
            problems.append(f"入口丢了公开函数 {name}")
    if "///" not in entry_out:
        problems.append("入口一条 /// 都不剩，LSP 悬停会没有参数说明")

    for f in sorted(doc_sources):
        src, out = f.read_text(encoding="utf-8"), (dest / f.relative_to(ROOT)).read_text(encoding="utf-8")
        want, got = src.count("/**"), out.count("/**")
        if want != got:
            problems.append(f"{f.relative_to(ROOT)} 的手册文档块丢了：源 {want} 个，产物 {got} 个")
        # 手册的抽取算法：`/** **/` 块必须紧贴在 `let 名字(` 上方，中间只有空白。
        for m in re.finditer(r"\*\*/", out):
            rest = out[m.end():]
            if re.match(r"\s*#?let\s+[A-Za-z0-9_\-]+\(", rest) is None:
                problems.append(f"{f.relative_to(ROOT)} 有文档块没紧贴 let，手册会抽不到")

    # 内部文件：注释一个不剩。
    for f in sorted(typs):
        if f == entry or f in doc_sources:
            continue
        out = (dest / f.relative_to(ROOT)).read_text(encoding="utf-8")
        left = [k for k, _s, _e in strip_mod.scan(out) if k != "code"]
        if left:
            problems.append(f"{f.relative_to(ROOT)} 还剩 {len(left)} 处注释没剥干净")

    return "\n".join(problems) if problems else None


def gate_idempotent(dest, entry, typs, doc_sources):
    """闸四：剥两遍与剥一遍逐字节相同（剥注释器自己是稳定的）。"""
    for f in sorted(typs):
        mode = "entrypoint" if f == entry else ("doc-source" if f in doc_sources else "internal")
        once = (dest / f.relative_to(ROOT)).read_text(encoding="utf-8")
        if strip_mod.strip(once, mode) != once:
            return f"{f.relative_to(ROOT)} 剥两遍与剥一遍不同，剥注释器不稳定"
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("version", nargs="?", help="版本号，缺省取 typst.toml")
    ap.add_argument("--check", action="store_true", help="只验不写盘")
    ap.add_argument("--install", action="store_true", help="过闸后把产物同步到 @local/<name>:<version>")
    args = ap.parse_args()

    name, manifest_version, entrypoint = parse_manifest()
    version = args.version or manifest_version
    entry = ROOT / entrypoint

    typs, assets = walk_imports(entry)
    doc_sources = find_doc_sources(typs)

    print(f"包 {name} 版本 {version}")
    print(f"  入口     {entrypoint}")
    print(f"  .typ     {len(typs)} 个（走 import 图收到）")
    print(f"  资源     {len(assets)} 个" + (f"：{', '.join(str(a.relative_to(ROOT)) for a in sorted(assets))}" if assets else ""))
    print(f"  手册源   {', '.join(str(d.relative_to(ROOT)) for d in sorted(doc_sources)) or '（无）'}")

    tmpdir = tempfile.mkdtemp() if args.check else None
    dest = Path(tmpdir) / version if args.check else ROOT / name / "preview" / version

    missing = build(dest, version, entry, typs, assets, doc_sources)
    src_bytes = sum(f.stat().st_size for f in typs)
    out_bytes = sum(f.stat().st_size for f in dest.rglob("*.typ"))
    print(f"  产物     {dest.relative_to(ROOT) if not args.check else '（临时目录，--check 不写盘）'}")
    print(f"  瘦身     {src_bytes // 1024} KB → {out_bytes // 1024} KB（剥掉 {100 - out_bytes * 100 // max(src_bytes, 1)}%）")
    if missing:
        print(f"  ⚠️  缺文件：{', '.join(missing)}（Typst Universe 要求包里必须有 LICENSE）")

    print()
    failed = False
    for label, gate in (
        ("闸一 语法：剥完的包能编译", lambda: gate_syntax(dest, entrypoint)),
        ("闸二 等价：矩阵 golden 0 差异", lambda: gate_equivalence(dest)),
        ("闸三 保留：该留的都在、其余不剩", lambda: gate_retention(dest, entry, typs, doc_sources)),
        ("闸四 幂等：剥两遍与一遍相同", lambda: gate_idempotent(dest, entry, typs, doc_sources)),
    ):
        err = gate()
        if err is None:
            print(f"  ✅ {label}")
        else:
            print(f"  ❌ {label}\n     {err}")
            failed = True

    print()
    if failed:
        if tmpdir:
            shutil.rmtree(tmpdir, ignore_errors=True)
        print("❌ 发布版打包未通过")
        return 1

    # `@local` 里的那份是拷贝不是软链，源码一迭代它就旧了——旧到用户拿它编译会撞上「未知参数」。
    #   `--install` 一步同步；没加就至少提醒一句，别让人再踩一次。
    if not args.check:
        installed = local_package_dir(name, version)
        if args.install:
            if installed.exists():
                shutil.rmtree(installed)
            installed.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(dest, installed)
            print(f"📦 已同步到 @local/{name}:{version}")
        elif not same_tree(dest, installed):
            state = "内容已过时" if installed.exists() else "尚未安装"
            print(f"⚠️  @local/{name}:{version} {state}——加 --install 同步，否则拿它编译的文档会用到旧引擎")

    if tmpdir:
        shutil.rmtree(tmpdir, ignore_errors=True)
    print("✅ 发布版打包通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
