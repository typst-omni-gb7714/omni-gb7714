#import "../../parse/field.typ"

#let edtf-year(s) = {
  if s.ends-with("~") or s.ends-with("?") or s.ends-with("%") {
    "[" + s.slice(0, -1) + "]"
  } else { s }
}

#let year(entry) = {
  let date-field = field.get(entry, "date"); let year-field = field.get(entry, "year")
  if date-field != none { edtf-year(str(date-field).split("-").first()) }
  else if year-field != none { edtf-year(str(year-field)) } else { none }
}

#let date(entry) = {
  let date-field = field.get(entry, "date"); let year-field = field.get(entry, "year")
  if date-field != none { edtf-year(str(date-field)) }
  else if year-field != none { edtf-year(str(year-field)) } else { none }
}

#let with-suffix(year, suffix) = {
  if year == none or suffix == "" { return year }
  if type(year) == str and year.starts-with("[") and year.ends-with("]") {
    year.slice(0, -1) + suffix + "]"
  } else { year + suffix }
}
