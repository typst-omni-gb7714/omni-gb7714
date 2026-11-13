// 站点交互脚本：TOC 折叠 + 滚动同步 + 深浅主题切换
(function () {
  'use strict';

  // ============ 主题切换 ============
  const THEME_KEY = 'manual-theme';
  function applyTheme(t) {
    document.documentElement.dataset.theme = t;
    const btn = document.querySelector('.theme-toggle');
    if (btn) btn.textContent = t === 'dark' ? '☀' : '☾';
  }
  function initTheme() {
    const saved = localStorage.getItem(THEME_KEY);
    const sys = matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    applyTheme(saved || sys);
  }
  function toggleTheme() {
    const cur = document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light';
    const next = cur === 'dark' ? 'light' : 'dark';
    localStorage.setItem(THEME_KEY, next);
    applyTheme(next);
  }
  function injectThemeToggle() {
    const btn = document.createElement('button');
    btn.className = 'theme-toggle';
    btn.setAttribute('aria-label', '切换深浅主题');
    btn.title = '切换深浅主题';
    btn.addEventListener('click', toggleTheme);
    document.body.appendChild(btn);
  }

  // ============ 顶部站点栏（品牌 + 主题切换 + 仓库链接） ============
  function injectTopBar() {
    if (document.querySelector('.site-bar')) return;
    const bar = document.createElement('header');
    bar.className = 'site-bar';
    bar.innerHTML = [
      '<button class="nav-toggle nav-toggle-left" aria-label="打开章节目录" title="章节目录">',
      '  <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M3 6h18v2H3V6zm0 5h18v2H3v-2zm0 5h18v2H3v-2z"/></svg>',
      '</button>',
      '<a class="brand" href="#chapter-1" aria-label="回到首页">',
      '  <img class="brand-mark" src="brand-icon.png" alt="" width="28" height="28">',
      '  <span class="brand-name">omni-gb7714</span>',
      '  <span class="brand-tag">Typst · GB/T 7714 中文参考样式</span>',
      '</a>',
      '<div class="actions">',
      '  <button class="nav-toggle nav-toggle-right" aria-label="打开本页内容" title="本页内容">',
      '    <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M4 6h12v2H4V6zm0 5h12v2H4v-2zm0 5h8v2H4v-2zM18 6h2v2h-2V6zm0 5h2v2h-2v-2zm0 5h2v2h-2v-2z"/></svg>',
      '  </button>',
      '  <a class="repo-link" href="https://github.com/typst-omni-gb7714/omni-gb7714" target="_blank" rel="noopener" title="GitHub 仓库" aria-label="GitHub">',
      '    <svg viewBox="0 0 16 16" width="20" height="20" aria-hidden="true">',
      '      <path fill="currentColor" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/>',
      '    </svg>',
      '  </a>',
      '  <button class="theme-toggle" aria-label="切换深浅主题" title="切换深浅主题"></button>',
      '</div>',
    ].join('\n');
    document.body.insertBefore(bar, document.body.firstChild);
    bar.querySelector('.theme-toggle').addEventListener('click', toggleTheme);

    // 侧栏切换：移动 / 缩放后侧栏隐藏时，点 toggle 把它拉回（带 backdrop）
    const toggleNav = (cls) => () => {
      const opening = !document.body.classList.contains(cls);
      // 互斥：开一个时把另一个关掉
      document.body.classList.remove('show-left-nav', 'show-right-nav');
      if (opening) document.body.classList.add(cls);
    };
    bar.querySelector('.nav-toggle-left').addEventListener('click', toggleNav('show-left-nav'));
    bar.querySelector('.nav-toggle-right').addEventListener('click', toggleNav('show-right-nav'));
    // 点 backdrop / Esc 关闭
    document.addEventListener('click', (e) => {
      if (!document.body.classList.contains('show-left-nav') &&
          !document.body.classList.contains('show-right-nav')) return;
      // 点击发生在 nav-toggle / 已展开的 nav 内 → 不关
      if (e.target.closest('.nav-toggle, .manual-toc, .page-toc-rail')) return;
      document.body.classList.remove('show-left-nav', 'show-right-nav');
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        document.body.classList.remove('show-left-nav', 'show-right-nav');
      }
    });
    // 触发一次 applyTheme 让按钮显示当前图标（initTheme 已设置过 dataset.theme）
    applyTheme(document.documentElement.dataset.theme || 'light');
  }

  // ============ TOC 折叠 ============
  function makeFoldable() {
    const toc = document.querySelector('.manual-toc');
    if (!toc) return;
    // 找出所有有 <ol> 子节的 <li>
    toc.querySelectorAll('li').forEach((li) => {
      const childList = li.querySelector(':scope > ol');
      if (!childList) return;
      li.classList.add('has-children');
      // 在 <div> 之前插入 toggle 按钮
      const head = li.querySelector(':scope > div') || li;
      const tog = document.createElement('span');
      tog.className = 'toc-toggle';
      tog.textContent = '▼';
      tog.setAttribute('aria-label', '折叠 / 展开');
      tog.addEventListener('click', (ev) => {
        ev.stopPropagation();
        ev.preventDefault();
        li.classList.toggle('collapsed');
      });
      head.insertBefore(tog, head.firstChild);
    });

    // 默认折叠到第二级（一级章节展开，更深的折叠）
    toc.querySelectorAll('li.has-children li.has-children').forEach(
      (li) => li.classList.add('collapsed')
    );
  }

  // ============ Scrollspy（高亮当前节）============
  function initScrollSpy() {
    const tocLinks = document.querySelectorAll('.manual-toc a[href^="#"]');
    if (!tocLinks.length) return;
    const map = new Map();
    tocLinks.forEach((a) => {
      const id = a.getAttribute('href').slice(1);
      const target = document.getElementById(id);
      if (target) map.set(target, a);
    });
    if (!map.size) return;
    let active = null;
    const obs = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          const a = map.get(e.target);
          if (!a) return;
          if (e.isIntersecting) {
            if (active) active.classList.remove('toc-current');
            a.classList.add('toc-current');
            active = a;
            // 自动展开父级（如果折叠了）
            let li = a.closest('li');
            while (li) {
              li.classList.remove('collapsed');
              li = li.parentElement && li.parentElement.closest('li');
            }
          }
        });
      },
      { rootMargin: '-30% 0% -60% 0%' }
    );
    map.forEach((_, target) => obs.observe(target));
  }

  // ============ 章节分页：每个顶层 <h1> 视为独立"页面"，hash 路由 ============
  let chapters = [];
  let currentIdx = 0;

  function splitIntoChapters() {
    // 找到正文容器：body 下排除 nav、header、aside、theme-toggle
    const body = document.body;
    const isContent = (n) => {
      if (n.nodeType !== 1) return n.nodeType === 3 && n.textContent.trim() !== '';
      if (n.tagName === 'NAV' || n.tagName === 'HEADER' ||
          n.tagName === 'ASIDE' && n.classList.contains('manual-toc') ||
          n.classList.contains('theme-toggle') ||
          n.classList.contains('manual-header') ||
          n.classList.contains('manual-toc')) return false;
      return true;
    };
    // 找出所有顶层章节起点。Typst HTML：'=' 映射为 <h2>，但通常被 <div id="loc-N"> 包裹
    // （锚点容器）。所以章节起点既可能是 body 下直接的 <h2>，也可能是首子元素为 <h2> 的 <div>。
    const h1s = Array.from(body.children).filter((n) => {
      if (n.tagName === 'H2') return true;
      if (n.tagName === 'DIV') {
        const f = n.firstElementChild;
        return f && f.tagName === 'H2';
      }
      return false;
    });
    if (h1s.length < 2) return;

    h1s.forEach((startNode, i) => {
      const sec = document.createElement('section');
      sec.className = 'chapter';
      sec.dataset.chapter = String(i);
      const id = 'chapter-' + (i + 1);
      sec.id = id;
      const h2 = startNode.tagName === 'H2'
        ? startNode
        : startNode.querySelector('h2');
      // 章节锚点 id（loc-2 / loc-9 ...）：左侧 TOC 链接 href 用的就是这个
      const anchorId = (startNode.tagName === 'DIV' && startNode.id) ? startNode.id : (h2 && h2.id) || '';
      // 收集 startNode 到下一个 startNode 之间的兄弟节点
      const stop = h1s[i + 1] || null;
      let cur = startNode;
      const collected = [];
      while (cur && cur !== stop) {
        const next = cur.nextSibling;
        collected.push(cur);
        cur = next;
      }
      // 挂在 startNode 原位置
      startNode.parentNode.insertBefore(sec, startNode);
      collected.forEach((n) => sec.appendChild(n));
      chapters.push({
        idx: i,
        id,
        anchorId,
        title: h2 ? h2.textContent.trim() : '',
        el: sec,
      });
    });

    // 标记包含 API options 的章节，用于切换时启用 body.has-hanging
    chapters.forEach((ch) => {
      if (ch.el.querySelector('section.option')) {
        ch.el.classList.add('chapter--has-options');
      }
    });

    // 重分布脚注：Typst HTML 默认把所有 footnote 集中到 body 末尾 <section role="doc-endnotes">，
    // 这样章节翻页后非末章看不到自己的 footnote、末章却挂着所有章的。
    // 每个 <li> 按其 backlink href 指向的 noteref 位置，就近搬到对应章节
    redistributeFootnotes();

    // 加 prev / next 导航
    chapters.forEach((ch, i) => {
      const nav = document.createElement('nav');
      nav.className = 'chapter-nav';
      const prev = chapters[i - 1];
      const next = chapters[i + 1];
      if (prev) {
        const a = document.createElement('a');
        a.className = 'prev';
        a.href = '#' + prev.id;
        a.innerHTML = '<span class="dir">← 前一章</span><span class="title">' + escapeHtml(prev.title) + '</span>';
        nav.appendChild(a);
      } else {
        // 占位元素：让"下一章"按钮保持半宽、靠右显示，但不绘制按钮外观
        const span = document.createElement('span');
        span.className = 'spacer';
        nav.appendChild(span);
      }
      if (next) {
        const a = document.createElement('a');
        a.className = 'next';
        a.href = '#' + next.id;
        a.innerHTML = '<span class="dir">下一章 →</span><span class="title">' + escapeHtml(next.title) + '</span>';
        nav.appendChild(a);
      } else {
        const span = document.createElement('span');
        span.className = 'spacer';
        nav.appendChild(span);
      }
      ch.el.appendChild(nav);
    });

    // 监听 hash 切章
    window.addEventListener('hashchange', () => {
      // 优先匹配 chapter-N；否则按嵌套锚点找所属章节
      const h = location.hash.slice(1);
      if (!h) { showChapter(0); return; }
      const found = chapters.findIndex((c) => c.id === h);
      if (found >= 0) { showChapter(found); window.scrollTo(0, 0); return; }
      // 子锚点：找 id=h 的元素，回溯到所属 chapter
      const el = document.getElementById(h);
      if (el) {
        const parentCh = el.closest('.chapter');
        if (parentCh) {
          const idx = parseInt(parentCh.dataset.chapter, 10);
          showChapter(idx);
          // 让浏览器原生跳转到目标
          el.scrollIntoView();
        }
      }
    });
  }

  function escapeHtml(s) {
    return s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
  }

  // 把 Typst HTML 末尾 <section role="doc-endnotes"> 里的脚注 <li> 按其 backlink
  // 所指 noteref 的位置，分发到各自所属章节末尾（chapter-nav 之前）
  function redistributeFootnotes() {
    const endnotes = document.querySelector('section[role="doc-endnotes"]');
    if (!endnotes) return;
    const lis = Array.from(endnotes.querySelectorAll(':scope > ol > li'));
    for (const li of lis) {
      const backlink = li.querySelector('a[role="doc-backlink"]');
      if (!backlink) continue;
      const href = backlink.getAttribute('href') || '';
      const targetId = href.startsWith('#') ? href.slice(1) : '';
      if (!targetId) continue;
      const target = document.getElementById(targetId);
      if (!target) continue;
      const chapter = target.closest('section.chapter');
      if (!chapter) continue;
      // 找/建当前章节的脚注容器
      let cfn = chapter.querySelector(':scope > section.chapter-footnotes');
      if (!cfn) {
        cfn = document.createElement('section');
        cfn.className = 'chapter-footnotes';
        cfn.setAttribute('role', 'doc-endnotes');
        const ol = document.createElement('ol');
        cfn.appendChild(ol);
        // 插到章节末尾的 chapter-nav 之前；没有 nav 就直接 append
        const nav = chapter.querySelector(':scope > nav.chapter-nav');
        if (nav) chapter.insertBefore(cfn, nav);
        else chapter.appendChild(cfn);
      }
      cfn.querySelector('ol').appendChild(li);
    }
    // 原 endnotes 容器空了就移除（保留则会显示一段空 section）
    if (endnotes.querySelectorAll('li').length === 0) {
      endnotes.remove();
    }
  }

  function showChapter(idx) {
    if (!chapters.length) return;
    if (idx < 0) idx = 0;
    if (idx >= chapters.length) idx = chapters.length - 1;
    const oldIdx = currentIdx;
    const newCh = chapters[idx];
    const oldCh = (oldIdx !== idx) ? chapters[oldIdx] : null;

    // 方向：往后翻 → 新章右滑入、旧章左滑出；往前翻 → 反之
    const goingBack = oldCh && idx < oldIdx;

    if (oldCh && oldCh.el.classList.contains('active')) {
      // 老章节即时下线：保留 leave 动画的话，过渡 320ms 内 old + new 同时 display:block，
      // body 高度临时增大；scrollIntoView 在此刻定位的目标位置，等动画结束 old display:none
      // 后高度收缩，滚动位置就漂移到了"目标后面一些"。直接 remove active 让 old 立刻消失，
      // 新章节的 enter 动画用 translateX（不影响垂直布局）平滑滑入，定位准确不闪。
      oldCh.el.classList.remove('active', 'from-left', 'leaving', 'to-right');
    }

    // 切换 body 类：仅 API 章节启用悬挂 + 拉宽 padding-left
    document.body.classList.toggle(
      'has-hanging',
      !!newCh.el.classList.contains('chapter--has-options')
    );

    // 移除可能残留的 leaving，再加 active（触发 enter 动画）
    newCh.el.classList.remove('leaving', 'to-right');
    newCh.el.classList.toggle('from-left', goingBack);
    // 强制重排再加 active 确保动画重放
    void newCh.el.offsetWidth;
    newCh.el.classList.add('active');

    currentIdx = idx;
    // 左侧 TOC 当前章节高光：根据 currentIdx 直接锁定（不依赖 scrollspy；
    // 旧 scrollspy 看的是 in-chapter sub-heading，会把高光抢到隐藏的子链接上去）
    document.querySelectorAll('.manual-toc a.toc-current').forEach((a) => a.classList.remove('toc-current'));
    const sel = newCh.anchorId
      ? `.manual-toc a[href="#${newCh.anchorId}"]`
      : `.manual-toc a[href="#${newCh.id}"]`;
    const chLink = document.querySelector(sel);
    if (chLink) chLink.classList.add('toc-current');
    // 重建右侧"本页内容"为新章节的次级标题
    updatePageToc();
  }

  function initChapterRouting() {
    if (!chapters.length) return;
    const h = location.hash.slice(1);
    if (h) {
      const found = chapters.findIndex((c) => c.id === h);
      if (found >= 0) { showChapter(found); return; }
      // 子锚点：定位到所属章节
      const el = document.getElementById(h);
      if (el) {
        const parentCh = el.closest('.chapter');
        if (parentCh) {
          showChapter(parseInt(parentCh.dataset.chapter, 10));
          // 让浏览器执行原生 hash 滚动
          requestAnimationFrame(() => el.scrollIntoView());
          return;
        }
      }
    }
    showChapter(0);
  }

  // ============ TOC 内层包装 ============
  // 设计：左栏始终显示完整章节列表（不滚动），只有"示例"区块可滚动
  // Typst HTML 输出：manual-toc 直接子节为 [<h2>目次</h2> <nav>chapters</nav> <h2>示例</h2> <nav>examples</nav>]
  // 把 "示例" 那个 nav 单独包进 .toc-scroll，让它占剩余空间且滚动；其它三个保持 flex 0 0 auto
  function wrapTocScroll() {
    const toc = document.querySelector('.manual-toc');
    if (!toc) return;
    const navs = toc.querySelectorAll(':scope > nav[role="doc-toc"]');
    if (navs.length < 2) return; // 没有示例区块就不包装
    const examplesNav = navs[1];
    const wrap = document.createElement('div');
    wrap.className = 'toc-scroll';
    toc.insertBefore(wrap, examplesNav);
    wrap.appendChild(examplesNav);
  }

  // ============ 右侧"本页内容"导航栏 ============
  // 设计：左侧固定显示章节列表（h2），右侧动态显示当前章节的次级标题（h3/h4/h5）
  // + 滚动高亮，二者功能不重合（左切章，右锚定本章节内）
  let pageTocLinks = [];
  let pageObs = null;

  function getPageTocRail() {
    let rail = document.querySelector('.page-toc-rail');
    if (rail) return rail;
    rail = document.createElement('aside');
    rail.className = 'page-toc-rail';
    rail.setAttribute('aria-label', '本页内容');
    rail.innerHTML = '<h2>本页内容</h2><div class="scroll"></div>';
    document.body.appendChild(rail);
    return rail;
  }

  function updatePageToc() {
    const rail = getPageTocRail();
    const scroll = rail.querySelector('.scroll');
    scroll.innerHTML = '';
    pageTocLinks = [];
    if (pageObs) { pageObs.disconnect(); pageObs = null; }

    if (!chapters.length || currentIdx < 0) {
      rail.classList.add('empty');
      return;
    }
    const ch = chapters[currentIdx];
    const headings = Array.from(ch.el.querySelectorAll('h3, h4, h5'));
    if (!headings.length) {
      rail.classList.add('empty');
      return;
    }
    rail.classList.remove('empty');

    // 把 h4 / h5 归到上一个 h3 下，做成可折叠的两级列表（再深的 heading 罕见，平铺到 h3 下）
    const groups = []; // [{ h3: heading|null, children: [headings...] }]
    for (const h of headings) {
      if (h.tagName === 'H3') {
        groups.push({ h3: h, children: [] });
      } else if (groups.length) {
        groups[groups.length - 1].children.push(h);
      } else {
        // 章节里没出现 h3 直接来 h4——给个无头组当成扁平
        groups.push({ h3: null, children: [h] });
      }
    }

    const makeLink = (h) => {
      const wrap = h.parentElement;
      const id = (wrap && wrap.id) || h.id || '';
      if (!id) return null;
      const a = document.createElement('a');
      a.href = '#' + id;
      a.textContent = h.textContent.trim().replace(/\s+/g, ' ');
      return { a, target: wrap || h };
    };

    const ol = document.createElement('ol');
    for (const g of groups) {
      if (g.h3) {
        const linkInfo = makeLink(g.h3);
        if (!linkInfo) continue;
        const li = document.createElement('li');
        const hasChildren = g.children.length > 0;
        li.className = 'lv-h3' + (hasChildren ? ' has-children' : '');
        const head = document.createElement('div');
        head.className = 'page-toc-head';
        if (hasChildren) {
          const tog = document.createElement('span');
          tog.className = 'page-toc-toggle';
          tog.textContent = '▼';
          tog.setAttribute('aria-label', '折叠 / 展开');
          tog.addEventListener('click', (ev) => {
            ev.stopPropagation();
            ev.preventDefault();
            li.classList.toggle('collapsed');
          });
          head.appendChild(tog);
        }
        head.appendChild(linkInfo.a);
        li.appendChild(head);
        pageTocLinks.push(linkInfo);
        if (hasChildren) {
          const sub = document.createElement('ol');
          for (const c of g.children) {
            const cl = makeLink(c);
            if (!cl) continue;
            const subLi = document.createElement('li');
            subLi.className = 'lv-' + c.tagName.toLowerCase();
            subLi.appendChild(cl.a);
            sub.appendChild(subLi);
            pageTocLinks.push(cl);
          }
          li.appendChild(sub);
        }
        ol.appendChild(li);
      } else {
        // 无 h3 头组：扁平展开
        for (const c of g.children) {
          const cl = makeLink(c);
          if (!cl) continue;
          const li = document.createElement('li');
          li.className = 'lv-' + c.tagName.toLowerCase();
          li.appendChild(cl.a);
          ol.appendChild(li);
          pageTocLinks.push(cl);
        }
      }
    }
    scroll.appendChild(ol);

    // 默认把所有有子项的 h3 折叠起来，避免长章节（API、GB/T 标准）一眼望不到底；
    // 用户滚动到某一节时，scrollspy 的 recompute() 会自动展开父项让高光可见
    ol.querySelectorAll('li.has-children').forEach((li) => li.classList.add('collapsed'));

    // 滚动高亮：用滚动位置主动算"最近一个标题已划过顶栏"，而不是被动等
    // IntersectionObserver 报 isIntersecting:true。前者支持"从下面章节往上扒"
    // 的边缘情形：1.3 出激活区后能立刻切到 1.2，不必等 1.2 标题进激活区。
    const THRESHOLD = 80; // 离顶 80px 以内视为"已划过"，配合顶栏 ~52px + 余量
    let activeLink = null;
    const recompute = () => {
      let candidate = null;
      for (const l of pageTocLinks) {
        const rect = l.target.getBoundingClientRect();
        if (rect.top <= THRESHOLD) candidate = l;
        else break; // pageTocLinks 是文档序，第一个不满足后面更不满足
      }
      // 全部都还没划过（用户在章节最顶部）→ 回退到第一个
      if (!candidate && pageTocLinks.length) candidate = pageTocLinks[0];
      if (candidate && candidate.a !== activeLink) {
        if (activeLink) activeLink.classList.remove('toc-current');
        candidate.a.classList.add('toc-current');
        activeLink = candidate.a;
        // 高光在折叠的 h3 子项里时，自动把父 h3 展开，让用户能看到亮的位置
        let par = candidate.a.closest('li');
        while (par) {
          par.classList.remove('collapsed');
          par = par.parentElement && par.parentElement.closest('li');
        }
      }
    };
    let raf = 0;
    const onScroll = () => {
      if (raf) return;
      raf = requestAnimationFrame(() => { raf = 0; recompute(); });
    };
    // 用 IntersectionObserver 仅作为兜底（chapter 切换 / 视口尺寸变化等触发重算）；
    // 主信号是滚动事件
    pageObs = { _scrollHandler: onScroll, disconnect() { window.removeEventListener('scroll', this._scrollHandler); } };
    window.addEventListener('scroll', onScroll, { passive: true });
    recompute(); // 初始
  }

  // ============ 性能基准面板：点击 #perf-launcher 注入按钮 → 弹模态 → 跑 WASM ============
  function injectPerfLauncher() {
    const slot = document.getElementById('perf-launcher');
    if (!slot) return;
    slot.innerHTML = '';
    const btn = document.createElement('button');
    btn.className = 'perf-run-btn';
    btn.innerHTML = '<span class="perf-run-icon">⚡</span><span class="perf-run-label">在你的设备上重测此基准</span><span class="perf-run-hint">(WASM · 仅点击后加载约 4 MB)</span>';
    btn.addEventListener('click', openPerfModal);
    slot.appendChild(btn);
  }

  function openPerfModal() {
    if (document.querySelector('.perf-modal')) return;
    const modal = document.createElement('div');
    modal.className = 'perf-modal';
    modal.innerHTML = [
      '<div class="perf-card">',
      '  <header class="perf-head">',
      '    <h3>浏览器内 WASM 性能基准</h3>',
      '    <button class="perf-close" aria-label="关闭">×</button>',
      '  </header>',
      '  <div class="perf-status">准备中…</div>',
      '  <div class="perf-progress"><div class="perf-progress-bar"></div></div>',
      '  <div class="perf-chart"></div>',
      '  <footer class="perf-foot">',
      '    <span class="perf-env"></span>',
      '  </footer>',
      '</div>',
    ].join('');
    document.body.appendChild(modal);
    const close = () => modal.remove();
    modal.querySelector('.perf-close').addEventListener('click', close);
    modal.addEventListener('click', (e) => { if (e.target === modal) close(); });
    document.addEventListener('keydown', function escClose(ev) {
      if (ev.key === 'Escape' && modal.parentNode) {
        close();
        document.removeEventListener('keydown', escClose);
      }
    });

    // file:// 下浏览器禁止跨源动态 import / fetch / WASM streaming——给出可执行的本地启动命令
    if (location.protocol === 'file:') {
      modal.querySelector('.perf-status').innerHTML = [
        '<strong>需要 HTTP 服务而非 file:// 才能跑 WASM 基准。</strong><br>',
        '在 dist 目录下起一个本地静态服务器，再用浏览器访问：<br>',
        '<code style="display:block;margin:0.6rem 0;padding:0.5rem 0.7rem;background:var(--code-bg);border-radius:4px;font-size:0.85em">',
        '  cd easy-zh-manual/web/dist<br>',
        '  python3 -m http.server 8000<br>',
        '  # 或：npx serve .',
        '</code>',
        '然后打开 <a href="http://localhost:8000/" target="_blank">http://localhost:8000/</a>，再点这个按钮即可。',
      ].join('');
      modal.querySelector('.perf-progress').style.display = 'none';
      return;
    }

    runPerfBenchmark(modal).catch((err) => {
      modal.querySelector('.perf-status').textContent = '运行失败：' + (err && err.message ? err.message : String(err));
      console.error('[benchmark]', err);
    });
  }

  async function runPerfBenchmark(modal) {
    const status = modal.querySelector('.perf-status');
    const bar = modal.querySelector('.perf-progress-bar');
    const chart = modal.querySelector('.perf-chart');
    const env = modal.querySelector('.perf-env');
    env.textContent = `${navigator.userAgent.replace(/Mozilla\/5\.0 \(/, '').replace(/\) .*/, ')')} · ${navigator.hardwareConcurrency || '?'} cores`;

    // 冷编译每次是整篇编译（慢但稳），少量即可；增量编辑快，多取剔抖。
    const N_COLD = 8, N_WARM = 60;
    const total = N_COLD * 2 + N_WARM * 2;
    let done = 0;

    const { runBench, statsOf } = await import('./benchmark.js');
    status.textContent = '加载 Typst WASM 编译器…';

    const result = await runBench({
      nCold: N_COLD, nWarm: N_WARM,
      onProgress: (p) => {
        if (p.phase === 'init') { status.textContent = p.label; bar.style.width = '4%'; return; }
        status.textContent = p.label;
        done += 1;
        bar.style.width = (4 + 96 * (done / total)).toFixed(1) + '%';
      },
    });

    // 主口径 = 冷编译（构建）：真实「构建一次要多久」（parse + 正文引用 + 著录 + 排版全跑），喂正文统计表。
    const omni = statsOf(result.cold.omni);
    const hay  = statsOf(result.cold.hay);
    const ratio = (omni.mean / hay.mean);
    const ratioPct = ((ratio - 1) * 100);
    // 次口径 = 增量编辑（最乐观角落：解析/著录被 comemo 缓存）。
    const wOmni = statsOf(result.warm.omni);
    const wHay  = statsOf(result.warm.hay);
    const wRatio = (wOmni.mean / wHay.mean);

    // 写回正文表格里的 .perf-stat span（冷编译口径，ms 两位小数）
    const fmt = (v) => v.toFixed(2) + ' ms';
    const setStat = (id, v) => {
      const el = document.querySelector(`[data-stat="${id}"]`);
      if (el) {
        el.textContent = v;
        el.classList.add('updated'); // CSS 给个高亮表示本次跑出的实测值
      }
    };
    setStat('omni-mean', fmt(omni.mean));
    setStat('omni-median', fmt(omni.median));
    setStat('omni-min', fmt(omni.min));
    setStat('omni-max', fmt(omni.max));
    setStat('omni-std', fmt(omni.std));
    setStat('hay-mean', fmt(hay.mean));
    setStat('hay-median', fmt(hay.median));
    setStat('hay-min', fmt(hay.min));
    setStat('hay-max', fmt(hay.max));
    setStat('hay-std', fmt(hay.std));
    setStat('ratio', ratio.toFixed(2));
    setStat('ratio-pct', (ratioPct >= 0 ? '+' : '') + ratioPct.toFixed(0) + '%');

    status.textContent = `完成。冷编译 ${N_COLD}×2 + 增量 ${N_WARM}×2 次 · 构建口径 ${ratio.toFixed(2)}× · 增量编辑口径 ${wRatio.toFixed(2)}×`;
    bar.style.width = '100%';

    chart.innerHTML = renderPerfChart(result.cold, omni, hay, { wRatio, wOmni, wHay });
  }

  function renderPerfChart(result, omni, hay, warm) {
    const all = result.omni.concat(result.hay);
    const max = Math.max.apply(null, all);
    const W = 300; // 内部画布宽度（CSS px）
    const scale = W / max;

    function row(label, runs, st, color) {
      const dotsHtml = runs.map((v) => {
        const x = (v * scale).toFixed(1);
        return `<span class="bench-dot" style="left:${x}px;background:${color}"></span>`;
      }).join('');
      const meanX = (st.mean * scale).toFixed(1);
      const stdW = (st.std * scale * 2).toFixed(1);
      return [
        '<div class="bench-row">',
        `  <div class="bench-label">${label}</div>`,
        `  <div class="bench-track" style="width:${W}px;">`,
        `    <span class="bench-band" style="left:${(st.mean * scale - st.std * scale).toFixed(1)}px;width:${stdW}px;background:${color}"></span>`,
        `    <span class="bench-mean" style="left:${meanX}px;background:${color}"></span>`,
        `    ${dotsHtml}`,
        '  </div>',
        `  <div class="bench-num">${st.mean.toFixed(3)}<span class="bench-pm"> ± ${st.std.toFixed(3)} ms</span></div>`,
        '</div>',
      ].join('');
    }

    const ratioLabel = (omni.mean / hay.mean).toFixed(3);
    const tickStep = niceStep(max);
    const ticks = [];
    for (let t = 0; t <= max; t += tickStep) {
      ticks.push(`<span class="bench-tick" style="left:${(t * scale).toFixed(1)}px">${t.toFixed(0)}</span>`);
    }

    return [
      '<div class="bench-axis-wrap">',
      '  <div class="bench-axis-spacer"></div>',
      `  <div class="bench-axis" style="width:${W}px">${ticks.join('')}</div>`,
      '  <div class="bench-axis-unit">ms</div>',
      '</div>',
      row('omni-gb7714', result.omni, omni, '#A56AC2'),
      row('Hayagriva',   result.hay,  hay,  '#5e8ce0'),
      `<div class="bench-summary">冷编译·构建 omni / Hayagriva = <strong>${ratioLabel}×</strong>`
        + (warm ? ` &nbsp;·&nbsp; 增量编辑 = <strong>${warm.wRatio.toFixed(2)}×</strong>` : '')
        + `</div>`,
    ].join('');
  }

  function niceStep(max) {
    const target = max / 5;
    const mag = Math.pow(10, Math.floor(Math.log10(target)));
    const m = target / mag;
    const nice = m < 1.5 ? 1 : m < 3 ? 2 : m < 7 ? 5 : 10;
    return nice * mag;
  }

  // ============ API 章节"参数排序"切换 ============
  // 默认按源码顺序（手动编排的高频 / 依赖序）；点切换按钮按字母重排 .api-section 内
  // 的 .option 元素，再点恢复源码序。
  function injectApiSortToggle() {
    const slot = document.getElementById('api-sort-toggle');
    if (!slot) return;
    // 抓快照：记录每个 api-section 内当前 DOM 中 option 的源码序，方便回滚
    const sections = Array.from(document.querySelectorAll('section.api-section'));
    const snapshots = sections.map((sec) => Array.from(sec.querySelectorAll(':scope > section.option')));

    slot.innerHTML = '';
    const btn = document.createElement('button');
    btn.className = 'api-sort-btn';
    btn.dataset.mode = 'source';
    btn.innerHTML = '<span class="api-sort-icon">↕</span><span class="api-sort-label">参数排序：源码序（高频/依赖）</span>';
    btn.title = '在"源码序"与"按字母"之间切换';
    btn.addEventListener('click', () => {
      const next = btn.dataset.mode === 'source' ? 'alpha' : 'source';
      btn.dataset.mode = next;
      btn.querySelector('.api-sort-label').textContent =
        next === 'source' ? '参数排序：源码序（高频/依赖）' : '参数排序：按字母';
      sections.forEach((sec, i) => {
        let order;
        if (next === 'alpha') {
          order = snapshots[i].slice().sort((a, b) => {
            const na = (a.dataset.name || '').toLowerCase();
            const nb = (b.dataset.name || '').toLowerCase();
            return na < nb ? -1 : na > nb ? 1 : 0;
          });
        } else {
          order = snapshots[i];
        }
        // 把 options 按新顺序重新挂回 sec
        order.forEach((opt) => sec.appendChild(opt));
      });
    });
    slot.appendChild(btn);
  }

  function init() {
    initTheme();
    injectTopBar();
    wrapTocScroll();
    splitIntoChapters();
    initChapterRouting();
    makeFoldable();
    // initScrollSpy() 不再调：左 TOC 只显示章节级 (h2)，高光由 showChapter 直接锁定；
    // 旧的 in-chapter scrollspy 会把 .toc-current 转移到隐藏的子链接上，反而抢掉视觉高光
    injectPerfLauncher();
    injectApiSortToggle();
  }

  // ============ 启动 ============
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
