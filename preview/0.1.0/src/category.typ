#import "sentinel.typ": *
#import "field.typ"
#import "elements/mark-medium/built-in.typ" as mark-medium

#let _BOOK-TYPES = ("book", "mvbook", "collection", "mvcollection", "proceedings", "mvproceedings", "reference", "mvreference")

#let _is-preprint(entry) = {
  if entry.entry_type == "preprint" { return true }
  let subtype = field.get(entry, "entrysubtype")
  let pubstate = field.get(entry, "pubstate")
  if subtype != none and lower(str(subtype)) == "preprint" { return true }
  if pubstate != none and lower(str(pubstate)) == "prepublished" { return true }
  let eprint = field.get(entry, "eprint")
  let archive = field.alias(entry, "eprinttype", "archiveprefix")
  let journal = field.alias(entry, "journaltitle", "journal")
  ((eprint != none and archive != none and lower(str(archive)).starts-with("arxiv"))
    or (journal != none and lower(str(journal)).starts-with("arxiv")))
}

#let _publication-form(entry) = {
  let kind = entry.entry_type
  let code = mark-medium.mark(entry)
  let parts = ("inbook", "incollection", "inproceedings", "conference", "inreference", "suppbook", "suppcollection")
  if kind in parts { return "component-part" }
  let dedicated = code in ("D", "P", "S", "N", "A")
  if not dedicated and field.get(entry, "booktitle") != none and kind not in _BOOK-TYPES { return "component-part" }
  let journal = field.alias(entry, "journaltitle", "journal")
  if code == "CM" and (field.get(entry, "booktitle") != none or journal != none) { return "component-part" }
  if code == "N" { return "serial-newspaper" }
  if kind in _BOOK-TYPES { return "monograph" }
  if kind == "periodical" { return "serial" }
  if kind == "article" {
    if _is-preprint(entry) { return none }
    return "serial-article"
  }
  if kind == "patent" or code == "P" { return "patent" }
  if not dedicated and journal != none and not _is-preprint(entry) { return "serial-article" }
  if code in ("M", "C", "G") { return "monograph" }
  none
}

#let resource-form(entry) = {
  if _publication-form(entry) != none { return none }
  let code = mark-medium.mark(entry)
  if code == "PP" or _is-preprint(entry) { return "preprint" }
  if code in ("D", "R", "S", "P", "N", "J", "A", "CM") { return none }
  if code == "DS" or entry.entry_type == "dataset" { return "dataset" }
  if code == "EB" or entry.entry_type in mark-medium.ONLINE-TYPES { return "web" }
  if (code in ("CP", "DB") or entry.entry_type in ("software", "database")) and mark-medium.is-online(entry) { return "web" }
  none
}

#let is-platform-form(entry, version: 2015) = version == 2025 and resource-form(entry) != none

#let lacks-imprint-slot(entry) = {
  let code = mark-medium.mark(entry)
  if code in ("EB", "DB", "CP", "DS", "PP") and _publication-form(entry) != none { return false }
  code in ("A", "D", "S", "EB", "DB", "CP", "DS", "PP")
}

#let get(entry, version: 2015) = {
  let entry-type = entry.entry_type
  let _mark = mark-medium.mark(entry)
  let form = _publication-form(entry)
  if form != none and form != "monograph" { return form }
  if form == "monograph" and entry-type in _BOOK-TYPES { return form }
  if form == none and entry-type == "article" and _is-preprint(entry) {
    if version == 2025 { return "electronic" }
    return "preprint"
  }
  if form == none and entry-type in mark-medium.ONLINE-TYPES { return "electronic" }
  if form == none and _mark in ("EB", "DB", "CP", "DS") and field.get(entry, "publisher") == none { return "electronic" }
  if form == none and _mark == "Z" and field.has-online(entry) and field.get(entry, "publisher") == none { return "electronic" }

  if is-platform-form(entry, version: version) { return "electronic" }

  let _online-redirect-types = if version == 2025 { ("D", "A") } else { ("R", "D", "A") }
  if _mark in _online-redirect-types {
    let has-location = field.get(entry, "location") != none or field.get(entry, "address") != none
    let has-url = field.has-online(entry)
    if not has-location and has-url { return "electronic" }
  }
  return "monograph"
}
