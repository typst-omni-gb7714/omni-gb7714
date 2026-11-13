#!/usr/bin/env python3
"""把一个 Typst 源文件剥成发布形态：去掉实现注释，只留用户看得见的那些。

保留判据是结构性的，不认任何具体文件名或函数名——src/ 结构将来怎么变都不用改这个脚本：

  entrypoint（typst.toml 的 entrypoint 指的那个文件）
      顶层非下划线 `#let 名字(` 的**参数表内**的 `///` 全留（LSP 悬停靠它），
      紧贴在这种 `#let` 上方的 `///` 文档块也留。

  doc-source（手册用 read() 读的包内 .typ）
      `/** ... **/` 块 + 紧跟其后的 `let 名字(` 全留——手册的抽取算法就是这么找的
      （easy-zh-manual/src/lib.typ 的 extract-function-doc），所以「有没有 /** **/ 块」
      本身就是「这个函数进不进手册」的标记。该函数参数表内的 `///` 一并留。

  其余文件
      注释一个不留。

剥的时候必须认 Typst 的词法，不能用正则：代码里有字面 `"//"`（析出文献的分隔符）、
`regex("https?://…")` 这类串，正则一剥就把代码剁了。
"""

import re
import sys

# ---- 词法扫描：把源码切成 (kind, start, end) 段 ----------------------------------
# kind: "code" | "line-comment" | "doc-comment" | "block-comment"
# 字符串与 raw 块内的 `//` `/*` 不是注释，扫描器必须跳过它们。


def scan(src):
    spans = []
    i, n = 0, len(src)
    code_start = 0

    def flush_code(end):
        if end > code_start:
            spans.append(("code", code_start, end))

    while i < n:
        c = src[i]
        # 字符串字面量：反斜杠转义下一个字符。
        if c == '"':
            i += 1
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        # raw 块：单反引号或三反引号（更多也照收），以同长度的反引号收尾。
        if c == "`":
            ticks = 0
            while i + ticks < n and src[i + ticks] == "`":
                ticks += 1
            fence = "`" * ticks
            j = src.find(fence, i + ticks)
            i = n if j == -1 else j + ticks
            continue
        # 行注释：`///` 是文档注释，单独归类。
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            flush_code(i)
            is_doc = i + 2 < n and src[i + 2] == "/"
            j = src.find("\n", i)
            j = n if j == -1 else j
            spans.append(("doc-comment" if is_doc else "line-comment", i, j))
            i = code_start = j
            continue
        # 块注释：Typst 的块注释可嵌套。
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            flush_code(i)
            depth, j = 1, i + 2
            while j < n and depth > 0:
                if src.startswith("/*", j):
                    depth += 1
                    j += 2
                elif src.startswith("*/", j):
                    depth -= 1
                    j += 2
                else:
                    j += 1
            spans.append(("block-comment", i, j))
            i = code_start = j
            continue
        i += 1
    flush_code(n)
    return spans


# ---- 保留区的计算 ---------------------------------------------------------------

# `let 名字(`：容忍前导空白与可选的 `#`，与手册 extract-function-doc 的正则同形。
LET_RE = re.compile(r"(?:^|\n)([ \t]*)#?let[ \t]+([A-Za-z0-9_\-]+)\(")


def param_span(src, open_paren):
    """从参数表的左括号扫到配对的右括号，返回 (start, end)。括号计数要避开字符串与注释。"""
    depth, i, n = 0, open_paren, len(src)
    while i < n:
        c = src[i]
        if c == '"':
            i += 1
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            i = n if j == -1 else j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            depth_b, j = 1, i + 2
            while j < n and depth_b > 0:
                if src.startswith("/*", j):
                    depth_b += 1
                    j += 2
                elif src.startswith("*/", j):
                    depth_b -= 1
                    j += 2
                else:
                    j += 1
            i = j
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return (open_paren, i + 1)
        i += 1
    return (open_paren, n)


def preceding_doc_block(src, spans, let_start):
    """紧贴在 `let` 上方（中间只有空白）的 `///` 连续块，返回它的 (start, end)；没有则 None。"""
    docs = [s for s in spans if s[0] == "doc-comment" and s[2] <= let_start]
    if not docs:
        return None
    if src[docs[-1][2]:let_start].strip() != "":
        return None
    end = docs[-1][2]
    start = docs[-1][1]
    # 向上并拢连续的 `///` 行。
    for kind, s, e in reversed(docs[:-1]):
        if src[e:start].strip() != "":
            break
        start = s
    return (start, end)


def keep_regions(src, spans, mode):
    """返回 (keep_spans, keep_param_ranges)。前者是整段保留的注释，后者是「其中的 /// 要留」的区间。"""
    keep_spans = []
    keep_params = []

    if mode == "internal":
        return keep_spans, keep_params

    blocks = [s for s in spans if s[0] == "block-comment" and src[s[1]:s[1] + 3] == "/**"]

    for m in LET_RE.finditer(src):
        indent, name = m.group(1), m.group(2)
        let_start = m.start() + (0 if m.start() == 0 else 1)
        open_paren = m.end() - 1

        documented = False
        if mode == "doc-source":
            # 手册的判据：`/** **/` 块紧贴在 let 上方（中间只有空白）。有它就是进手册的函数。
            for _kind, bs, be in blocks:
                if be <= let_start and src[be:let_start].strip() == "":
                    keep_spans.append((bs, be))
                    documented = True
                    break
        if mode == "entrypoint":
            # 入口的判据：顶层（无缩进）且非下划线的公开绑定。
            documented = indent == "" and not name.startswith("_")

        if not documented:
            continue

        keep_params.append(param_span(src, open_paren))
        doc = preceding_doc_block(src, spans, let_start)
        if doc is not None:
            keep_spans.append(doc)

    return keep_spans, keep_params


# ---- 剥离 -----------------------------------------------------------------------


def strip(src, mode):
    spans = scan(src)
    keep_spans, keep_params = keep_regions(src, spans, mode)

    def kept(kind, s, e):
        # 落在保留区里就留。这里要的是*包含*不是相等：函数级文档块是一串 `///` 行，
        #   `preceding_doc_block` 给的是并拢后的整段区间，而 `spans` 里是逐行的注释段——
        #   按相等比对会一个都对不上（`/** **/` 恰好是单段，所以曾侥幸没暴露）。
        if any(ks <= s and e <= ke for ks, ke in keep_spans):
            return True
        # 保留函数参数表内的文档注释——参数说明就靠它。
        if kind == "doc-comment":
            return any(ps <= s < pe for ps, pe in keep_params)
        return False

    out, cursor = [], 0
    for kind, s, e in spans:
        if kind == "code":
            continue
        if kept(kind, s, e):
            continue
        out.append(src[cursor:s])
        cursor = e
    out.append(src[cursor:])
    text = "".join(out)

    # 收拾：剥空的行整行丢掉，连续空行压成一个，末尾留一个换行。
    lines = [ln for ln in text.split("\n")]
    cleaned, blank = [], False
    for ln in lines:
        if ln.strip() == "":
            if not blank and cleaned:
                cleaned.append("")
            blank = True
        else:
            cleaned.append(ln.rstrip())
            blank = False
    while cleaned and cleaned[-1] == "":
        cleaned.pop()
    return "\n".join(cleaned) + "\n"


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in ("entrypoint", "doc-source", "internal"):
        print("用法: strip-comments.py <file.typ> entrypoint|doc-source|internal", file=sys.stderr)
        return 2
    with open(sys.argv[1], encoding="utf-8") as f:
        src = f.read()
    sys.stdout.write(strip(src, sys.argv[2]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
