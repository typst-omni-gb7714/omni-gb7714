#import "../../parse/field.typ"

#let edtf-year(s) = {
  if s.ends-with("~") or s.ends-with("?") or s.ends-with("%") {
    "[" + s.slice(0, -1) + "]"
  } else { s }
}

#let parsed(entry, key) = entry.at("parsed_dates", default: (:)).at(key, default: none)

#let _parsed-date-year(parsed-date) = str((if "start" in parsed-date { parsed-date.start } else { parsed-date.end }).year)

#let zero-pad(number) = if number < 10 { "0" + str(number) } else { str(number) }

#let format-date-point(point) = {
  let result = str(point.year)
  if "month" in point { result += "-" + zero-pad(point.month) }
  if "day" in point { result += "-" + zero-pad(point.day) }
  result
}

#let format-parsed-date(parsed-date) = {
  let body = if parsed-date.kind == "between" { format-date-point(parsed-date.start) + "—" + format-date-point(parsed-date.end) } else if parsed-date.kind == "after" { format-date-point(parsed-date.start) + "—" } else if parsed-date.kind == "before" { "—" + format-date-point(parsed-date.end) } else { format-date-point(parsed-date.start) }
  if parsed-date.approximate or parsed-date.uncertain { "[" + body + "]" } else { body }
}

#let year(entry) = {

  let date-field = field.get(entry, "date")
  if date-field != none {
    let parsed-date = parsed(entry, "date")
    if parsed-date == none { return none }
    let year-str = _parsed-date-year(parsed-date)
    if parsed-date.approximate or parsed-date.uncertain { "[" + year-str + "]" } else { year-str }
  } else {
    let year-field = field.get(entry, "year")
    if year-field != none { edtf-year(str(year-field)) } else { none }
  }
}

#let date(entry) = {

  let date-field = field.get(entry, "date")
  if date-field != none {
    let parsed-date = parsed(entry, "date")
    if parsed-date == none { return none }
    format-parsed-date(parsed-date)
  } else {
    let year-field = field.get(entry, "year")
    if year-field != none { edtf-year(str(year-field)) } else { none }
  }
}

#let with-suffix(year, suffix) = {
  if year == none or suffix == "" { return year }
  if type(year) == str and year.starts-with("[") and year.ends-with("]") {
    year.slice(0, -1) + suffix + "]"
  } else { year + suffix }
}
