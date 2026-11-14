#import "../field.typ"
#import "../category.typ"
#import "imprint/date.typ" as publication-date

#let modified(entry, fallback-year: false, range-separator: "—") = {
  let date-field = field.get(entry, "date")
  if date-field != none {
    let parsed-date = publication-date.parsed(entry, "date")
    if parsed-date != none { return publication-date.format-parsed-date(parsed-date, range-separator: range-separator) }
  }
  if fallback-year and field.get(entry, "_omni-year-inferred-from") == none {
    let year = field.get(entry, "year")
    if year != none { return publication-date.edtf-year(str(year)) }
  }
  none
}

#let urldate(entry, show-urldate: true, version: 2015) = {
  if not show-urldate { return none }
  let urldate-value = field.get(entry, "urldate")
  if urldate-value == none { return none }
  if version == 2025 and not category.is-platform-form(entry, version: version) { return none }
  let parsed-date = publication-date.parsed(entry, "urldate")
  if parsed-date == none { return none }
  "[" + publication-date.format-date-point(if "start" in parsed-date { parsed-date.start } else { parsed-date.end }) + "]"
}
