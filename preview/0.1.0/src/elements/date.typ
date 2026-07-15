#import "../parse/field.typ"
#import "mark-medium/built-in.typ" as mark-medium
#import "imprint/date.typ" as publication-date

#let modified(entry) = {
  let date-field = field.get(entry, "date")
  if date-field != none { publication-date.edtf-year(str(date-field)) } else { none }
}

#let _URLDATE-TYPES = ("EB", "DB", "CP", "DS", "PP")

#let urldate(entry, show-urldate: true, version: 2015) = {
  if not show-urldate { return none }
  let urldate-value = field.get(entry, "urldate")
  if urldate-value == none { return none }
  if version == 2025 and mark-medium.mark(entry) not in _URLDATE-TYPES { return none }
  "[" + str(urldate-value) + "]"
}
