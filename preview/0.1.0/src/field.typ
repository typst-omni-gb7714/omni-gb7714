#import "sentinel.typ": *

#let _stable-dict-order(value) = {
  if type(value) == dictionary {
    let result = (:)
    for key in value.keys().sorted() { result.insert(key, _stable-dict-order(value.at(key))) }
    result
  } else if type(value) == array { value.map(_stable-dict-order) }
  else { value }
}

#let stable-name-entry(entry) = {
  let result = entry
  if "parsed_names" in result { result.parsed_names = _stable-dict-order(result.parsed_names) }
  result
}

#let get(entry, key) = {
  let value = entry.fields.at(key, default: none)
  if type(value) == str and value.trim() == "" { return none }

  if type(value) == str and value.contains(_SD) { value = value.replace(_SD, "$") }
  if type(value) == str and (value.contains(_SLBR) or value.contains(_SRBR)) { value = value.replace(_SLBR, "{").replace(_SRBR, "}") }
  value
}

#let alias(entry, real, alias) = {
  let value = get(entry, real)
  if value == none { value = get(entry, alias) }
  value
}

#let has-online(entry) = (
  get(entry, "url") != none or get(entry, "doi") != none or get(entry, "eprint") != none
)

#let use-prefix-entry(entry) = {
  let opts = entry.fields.at("options", default: none)
  if opts == none { return none }
  let options-match = str(opts).match(regex("useprefix\\s*=\\s*(true|false)"))
  if options-match == none { return none }
  options-match.captures.at(0) == "true"
}
#let use-prefix-eff(name, entry-use-prefix, global-use-prefix) = {
  let name-use-prefix = name.at("use-prefix", default: none)
  if name-use-prefix != none { return name-use-prefix == true }
  if entry-use-prefix != none { return entry-use-prefix }
  global-use-prefix
}

#let use-prefix-explicit(name, entry-use-prefix) = {
  let name-use-prefix = name.at("use-prefix", default: none)
  if name-use-prefix != none { return name-use-prefix == true }
  entry-use-prefix
}
