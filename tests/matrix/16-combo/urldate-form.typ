//! combo: version × 著录形式 × show-urldate × show-url × date-fallback
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "引用日期与著录形式", controls: "日期项由版本和实际出版形式决定，不只看类型码或OL。",
  expect: [2025图书／期刊形式即使内容码为DS、CP、EB也不加引用日期；独立数据集、预印本、网页式保留已有日期。
    非联机数据集不因CD载体或隐藏URL丢失日期。2005／2015沿用已有日期，缺失不补造。
    依据2025 §8.11.1、§8.14.1及表10／11／14／15，2005 §4.1.1。])
#let DATA = bytes(```bib
@book{form-book-ds, author={Alpha, Alice}, title={Book Dataset}, usera={DS},
  address={City}, publisher={Book Press}, year={2020}, urldate={2024-06-07}, medium={OL}, url={https://example.org/book}}
@article{form-article-ds, author={Beta, Bob}, title={Journal Dataset}, usera={DS},
  journaltitle={Data Journal}, year={2021}, volume={5}, pages={23-25}, urldate={2024-06-07}, medium={OL}}
@dataset{form-dataset-part, author={Gamma, Grace}, title={Dataset Chapter}, booktitle={Collected Data},
  editor={Host, Henry}, address={City}, publisher={Book Press}, year={2022}, pages={10-12}, urldate={2024-06-07}}
@dataset{form-dataset-journal, author={Delta, David}, title={Published Dataset}, journaltitle={Data Journal},
  year={2022}, volume={6}, pages={31-34}, urldate={2024-06-07}}
@dataset{form-dataset-cd, author={Epsilon, Eva}, title={Independent Disc Data}, medium={CD},
  publisher={Data Platform}, version={V2}, date={2023-01-02}, urldate={2024-06-07}}
@dataset{form-dataset-unknown, author={Zeta, Zoe}, title={Independent Data}, urldate={2024-06-07}}
@preprint{form-preprint, author={Eta, Ethan}, title={Preprint Form}, date={2023-03-04},
  urldate={2024-06-07}, url={https://example.org/preprint}, publisher={Preprint Platform}}
@software{form-software-cd, author={Theta, Theo}, title={Disc Software}, medium={CD}, address={City},
  publisher={Software Press}, year={2023}, version={V1.2}, urldate={2024-06-07}}
@software{form-software-web, author={Iota, Irene}, title={Download Page}, date={2023-04-05},
  url={https://example.org/download}, urldate={2024-06-07}}
@database{form-database-web, author={Kappa, Kate}, title={Database Page}, date={2023-05-06},
  url={https://example.org/database}, urldate={2024-06-07}}
@book{form-book-cp, author={Lambda, Leo}, title={Software Book}, usera={CP},
  address={City}, publisher={Book Press}, year={2021}, urldate={2024-06-07}}
@book{form-book-eb, author={Mu, Mary}, title={Book With EB Code}, usera={EB},
  address={City}, publisher={Book Press}, year={2021}, urldate={2024-06-07}}
@online{form-online-book, author={Nu, Nora}, title={Book On Web}, usera={M},
  address={City}, publisher={Book Press}, year={2021}, url={https://example.org/online-book}, urldate={2024-06-07}}
@online{form-no-date, author={Xi, Xavier}, title={Undated Page}, url={https://example.org/no-date}}
@book{form-estimate-book, author={Omicron, Olive}, title={Estimated Book}, usera={DS},
  address={City}, publisher={Book Press}, urldate={2024-06-07}}
@book{form-legacy-cd, author={Pi, Peter}, title={Legacy Disc Book}, medium={CD},
  address={City}, publisher={Book Press}, year={2020}, urldate={2024-06-07}}
@online{form-custom-web, author={Rho, Rose}, title={Custom Web Form}, publisher={Not A Platform},
  version={V9}, date={2023-07-08}, url={https://example.org/custom-web}, urldate={2024-06-07}}
@online{form-web-year, author={Sigma, Simon}, title={Declared Web Year}, year={2020},
  url={https://example.org/year-only}, urldate={2024-06-07}}
```.text)
#let _sample(caption, key, ..options) = case(caption, gb7714.with(..options), bib: DATA, cites: (label(key),), full: false)
#_sample("01 图书形式数据集不加引用日期", "form-book-ds")
#_sample("02 期刊形式数据集不加引用日期", "form-article-ds")
#_sample("03 数据集有图书母体时按析出形式", "form-dataset-part")
#_sample("04 数据集有期刊母体时按期刊形式", "form-dataset-journal")
#_sample("05 独立CD数据集仍有引用日期", "form-dataset-cd", show-url: "online-only")
#_sample("06 独立数据集不要求OL才能显示日期", "form-dataset-unknown")
#_sample("07 独立预印本保留日期", "form-preprint")
#_sample("08 光盘软件不是下载网页", "form-software-cd")
#_sample("09 软件下载网页保留日期", "form-software-web")
#_sample("10 网络数据库按网页式处理", "form-database-web")
#_sample("11 图书形式的软件资料不加引用日期", "form-book-cp")
#_sample("12 写EB代码不抹去明确的图书形式", "form-book-eb")
#_sample("13 网页呈现的图书仍按图书形式", "form-online-book")
#_sample("14 网页缺引用日期时不补今天", "form-no-date")
#_sample("15 独立数据集的日期可显式关闭", "form-dataset-cd", show-urldate: false)
#_sample("16 隐藏网页URL仍保留引用日期", "form-software-web", show-url: false)
#_sample("17 图书形式仍可按引用年推定出版年", "form-estimate-book", date-fallback: "urldate", show-urldate: false)
#_sample("18 独立数据集不从引用日期造出版年", "form-dataset-unknown", date-fallback: "urldate")
#_sample("19 2015版保留图书日期", "form-book-ds", version: 2015)
#_sample("20 2005版非联机电子日期任选", "form-legacy-cd", version: 2005, show-url: "online-only")
#case("21 全局2015、逐表2025：图书形式不加日期", gb7714.with(version: 2015), bib: DATA,
  cites: (<form-book-ds>,), full: false, bib-args: (version: 2025))
#case("22 全局2025、逐表2015：保留图书日期", gb7714.with(), bib: DATA,
  cites: (<form-book-ds>,), full: false, bib-args: (version: 2015))
#_sample("23 自定义数据集代码仍按独立形式著录", "form-dataset-cd", custom-marks: (dataset: "DX"))
#_sample("24 自定义预印本代码仍保留日期和平台", "form-preprint", custom-marks: (preprint: "PX"))
#_sample("25 自定义网页代码不添加版本和平台", "form-custom-web", custom-marks: (online: "WX"))
#_sample("26 模板中的图书日期同样按形式过滤", "form-book-ds", custom-drivers: (book: "<title-block>. <urldate>. <access>"))
#_sample("27 模板中的非联机数据集仍保留日期", "form-dataset-cd", custom-drivers: (dataset: "<title-block>. <urldate>"))
#_sample("28 自定义软件代码仍识别下载网页", "form-software-web", custom-marks: (software: "SW"))
#_sample("29 自定义数据库代码仍识别网页式", "form-database-web", custom-marks: (database: "BX"))
#_sample("30 著者出版年制的图书形式推定出版年", "form-estimate-book", style: "author-date", date-fallback: "urldate")
#case("31 全局旧版推定年不冒充新版资源创建日期", gb7714.with(version: 2015, date-fallback: "urldate"),
  bib: DATA, cites: (<form-dataset-unknown>,), full: false, bib-args: (version: 2025))
#_sample("32 著者出版年制保留真实声明的网页年份", "form-web-year", style: "author-date")
#_sample("33 顺序编码制的真实网页年份同样保留", "form-web-year")
#case("34 模板也不把推定出版年当作创建日期", gb7714.with(version: 2015, date-fallback: "urldate",
  custom-drivers: (dataset: "<title-block>. <（date）><urldate>. <access>")),
  bib: DATA, cites: (<form-dataset-unknown>,), full: false, bib-args: (version: 2025))
#_sample("35 著者出版年制模板保留真实网页年份", "form-web-year", style: "author-date",
  custom-drivers: (online: "<title-block>. <（date）><urldate>. <access>"))
