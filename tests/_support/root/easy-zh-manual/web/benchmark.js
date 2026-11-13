// 浏览器内 WASM 性能基准。仅在用户点击"在你的设备上重测"按钮后被动态 import，
// 不影响首屏。依赖 @myriaddreamin/typst.ts 的 snippet API + 同目录的
// benchmark/{manifest.json, lib.typ, src/*.typ, refs.bib, main-omni.typ, main-hayagriva.typ}

// 用 all-in-one-lite.bundle.js（vite 预打包，已内联依赖、无 bare specifier），
// 直接走 contrib/snippet.mjs 在浏览器里会触发 `await import('@myriaddreamin/typst.ts/...')`
// 这种裸模块说明符浏览器无法解析。
const TYPST_TS_BUNDLE = 'https://cdn.jsdelivr.net/npm/@myriaddreamin/typst.ts/dist/esm/contrib/all-in-one-lite.bundle.js';
const COMPILER_WASM   = 'https://cdn.jsdelivr.net/npm/@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm';
const RENDERER_WASM   = 'https://cdn.jsdelivr.net/npm/@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm';

let _typst = null;
let _compiler = null;
let _omniSrc = '';
let _haySrc = '';
let _loaded = null;

// 取一个 benchmark 资源，失败时把**出错的 URL**点名报出来（否则 Safari 只丢一句不知所云的
//   "Load failed" / Chrome 的 "Failed to fetch"）。`cache:'reload'` 绕开 HTTP 缓存防喂旧文件。
//   常见网络层失败：用 file:// 直开页面（fetch 在 file:// 下一律失败）→ 提示改用 serve.sh 经 HTTP 访问。
async function grab(url, kind, retry = 1) {
  let r;
  try {
    r = await fetch(url, { cache: 'reload' });
  } catch (e) {
    // 网络层失败（含单线程服务器并发压垮时的连接 reset）→ 退避后重试一次，仍失败才点名抛出。
    if (retry > 0) {
      await new Promise((res) => setTimeout(res, 200));
      return grab(url, kind, retry - 1);
    }
    throw new Error('网络请求失败：' + url + '（' + ((e && e.message) || e) + '）。'
      + '若是用 file:// 直接打开了页面，请改用 web/serve.sh 经 HTTP 访问。');
  }
  if (!r.ok) throw new Error('资源加载失败：' + url + '（HTTP ' + r.status + '）');
  return kind === 'json' ? r.json() : kind === 'bin' ? r.arrayBuffer() : r.text();
}

// 限并发 map：维持至多 `limit` 个在途请求并保序返回。Safari 对「同一 tick 一次性 fetch 几十个文件」
//   会偶发 "Load failed"（连接被丢），限并发=6（≈ 浏览器单 host 连接预算）+ grab 重试可根治。
async function mapLimit(items, limit, fn) {
  const out = new Array(items.length);
  let next = 0;
  async function worker() {
    while (next < items.length) {
      const i = next++;
      out[i] = await fn(items[i], i);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return out;
}

async function init() {
  if (_typst && _compiler) return { $typst: _typst, compiler: _compiler };
  const mod = await import(TYPST_TS_BUNDLE);
  const $typst = mod.$typst;
  $typst.setCompilerInitOptions({
    getModule: () => COMPILER_WASM,
  });
  // svg() 需要 renderer WASM；不显式配置会抛 "Cannot import wasm module without importer"
  $typst.setRendererInitOptions({
    getModule: () => RENDERER_WASM,
  });
  // 拉取 benchmark 文件清单（lib.typ + 全部 src 模块 + vendored citegeist/lib.typ），逐一挂进 WASM 虚拟 FS。
  //   omni 驱动 `#import "/lib.typ"`，lib.typ 再函数内 `import "src/.."` 与 `/citegeist/lib.typ`，故整棵源码树都要在位；
  //   citegeist 已 vendored（不再 @preview），其 lib.typ 在清单里走 addSource，citegeist.wasm 是二进制单独 mapShadow（见下）；
  //   其余 @preview 依赖（mitex / auto-pinyin / auto-bihua / glotter / jurlstify / quan）由 typst.ts 自动从包 registry 拉取，不在清单里。
  // `cache: 'reload'` 强制绕过 HTTP 缓存重取——否则改了 refs.bib / src / wasm 后浏览器可能仍喂旧文件。
  const manifest = await grab('benchmark/manifest.json', 'json');
  // 把所有资源汇成一张表，**限并发=6** 拉取（不再同 tick 爆发 ~27 个 fetch → 避免 Safari "Load failed"）。
  const jobs = [
    ...manifest.map((p) => ({ url: 'benchmark/' + p, kind: 'text' })),
    { url: 'benchmark/refs.bib', kind: 'text' },
    { url: 'benchmark/main-omni.typ', kind: 'text' },
    { url: 'benchmark/main-hayagriva.typ', kind: 'text' },
    { url: 'benchmark/citegeist/citegeist.wasm', kind: 'bin' },
  ];
  const got = await mapLimit(jobs, 6, (j) => grab(j.url, j.kind));
  // 缓存已 fetch 的字节：reset 后可免重新下载直接重挂（见 mountAll / runBench）。
  _loaded = {
    manifest,
    srcTexts: got.slice(0, manifest.length),
    bib: got[manifest.length],
    omniMain: got[manifest.length + 1],
    hayMain: got[manifest.length + 2],
    citegeistWasm: got[manifest.length + 3],
  };
  await mountAll($typst);
  _omniSrc = _loaded.omniMain;
  _haySrc  = _loaded.hayMain;
  _compiler = await $typst.getCompiler();
  _typst = $typst;
  return { $typst: _typst, compiler: _compiler };
}

// 把全部源文件挂进虚拟 FS（lib.typ + src/* + citegeist/lib.typ 走 addSource，citegeist.wasm
//   是二进制走 mapShadow）。init 首挂、以及每次 reset 后重挂都调它——addSource/mapShadow 幂等，
//   重挂只是 JS→wasm 内存写、无网络开销。reset 是否清 shadow 不确定，重挂保证万无一失。
async function mountAll($typst) {
  const { manifest, srcTexts, bib, citegeistWasm } = _loaded;
  for (let i = 0; i < manifest.length; i++) {
    await $typst.addSource('/' + manifest[i], srcTexts[i]);
  }
  await $typst.mapShadow('/citegeist/citegeist.wasm', new Uint8Array(citegeistWasm));
  await $typst.addSource('/refs.bib', bib);
}

// 【冷编译 = 构建口径】reset 清增量缓存 + 重挂源，再计时*一次完整编译*（parse + 排序 + 消歧 +
//   逐条渲染 + 排版 + 序列化全跑）。这正是 `typst compile` / CI / 导出 PDF / 首次打开预览的样子——
//   用户真正等待的「构建一次要多久」。bib 解析、正文引用处理都在此口径里如实计入（不被 comemo 缓存掉）。
async function timeCold($typst, mainFilePath, baseSrc) {
  await $typst.getCompilerReset();   // 清空 comemo → 下一次编译必为冷
  await mountAll($typst);            // reset 后重挂源（幂等、无网络）
  await $typst.addSource(mainFilePath, baseSrc);
  const t0 = performance.now();
  await $typst.svg({ mainFilePath });
  return performance.now() - t0;
}

// 【增量编辑 = 编辑口径】预热后，在 mainFile 末尾注入随机 #metadata 让 AST 变、强制重编，但*保留*
//   comemo 暖缓存 → bib 解析/条目渲染命中缓存，只重排改动处。这量的是「编辑时改一个字、预览多快刷新」，
//   是最乐观的角落（omni 的正文引用/解析多被缓存掉），与冷编译并列看才完整。
async function timeWarm($typst, mainFilePath, baseSrc, tag) {
  const fresh = baseSrc + '\n\n#metadata("bench-' + tag + '-' + Math.random().toString(36).slice(2) + '")\n';
  await $typst.addSource(mainFilePath, fresh);
  const t0 = performance.now();
  await $typst.svg({ mainFilePath });
  return performance.now() - t0;
}

export async function runBench({ onProgress, nCold = 8, nWarm = 60 } = {}) {
  onProgress?.({ phase: 'init', label: '加载 Typst WASM 编译器…' });
  const { $typst } = await init();
  const yieldFrame = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));

  // ── 冷编译（构建口径）：每次 reset+重挂，交替量 omni / native 的完整编译 ──
  const coldOmni = [], coldHay = [];
  for (let i = 0; i < nCold; i++) {
    onProgress?.({ phase: 'cold-omni', i, n: nCold, label: `冷编译 omni-gb7714  ${i + 1}/${nCold}…` });
    await yieldFrame();
    coldOmni.push(await timeCold($typst, '/main-omni.typ', _omniSrc));
    onProgress?.({ phase: 'cold-hay', i, n: nCold, label: `冷编译 Hayagriva  ${i + 1}/${nCold}…` });
    await yieldFrame();
    coldHay.push(await timeCold($typst, '/main-hayagriva.typ', _haySrc));
  }

  // ── 增量编辑（编辑口径）：预热一次，再循环「改末尾 + 重编」量增量重排 ──
  await $typst.getCompilerReset();
  await mountAll($typst);
  await $typst.addSource('/main-omni.typ', _omniSrc);
  await $typst.addSource('/main-hayagriva.typ', _haySrc);
  await $typst.svg({ mainFilePath: '/main-omni.typ' });
  await $typst.svg({ mainFilePath: '/main-hayagriva.typ' });
  const warmOmni = [], warmHay = [];
  for (let i = 0; i < nWarm; i++) {
    onProgress?.({ phase: 'warm-omni', i, n: nWarm, label: `增量编辑 omni-gb7714  ${i + 1}/${nWarm}…` });
    await yieldFrame();
    warmOmni.push(await timeWarm($typst, '/main-omni.typ', _omniSrc, 'o' + i));
  }
  for (let i = 0; i < nWarm; i++) {
    onProgress?.({ phase: 'warm-hay', i, n: nWarm, label: `增量编辑 Hayagriva  ${i + 1}/${nWarm}…` });
    await yieldFrame();
    warmHay.push(await timeWarm($typst, '/main-hayagriva.typ', _haySrc, 'h' + i));
  }

  return { cold: { omni: coldOmni, hay: coldHay }, warm: { omni: warmOmni, hay: warmHay } };
}

export function statsOf(arr) {
  const sorted = [...arr].sort((a, b) => a - b);
  const mean = arr.reduce((s, v) => s + v, 0) / arr.length;
  const median = sorted[Math.floor(arr.length / 2)];
  const min = sorted[0];
  const max = sorted[sorted.length - 1];
  const variance = arr.reduce((s, v) => s + (v - mean) ** 2, 0) / arr.length;
  const std = Math.sqrt(variance);
  return { mean, median, min, max, std };
}
