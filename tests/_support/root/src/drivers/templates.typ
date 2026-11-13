// 内置驱动的模板表示，供手册和诊断信息直接读取。
// 键与手册中的 Typst 条目类型一致；值使用 custom-drivers 的模板语法表示。
#let built-in-templates-2025 = (
  "@book": "creator. titles<mark-medium>. editor-other. translator. edition. address：publisher，date：pages. access.",
  "@inbook": "creator. component-part-title-block. translator<{//}bookauthor|editor. booktitles：volume>. edition. address：publisher，date：pages. access.",
  "@periodical": "creator. titles<mark-medium>. <serial-block>. address：publisher，<date{—}>. access.",
  "@article": "creator. titles<mark-medium>. editor-other. translator. journaltitles，date，volume<（number）>：pages. access.",
  "@inproceedings / @conference": "creator. titles<mark-medium>//eventtitle，date：pages. access.",
  "@thesis / @mastersthesis / @phdthesis": "creator. titles<mark-medium>. address：publisher，date：pages. access.",
  "@report": "creator. titles：number<mark-medium>. date：pages. access.",
  "@standard": "number titles<mark-medium>. access.",
  "@patent": "creator. titles：number<mark-medium>. date. access.",
  "@online / @webpage": "creator. titles<mark-medium>. <（date）>urldate. access.",
  "@archive": "creator. titles：number<mark-medium>. address：publisher，date：pages. access.",
  "@map": "creator. titles<!scale => mark-medium>. <scale => scale<mark-medium>>. edition. address：publisher，date. dimensions. access.",
  "@dataset": "creator. titles<mark-medium>. version. publisher<（date）>urldate. access.",
  "@preprint": "creator. titles<mark-medium>. version. archiveprefix|eprinttype|publisher<（date）>urldate. access.",
)
