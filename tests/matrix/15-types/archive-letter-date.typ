//! param: 档案 / 书信（[A]）的日期著录，版本相关
#import "/tests/_fixture/probe.typ": *
#show: spec.with(param: "档案 / 书信（[A]）日期 × 版本", controls: "`@archive` / `@letter` 的 `date`（形成日期）如何著录，随版本切换。",
  expect: [档案类（标识码 [A]）的 `date` 是*形成日期*，与出版年不同。著录形态*版本相关*：

    - *2025*：§8.12 例 [2]「武汉: 湖北省档案馆, 1931-11-07」、例 [4]「[A/OL]. 1570-07-28」——保存者后 /
      标题后接*全日期*（`YYYY-MM-DD`），平铺、不加圆括号。有保存者（`institution` / `location`）走专著式出版项、
      日期取全日期；无保存者的书信走电子资源支，形成日期平铺（不进创建 / 修改日期的圆括号）。
    - *2015*：无「保存者, 全日期平铺」格式。附录示例中脱机 [A]「…广西师范大学出版社, 2001」只出*出版年*；
      联机 [A/OL]「(2005-07-12)[2011-07-12]」的形成日期进*圆括号*、后随引用日期。故本包 2015 版档案走专著式出
      *出版年*、书信走电子资源支的*圆括号*式——即历史行为。
    - *2005*：无 [A] 码，档案 / 书信一律归*其他* [Z]（见 `_omni-mark-override`），走电子资源支，形成日期进圆括号。

    门控按 *entry_type* 精确判档案族（`archive` / `letter` / `legislation`）+ `version == 2025`，*不*用宽泛的
    `mark == "A"`：`@manual` 也判 [A]，但李泽平 .bst 把它当 [M] 图书、§8.12 无 manual 示例，故 `@manual` 仍出*年*、
    不随档案全日期；`@legislation` 两家引擎（胡振震 `typetarget=archive`、李泽平 `FUNCTION{legislation}{archive}`）
    都归 archive，故与 archive/letter 同族出全日期。2015 与 2025 不同是标准版本差异；2005 无 [A] 码天然不触发。])
#let ab = bytes("@archive{arch, author={{湖北省建设厅}}, date={1931-11-07}, institution={湖北省档案馆}, langid={chinese}, location={武汉}, number={LS031-001-0001-001}, title={关于检发实业部农工矿业团体登记规则的布告}, url={https://www.hbda.gov.cn/x.pdf}}
@letter{lett, author={Fitzwilliam, Hugh}, date={1570-07-28}, langid={british}, title={[Letter to Bess of Hardwick]}, type={Letter}, url={https://www.bessofhardwick.org/letter.jsp}}
@legislation{legis, author={{某厅}}, date={2005-07-12}, institution={某档案馆}, langid={chinese}, location={武汉}, number={LS-1}, title={某法规通知}, url={https://e.com/g}}
@manual{man, author={{某公司}}, date={2024-05-10}, organization={某公司}, langid={chinese}, location={深圳}, title={某产品说明书}}")
#case("2025：档案保存者后全日期平铺 · 书信全日期平铺（§8.12）", gb7714.with(), bib: ab, cites: (<arch>, <lett>), full: false)
#case("2025：legislation（两家引擎归 archive）随档案出全日期 · @manual（李泽平判 [M]）仍出年", gb7714.with(), bib: ab, cites: (<legis>, <man>), full: false)
#case("2015：档案出版年 · 书信圆括号（联机 [A/OL] 式）", gb7714.with(version: 2015), bib: ab, cites: (<arch>, <lett>), full: false)
#case("2005：无 [A] 码 → 归其他 [Z]，走电子资源圆括号", gb7714.with(version: 2005), bib: ab, cites: (<arch>, <lett>), full: false)
