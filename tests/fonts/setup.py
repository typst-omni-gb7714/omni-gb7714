#!/usr/bin/env python3
"""下载并核对固定版本的测试字体；不安装系统字体。"""
import argparse
import hashlib
from pathlib import Path
import sys
import urllib.request

HERE = Path(__file__).resolve().parent
COMMIT = '523d033d6cb47f4a80c58a35753646f5c3608a78'  # noto-cjk Sans2.004
BASE = f'https://raw.githubusercontent.com/notofonts/noto-cjk/{COMMIT}'
FILES = {
    'NotoSansCJKsc-Regular.otf': ('Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf', 'dc15562470b4f842321894787a0d066879ccff8b'),
    'NotoSansCJKsc-Bold.otf': ('Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Bold.otf', 'ff4c0450e8a5bf0290fbb6013a72dc61a10e8e56'),
    'LICENSE': ('LICENSE', 'd952d62c065f3f35fb83a173496e90b21525aef3'),
}


def valid(data, expected):
    # 与固定 commit 的 Git blob 一致，而非只比较字体名称或版本号。
    return hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest() == expected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='只检查本地文件，不联网')
    args = parser.parse_args()
    for name, (relative, expected) in FILES.items():
        path = HERE / name
        if path.exists():
            if not valid(path.read_bytes(), expected):
                sys.exit(f'测试字体文件与固定版本不一致：{path}；请检查后移走该文件，再重新运行 setup.py')
            continue
        if args.check:
            sys.exit(f'缺少测试字体：{name}；请运行 python3 "{HERE / "setup.py"}"')
        print(f'下载 {name}', flush=True)
        with urllib.request.urlopen(BASE + '/' + relative, timeout=90) as response:
            data = response.read()
        if not valid(data, expected):
            sys.exit(f'下载校验失败：{name}')
        path.write_bytes(data)
    if not args.check:
        print('测试字体已固定为 Noto Sans CJK SC 2.004（Regular／Bold）')


if __name__ == '__main__':
    main()
