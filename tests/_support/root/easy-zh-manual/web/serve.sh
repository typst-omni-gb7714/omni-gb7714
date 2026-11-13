#!/usr/bin/env bash
# Rebuild HTML, restart no-cache local HTTP server, and open the browser.
#
# Usage:
#   bash easy-zh-manual/web/serve.sh                      # default port 8000, root page
#   bash easy-zh-manual/web/serve.sh loc-2                # open #loc-2 (1 概述)
#   bash easy-zh-manual/web/serve.sh '#perf-section'      # # is also accepted
#   bash easy-zh-manual/web/serve.sh chapter-3 9000       # custom hash + port
#   bash easy-zh-manual/web/serve.sh --no-build           # skip rebuild
#
# Stop server: lsof -ti:8000 | xargs kill
set -euo pipefail

NO_BUILD=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --no-build) NO_BUILD=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) ARGS+=("$arg") ;;
  esac
done

HASH="${ARGS[0]:-}"
PORT="${ARGS[1]:-8000}"
if [[ -n "$HASH" && "${HASH:0:1}" != "#" ]]; then HASH="#$HASH"; fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIST="$ROOT/easy-zh-manual/web/dist"

if [[ "$NO_BUILD" -eq 0 ]]; then
  echo "[serve.sh] rebuilding HTML..."
  if ! bash "$ROOT/easy-zh-manual/web/build.sh" html; then
    echo "[serve.sh] build failed; aborting." >&2
    exit 1
  fi
fi

echo "[serve.sh] freeing port $PORT (if in use)..."
PIDS="$(lsof -ti:"$PORT" 2>/dev/null || true)"
if [[ -n "$PIDS" ]]; then
  echo "$PIDS" | xargs kill 2>/dev/null || true
  sleep 0.3
fi

echo "[serve.sh] starting no-cache HTTP server on $PORT..."
# ThreadingHTTPServer（非单线程 HTTPServer）：基准页一次并发拉 ~27 个文件（lib.typ + 23 src
#   + citegeist/lib.typ + 275KB wasm + refs.bib + 2 main），单线程服务器会被压垮、随机 reset
#   连接 → 浏览器报 "Load failed"。多线程后每个连接独立处理，不再丢。
(cd "$DIST" && python3 -c "
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
class H(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        super().end_headers()
    def log_message(self, fmt, *args):
        pass
ThreadingHTTPServer(('', $PORT), H).serve_forever()
" >/dev/null 2>&1 &)

sleep 0.4

URL="http://localhost:$PORT/?$(date +%s)$HASH"
echo "[serve.sh] opening $URL"
open "$URL" 2>/dev/null || echo "(open failed, please paste the URL above into your browser)"
echo "[serve.sh] done. To stop: lsof -ti:$PORT | xargs kill"
