// 每组数据与手册中紧随其后的第一条标准示例对应。
// CSL JSON 展示交换格式中的等价字段，不表示建议用户手写 JSON。
#let entry-data-examples-2025 = (
  "图书": (
    bib: ```bib
@book{zhang2002,
  author = {张伯伟},
  title = {全唐五代诗格汇考},
  location = {南京},
  publisher = {江苏古籍出版社},
  date = {2002},
  pages = {288},
}
```,
    csl: ```json
{
  "id": "zhang2002",
  "type": "book",
  "author": [{"literal": "张伯伟"}],
  "title": "全唐五代诗格汇考",
  "publisher-place": "南京",
  "publisher": "江苏古籍出版社",
  "issued": {"date-parts": [[2002]]},
  "page": "288"
}
```,
  ),
  "图书中的析出文献": (
    bib: ```bib
@inbook{zhouyi2011,
  title = {周易外传: 卷5},
  bookauthor = {王夫之},
  booktitle = {船山全书: 第1册},
  edition = {修订版},
  location = {长沙},
  publisher = {岳麓书社},
  date = {2011},
  pages = {983-1029},
}
```,
    csl: ```json
{
  "id": "zhouyi2011",
  "type": "chapter",
  "title": "周易外传: 卷5",
  "container-title": "船山全书: 第1册",
  "container-author": [{"literal": "王夫之"}],
  "edition": "修订版",
  "publisher-place": "长沙",
  "publisher": "岳麓书社",
  "issued": {"date-parts": [[2011]]},
  "page": "983-1029"
}
```,
  ),
  "连续出版物": (
    bib: ```bib
@periodical{lcnk,
  editor = {中华医学会湖北分会},
  title = {临床内科杂志},
  volume = {1-},
  number = {1-},
  location = {武汉},
  publisher = {中华医学会湖北分会},
  date = {1984/..},
}
```,
    csl: ```json
{
  "id": "lcnk",
  "type": "periodical",
  "editor": [{"literal": "中华医学会湖北分会"}],
  "title": "临床内科杂志",
  "volume": "1-",
  "issue": "1-",
  "publisher-place": "武汉",
  "publisher": "中华医学会湖北分会",
  "issued": {"literal": "1984/.."}
}
```,
  ),
  "连续出版物中的析出文献": (
    bib: ```bib
@article{yu2012,
  author = {于潇 and 刘义 and others},
  title = {互联网药品可信交易环境中主体资质审核备案模式},
  journaltitle = {清华大学学报 (自然科学版)},
  date = {2012},
  volume = {52},
  number = {11},
  pages = {1518-1523},
}
```,
    csl: ```json
{
  "id": "yu2012",
  "type": "article-journal",
  "author": [{"literal": "于潇"}, {"literal": "刘义"}, {"literal": "柴跃廷"}],
  "title": "互联网药品可信交易环境中主体资质审核备案模式",
  "container-title": "清华大学学报 (自然科学版)",
  "issued": {"date-parts": [[2012]]},
  "volume": "52",
  "issue": "11",
  "page": "1518-1523"
}
```,
  ),
  "会议录": (
    bib: ```bib
@inproceedings{li2022,
  author = {李妍 and 王莹},
  title = {医疗机构保洁人员“一前五后”手卫生干预效果研究},
  eventtitle = {中华预防医学会医院感染控制分会第31次全国医院感染学术年会},
  date = {2022},
  pages = {2},
}
```,
    csl: ```json
{
  "id": "li2022",
  "type": "paper-conference",
  "author": [{"literal": "李妍"}, {"literal": "王莹"}],
  "title": "医疗机构保洁人员‘一前五后’手卫生干预效果研究",
  "event-title": "中华预防医学会医院感染控制分会第31次全国医院感染学术年会",
  "issued": {"date-parts": [[2022]]},
  "page": "2"
}
```,
  ),
  "学位论文": (
    bib: ```bib
@thesis{wang2022,
  author = {王琦},
  title = {融合星载GNSS-R和SAR数据的高时空分辨率土壤湿度反演方法研究},
  location = {武汉},
  institution = {武汉大学},
  date = {2022},
  pages = {87},
}
```,
    csl: ```json
{
  "id": "wang2022",
  "type": "thesis",
  "author": [{"literal": "王琦"}],
  "title": "融合星载GNSS-R和SAR数据的高时空分辨率土壤湿度反演方法研究",
  "publisher-place": "武汉",
  "publisher": "武汉大学",
  "issued": {"date-parts": [[2022]]},
  "page": "87"
}
```,
  ),
  "报告": (
    bib: ```bib
@report{tang2013,
  author = {汤万金 and 杨跃翔 and 刘文 and others},
  title = {人体安全重要技术标准研制最终报告},
  number = {7178999X-2006BAK04A10/10.2013},
  date = {2013-09-30},
  url = {http://www.nstrs.cn/xiangxiBG.aspx?id=41707},
}
```,
    csl: ```json
{
  "id": "tang2013",
  "type": "report",
  "author": [{"literal": "汤万金"}, {"literal": "杨跃翔"}, {"literal": "刘文"}],
  "title": "人体安全重要技术标准研制最终报告",
  "number": "7178999X-2006BAK04A10/10.2013",
  "issued": {"date-parts": [[2013, 9, 30]]},
  "URL": "http://www.nstrs.cn/xiangxiBG.aspx?id=41707"
}
```,
  ),
  "标准": (
    bib: ```bib
@standard{gbt3792,
  number = {GB/T 3792—2021},
  title = {信息与文献 资源描述},
}
```,
    csl: ```json
{
  "id": "gbt3792",
  "type": "standard",
  "number": "GB/T 3792—2021",
  "title": "信息与文献 资源描述"
}
```,
  ),
  "专利": (
    bib: ```bib
@patent{deng2008,
  author = {邓一刚},
  title = {全智能节电器},
  number = {CN200610171314.3},
  date = {2008-01-16},
  pages = {8-9},
}
```,
    csl: ```json
{
  "id": "deng2008",
  "type": "patent",
  "author": [{"literal": "邓一刚"}],
  "title": "全智能节电器",
  "number": "CN200610171314.3",
  "issued": {"date-parts": [[2008, 1, 16]]},
  "page": "8-9"
}
```,
  ),
  "网站、网页": (
    bib: ```bib
@online{chnmuseum,
  title = {中国国家博物馆},
  urldate = {2025-05-06},
  url = {https://www.chnmuseum.cn/},
}
```,
    csl: ```json
{
  "id": "chnmuseum",
  "type": "webpage",
  "title": "中国国家博物馆",
  "accessed": {"date-parts": [[2025, 5, 6]]},
  "URL": "https://www.chnmuseum.cn/"
}
```,
  ),
  "档案": (
    bib: ```bib
@archive{li1887,
  author = {李鸿章},
  title = {奏请上海道库洋务外销要款无款可筹仍拨药厘接济事},
  number = {04-01-35-0399-039},
  location = {北京},
  institution = {中国第一历史档案馆},
  date = {1887},
}
```,
    csl: ```json
{
  "id": "li1887",
  "type": "manuscript",
  "author": [{"literal": "李鸿章"}],
  "title": "奏请上海道库洋务外销要款无款可筹仍拨药厘接济事",
  "archive_location": "04-01-35-0399-039",
  "archive-place": "北京",
  "archive": "中国第一历史档案馆",
  "issued": {"date-parts": [[1887]]}
}
```,
  ),
  "地图": (
    bib: ```bib
@map{hu2021,
  author = {胡健民},
  title = {东南极拉斯曼丘陵地区地质图},
  scale = {1: 25 000},
  location = {北京},
  publisher = {科学出版社},
  date = {2021},
  dimensions = {128 cm×84 cm},
}
```,
    csl: ```json
{
  "id": "hu2021",
  "type": "map",
  "author": [{"literal": "胡健民"}],
  "title": "东南极拉斯曼丘陵地区地质图",
  "scale": "1: 25 000",
  "publisher-place": "北京",
  "publisher": "科学出版社",
  "issued": {"date-parts": [[2021]]},
  "dimensions": "128 cm×84 cm"
}
```,
  ),
  "数据集": (
    bib: ```bib
@dataset{zhou2023,
  author = {周壮 and 李盛阳 and 吴薇 and others},
  title = {天宫二号遥感图像自然景物分类科学数据},
  version = {V1.0},
  publisher = {国家基础学科公共科学数据中心},
  date = {2023-09-10},
  urldate = {2025-07-15},
  url = {https://www.nbsdc.cn/general/dataLinks/},
  cstr = {16666.11.nbsdc.tfpbwtqf},
}
```,
    csl: ```json
{
  "id": "zhou2023",
  "type": "dataset",
  "author": [{"literal": "周壮"}, {"literal": "李盛阳"}, {"literal": "吴薇"}],
  "title": "天宫二号遥感图像自然景物分类科学数据",
  "version": "V1.0",
  "publisher": "国家基础学科公共科学数据中心",
  "issued": {"date-parts": [[2023, 9, 10]]},
  "accessed": {"date-parts": [[2025, 7, 15]]},
  "URL": "https://www.nbsdc.cn/general/dataLinks/",
  "note": "CSTR: 16666.11.nbsdc.tfpbwtqf"
}
```,
  ),
  "预印本": (
    bib: ```bib
@preprint{xiao2024,
  author = {肖玲 and 张雪 and 王永},
  title = {数据要素的统计测算方法探究},
  publisher = {PSSXiv},
  date = {2024-07-02},
  urldate = {2024-09-30},
  url = {https://zsyyb.cn/abs/202408.01096},
  cstr = {32012.36.PSSXiv.202408.01096},
}
```,
    csl: ```json
{
  "id": "xiao2024",
  "type": "article",
  "author": [{"literal": "肖玲"}, {"literal": "张雪"}, {"literal": "王永"}],
  "title": "数据要素的统计测算方法探究",
  "publisher": "PSSXiv",
  "issued": {"date-parts": [[2024, 7, 2]]},
  "accessed": {"date-parts": [[2024, 9, 30]]},
  "URL": "https://zsyyb.cn/abs/202408.01096",
  "note": "CSTR: 32012.36.PSSXiv.202408.01096"
}
```,
  ),
)
