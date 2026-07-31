#import "csl-map.typ"

#let _normalize-label(label) = {
  let t = lower(label.trim()).replace(" ", "-")
  if t == "archive-location" { return "archive_location" }
  if t in ("doi", "isbn", "issn", "pmid", "pmcid", "url") { return upper(t) }
  t
}

#let _split-line(line) = {
  let bounds = ()
  for m in line.matches(regex("(?:^|\\s)([A-Za-z][A-Za-z _-]*?)\\s*:")) {
    let norm = _normalize-label(m.captures.at(0))
    if csl-map.classify(norm).kind != "unknown" {
      bounds.push((mstart: m.start, vstart: m.end, var: norm))
    }
  }
  if bounds.len() == 0 { return (prefix: line, recognized: ()) }
  let recognized = ()
  for (i, b) in bounds.enumerate() {
    let vend = if i + 1 < bounds.len() { bounds.at(i + 1).mstart } else { line.len() }
    recognized.push((b.var, line.slice(b.vstart, vend).trim()))
  }
  (prefix: line.slice(0, bounds.first().mstart), recognized: recognized)
}

#let enrich(entry) = {
  let fields = entry.fields
  let names = entry.parsed_names
  let dates = entry.parsed_dates

  let real-fields = fields.keys()
  let real-name-roles = names.keys()
  let real-date-keys = dates.keys()

  let note-raw = fields.at("_omni-note-raw", default: false)
  let esc(v) = if note-raw { csl-map.escape-text(v) } else { v }

  for src-key in ("note", "annotation") {
    let src = fields.at(src-key, default: none)
    if src == none or type(src) != str { continue }
    let kept = ()
    for line in src.split("\n") {
      let (prefix, recognized) = _split-line(line)
      if recognized.len() == 0 { kept.push(line); continue }
      if prefix.trim() != "" { kept.push(prefix) }
      for (var, value) in recognized {
        if value == "" { continue }
        let route = csl-map.classify(var)

        let target = if route.kind == "lang" { "langid" } else if route.kind == "pmid" { "eprint" } else if route.kind == "container" { csl-map.container-field(entry.entry_type) } else { route.key }
        let occupied = if route.kind == "name" { target in real-name-roles } else if route.kind == "date" { target in real-date-keys or target in real-fields } else { target in real-fields }
        if occupied { continue }

        if route.kind == "name" {
          let arr = names.at(target, default: ())
          arr.push(csl-map.parse-name-string(value))
          names.insert(target, arr)
          fields.insert(target, csl-map.name-string(arr))
        } else if route.kind == "date" {
          let (parsed, raw) = csl-map.parse-date-string(value)
          if parsed != none { dates.insert(target, parsed) } else { let _ = dates.remove(target, default: none) }
          fields.insert(target, raw)
        } else if route.kind == "pmid" {
          fields.insert("eprint", value)
          if "eprinttype" not in real-fields { fields.insert("eprinttype", "pmid") }
        } else if route.kind == "lang" {
          fields.insert("langid", csl-map.map-lang(value))
        } else if route.kind == "raw" {
          fields.insert(target, value)
        } else {

          fields.insert(target, esc(value))
        }
      }
    }

    let leftover = kept.join("\n", default: "").trim()
    if leftover == "" { let _ = fields.remove(src-key, default: none) } else { fields.insert(src-key, esc(leftover)) }
  }
  let _ = fields.remove("_omni-note-raw", default: none)

  let e = entry
  e.fields = fields
  e.parsed_names = names
  e.parsed_dates = dates
  e
}
