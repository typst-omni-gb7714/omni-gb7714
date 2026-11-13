//! param: Zotero「Extra」字段（note / annotation 里的 CSL 变量编码）
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "note/Extra 字段", controls: "Zotero 把没有 BibTeX 字段的 CSL 变量塞进 `note`（vanilla `.bib` 导出）或 CSL JSON 的 `note` 变量,每行 `变量: 值`。`src/parse/csl-extra.typ` 扫 `note`/`annotation`,复用 `csl-map` 词表把*已知* CSL 变量注入对应槽位——`.bib` 与 JSON 同处生效。解析对齐 Zotero `extractExtraFields`:标签小写+空格→连字符归一、仅已知变量提取、同名文本后者胜、同名名字累加。",
  expect: [note 里的 CSL 变量被抽出注入,余文留作 note 正文:

    - *已知变量注入*:`page`→页码、`Original Date`→出版年回退、`issued`→出版年、`edition`→版本、`author`（多行）→累加成多个责任者。
    - *地图 scale / dimensions*:标准 biblatex 无这两个字段（Zotero 只能塞 note）,现按胡振震 biblatex-gb7714-2025 的同名字段注入,驱动渲染在题名后（比例尺）与出版年后（尺寸,2025 §8.13）。
    - *地图类型推断*:`@misc` 带了地图专用字段 `scale` / `dimensions`（字段形式，或 note 里的标记注入后）→ 判为 map 出 `[CM]`。这两个字段只对地图有意义,vanilla 导出遇 biblatex 无 map 时退成 `@misc` 却带着它们,据此还原;只补 `misc` 这个兜底桶。
    - *`tex.entrytype` 显式覆写*:导出也可能把真类型记进 note 的 `tex.entrytype: <类型>`,检测到就覆盖 entry_type（优先于推断，要求 `tex.` 前缀）。
    - *`tex.*` 透传剥离*:BBT 把 biblatex 专有信息追加成 note 末尾的 `tex.<字段>: <值>`。omni 不渲染,一律剥掉——否则 biber 折行后会被前一个已识别变量的值吞进去、漏进正文。
    - *`tex.*` 字段名含下划线*:`.bib` 里的 `\_` 进 citegeist 前先变私用区哨兵（渲染末端才还原为 `_`）,不在 `[a-z0-9_]` 内;字段名匹配连哨兵一起吃、再还原成 `_`——否则 `tex.author\_transliteration\_en` 等透传字段漏过,剩在 note 里被 `Number:` 行的值一路吞进 eid 渲染出来（实测 b.4:11）。
    - *文章编号 vs 期号*:CSL `number`（文章编号）在文章类映到 `eid`（→按页码著录，§7.7）、`issue`（期号）另存,两者分槽不再互相覆盖。
    - *标准类型推断*:vanilla 导出遇 biblatex 无 `@standard` 时退成 `@misc`（type / genre 常丢，只剩 number）。靠 genre（→type 含「标准」/「standard」）或 number 的标准编号强特征还原 → `[S]`（编号前置）。misc 本不渲染 number,误判至多著录一个否则丢弃的编号,无下行风险。
    - *已注册 PID 注入*:CSTR（国标特有、非 CSL 标准变量）与用户经 `custom-pids` 注册的自定义 PID（URN 等）也从 note 抽出、注入对应 PID 字段,走 PID 管道著录在 URL 之后;否则整行漏成 note 正文渲染在错位（页码后 URL 前）。DOI / ISBN / ISSN 早由 `csl-map` 词表认出。
    - *专利 jurisdiction / holder*:CSL `jurisdiction`（专利国别）仅*专利*类型映到 `location`（§8.10 专利国别取 location，别的类型不动）;`tex.holder`（BBT 逃生舱，CSL 无 holder 变量）→ `holder` 名字角色（建 parsed_names，否则专利责任者错落到发明人）。其余 `tex.<字段>` 同理注入对应 biblatex 字段。
    - *BBT 透传消费与显式字段胜*:`tex.<字段>` 逐个消费、注入对应字段（名字角色建 parsed_names，其余作文本），真实字段在就跳过（`holder` 真字段与 note 里 `tex.holder` 并存时用真字段、不重复）;`tex.entrytype` 仍作类型覆盖。
    - *显式字段胜*:真实 biblatex 字段 / 已有责任者优先,note 只填缺失（`date={2020}` 压住 note 的 `issued: 1900`）。
    - *`.bib` 换行折叠*:biber 把 note 换行折成空格,本 pass 按已知标签边界再切;折叠行里最后一个值后跟的自由备注会被并进该值（biber 所致,JSON 因保留换行不受影响）。
    - *地图作析出文献*:`Book Title`（→`container-title`→地图的 `booktitle`）在场时,地图（[CM]）走析出驱动,得「析出题名. 比例尺[CM]//母体书名. 出版地: 出版者, 年: 页. 尺寸」（§8.13.1，与专著析出同构，复用 component-part 驱动）;真实 `booktitle` / `journaltitle` 字段同样触发。附带修了 `_split-line` 的折行吞标签:母体题名这种*多词全字母值*后紧跟的已知标签（`Pages`）不再被吞进题名，从尾部回缩找到已知子标签就断开。
    - *裸 DOI 不吞进 pages*:Zotero「Extra」把裸 DOI（`10.xxxx/…`，无 `DOI:` 标签）单列一行,biber 折行后紧跟在前一个值（如 `Pages: 35`）后成 `Pages: 35 10.1002/…`,DOI 被吞进页码。`_split-line` 认出裸 DOI 模式作*独立边界*切断前值,但*随后丢弃、不回收成 doi*——GB §5.1:3 与李泽平 / 胡振震都不著录它,回收会把 [M] 变 [M/OL] 并多出 DOI。故 pages 干净收「35」。
    - *认全 CSL 变量、杜绝泄漏*:`csl-map` 认*全套* CSL 1.0.2 变量名。omni 无渲染槽的（`original-author` / `original-title` / `medium` / `abstract` 等）判为 `drop`——*构成边界、消费丢弃*。这样折叠成一行的 `Pages: 798 original-author: … original-title: …` 里，`Pages` 的值在 `original-author:` 处断开、不再贪婪吞并后续字段漏进版面（实测 b.1:12：`…2010:798` 干净收尾，不再拖出「original-author: …」）。真·自由备注（非 CSL 变量）仍留 note 正文。])

// CSL JSON：note 变量承载 Extra（页码、以及多行 author 累加）
#let json = bytes("[
  {\"id\": \"jpage\", \"type\": \"chapter\", \"title\": \"析出题名\",
   \"author\": [{\"family\": \"李\", \"given\": \"四\"}], \"container-title\": \"母体文集\",
   \"publisher\": \"出版社\", \"publisher-place\": \"京\", \"issued\": {\"date-parts\": [[2019]]},
   \"note\": \"page: 序2-3\", \"language\": \"zh-CN\"},
  {\"id\": \"jnames\", \"type\": \"book\", \"title\": \"多名注入\", \"publisher\": \"社\",
   \"issued\": {\"date-parts\": [[2020]]}, \"note\": \"author: 张, 三\\nauthor: 王, 五\", \"language\": \"zh-CN\"},
  {\"id\": \"jarch\", \"type\": \"manuscript\", \"title\": \"某档案卷宗\", \"author\": [{\"literal\": \"辽宁省政府\"}],
   \"archive\": \"辽宁省档案馆\", \"issued\": {\"date-parts\": [[\"1931\", 11, 7]]},
   \"note\": \"archive-place: 沈阳\", \"language\": \"zh-CN\"}
]")

// .bib：vanilla Zotero 把 Extra 塞进 note（biber 折叠换行）
#let bib = bytes("@book{bnote, author={赵六}, title={补字段}, publisher={社}, location={京}, note={Original Date: 1705
PMID: 998877}, langid={chinese}}
@book{bwins, author={钱七}, title={显式胜}, publisher={社}, location={沪}, date={2020}, note={issued: 1900}, langid={chinese}}
@book{balias, author={{钱学森}}, title={创建系统学}, publisher={山西科学技术出版社}, location={太原}, date={2001}, note={Pages: 序2-3}, langid={pinyin}}
@misc{bmap, editora={{吴自银} and {温珍河}}, editoratype={collaborator}, title={中国南部海域海底地形图}, publisher={科学出版社}, location={北京}, date={2019}, note={dimensions: 100cm×70cm
scale: 1:3000000}, langid={chinese}}
@misc{bmapfield, editora={{吴自银} and {温珍河}}, editoratype={collaborator}, title={中国南部海域海底地形图}, publisher={科学出版社}, location={北京}, date={2019}, scale={1:3000000}, dimensions={100cm×70cm}, langid={chinese}}
@misc{bmaptx, author={某人}, title={退化成 misc 的地图}, publisher={社}, location={京}, date={2019}, note={tex.entrytype: map}, langid={chinese}}
@article{btex, author={{甲}}, title={文章编号与 tex 透传}, journaltitle={某刊}, date={2023}, volume={267}, langid={chinese}, note={Number: 147370
tex.number:
tex.eid: 147370}}
@article{bissue, author={{乙}}, title={期号与文章编号并存}, journaltitle={航空学报}, date={2024}, volume={45}, issue={增刊1}, langid={chinese}, note={Number: 730570}}
@misc{bstd, author={{委员会}}, title={资源描述}, date={2021}, number={GB/T 3792—2021}, langid={chinese}}
@misc{bstdg, author={{委员会}}, title={国际标准示例}, date={2019}, number={ISO 21378:2019}, langid={chinese}, note={genre: 国家标准}}
@thesis{bcstr, author={{井丽南}}, title={支持状态可编程的{SDN}交换机}, institution={中国科学院大学}, location={北京}, date={2022}, type={博士学位论文}, langid={pinyin}, url={http://x.cn/a}, note={Pages: 43
{CSTR}: 35001.37.01.33142.20220037}}
@book{burn, author={{张三}}, title={自定义标识符}, publisher={测试社}, location={北京}, date={2020}, langid={pinyin}, note={URN: urn:nbn:de:1234}}
@patent{ppat, author={{石顺祥} and {许海平}}, date={2002-03-06}, holder={西安电子科技大学}, langid={pinyin}, note={jurisdiction: 中国
tex.holder: 西安电子科技大学
tex.number: {CN}01128777.2}, number={{CN}1338652A}, title={光折变自适应光外差探测方法}, type={patent}, url={http://x.cn/a}, urldate={2002-05-28}}
@patent{ppatj, author={{石顺祥} and {许海平}}, date={2002-03-06}, langid={pinyin}, note={jurisdiction: 中国
tex.holder: 西安电子科技大学
tex.number: {CN}01128777.2}, number={{CN}1338652A}, title={光折变自适应光外差探测方法}, type={patent}, url={http://x.cn/a}, urldate={2002-05-28}}
@book{bleak, author={{甲}}, title={原作者原题名不漏}, publisher={社}, location={京}, date={2010}, pages={798}, langid={chinese}, note={original-author: Ljungqvist || Lars
original-title: Recursive macroeconomic theory
medium: 电子}}
@misc{bmapcp, title={某地区湿地图}, publisher={海洋出版社}, location={北京}, date={2024}, langid={chinese}, note={Book Title: 某海岸带侵蚀与防治研究
Pages: 50
tex.entrytype: map}}
@book{bdoi, author={Boobier, Tony}, title={AI and the future of banking}, publisher={Wiley}, location={Chichester}, date={2020}, langid={american}, note={Pages: 35
10.1002/9781119596165}}
@book{bvt, author={{李约瑟}}, title={中国科学技术史}, volume={第二卷}, publisher={科学出版社}, location={北京}, date={1990}, langid={chinese}, note={volume-title: 科学思想史}}
@article{btexund, author={{王利平} and {王福新} and {刘洪}}, title={过冷大水滴环境粒径分布模拟方法研究进展}, journaltitle={航空学报}, date={2024}, volume={45}, issue={增刊1}, langid={pinyin}, note={Number: 730570
tex.author\\_transliteration\\_en: Wang, Liping and Wang, Fuxin and Liu, Hong
tex.title\\_translation\\_en: Research progress on simulation methods
tex.journal\\_translation\\_en: Acta Aeronautica et Astronautica Sinica
tex.number:
tex.eid: 730570}}")

#case("CSL JSON note：page / 多行 author", gb7714.with(version: 2025), bib: json, cites: (<jpage>, <jnames>), full: true)
#case(".bib note：Original Date / PMID / 显式胜 / Zotero 字段名别名 Pages", gb7714.with(version: 2025), bib: bib, cites: (<bnote>, <bwins>, <balias>), full: true)
#case("类型推断：@misc 带地图字段 → CM（note 注入的 scale/dimensions · 直接的字段）", gb7714.with(version: 2025), bib: bib, cites: (<bmap>, <bmapfield>), full: true)
#case("显式覆写：@misc + note 的 tex.entrytype: map → CM（无地图字段也认）", gb7714.with(version: 2025), bib: bib, cites: (<bmaptx>,), full: true)
#case("tex.* 透传剥离 + 文章编号→页码：note 的 Number 入 eid（267：147370），tex.* 不漏", gb7714.with(version: 2025), bib: bib, cites: (<btex>, <bissue>), full: true)
#case("tex.* 字段名带下划线（\\_→哨兵）也剥净：eid 干净收 730570，转写/译名不漏（对齐 gbt7714.b.4:11）", gb7714.with(version: 2025), bib: bib, cites: (<btexund>,), full: true)
#case("标准类型推断：@misc 靠 number 强特征 / genre note 还原 [S]", gb7714.with(version: 2025), bib: bib, cites: (<bstd>, <bstdg>), full: true)
#case("已注册 PID 注入：note 的 CSTR（内置）→ 走 PID 管道著录在 URL 之后、不漏成正文", gb7714.with(version: 2025), bib: bib, cites: (<bcstr>,), full: true)
#case("已注册 PID 注入：note 的自定义 URN（custom-pids 注册）→ 注入 urn 字段", gb7714.with(version: 2025, custom-pids: (myurn: (field: "urn", prefix: "URN"))), bib: bib, cites: (<burn>,), full: true)
// note 的 volume-title（分卷书名）：与 CSL JSON 直接字段、.bib 三路统一，对调进 maintitle/title → 「整套:卷次 分卷」。
#case("note 的 volume-title→分卷书名（中国科学技术史:第二卷 科学思想史）", gb7714.with(version: 2025), bib: bib, cites: (<bvt>,), full: true)
// note 的 archive-place（收藏者所在地）→ location：档案类经 note 也认（§8.12.3「收藏者所在地: 收藏者」）。
#case("note 的 archive-place→收藏者所在地（沈阳：辽宁省档案馆）", gb7714.with(version: 2025), bib: json, cites: (<jarch>,), full: true)
#case("专利 jurisdiction→专利国别（中国）+ tex.holder→holder（责任者=西安电子科技大学，非发明人）；holder 真字段与 tex.holder 并存时显式字段胜、不重复", gb7714.with(version: 2025, show-patent-country: true), bib: bib, cites: (<ppat>,), full: true)
#case("专利 json 形态：holder 只在 tex.holder（无真字段）→ 经 BBT 逃生舱恢复责任者，不再错落到发明人", gb7714.with(version: 2025, show-patent-country: true), bib: bib, cites: (<ppatj>,), full: true)
#case("认全 CSL 变量：original-author / original-title / medium 等无渲染槽的变量 → 消费丢弃，不漏进版面", gb7714.with(version: 2025), bib: bib, cites: (<bleak>,), full: true)
#case("地图析出：note 的 Book Title→母体 booktitle，出 [CM]//母体（折行后 Pages 不被母体题名吞、归出版年后）", gb7714.with(version: 2025), bib: bib, cites: (<bmapcp>,), full: true)
#case("裸 DOI 不吞进 pages：折行后「Pages: 35 10.1002/…」的 DOI 作边界丢弃，pages 干净收 35（§5.1:3）", gb7714.with(version: 2025), bib: bib, cites: (<bdoi>,), full: true)
