#import "@preview/jurlstify:0.3.1": jurlstify as _jurlstify
#import "../sentinel.typ": *
#import "../field.typ"
#import "mark-medium/built-in.typ" as mark-medium

#import "../punct/built-in.typ": get as _punct, field-text as _field-text
#import "pids/built-in.typ": eprint-prefix as _eprint-prefix, resolve-eprint as _resolve-eprint, colon as _pid-colon, effective as _pid-effective
#import "pids/built-in.typ": resolve-doi as _resolve-doi, resolve-cstr as _resolve-cstr, pid-name-order as _pid-name-order
#import "pids/custom.typ": strip-label-prefix as _strip-label-prefix, label-text as _pid-label-text, resolve-custom as _resolve-custom-pid, emit as _emit-custom-pid

#let _break-url(url-value, every, hyphen, at-delimiters) = _jurlstify(
  str(url-value),
  extra-break-every: every,
  show-hyphens-at-extra-breaks: hyphen,
  show-hyphens-after-delimiters: hyphen and at-delimiters,
)

#let access(entry, show-url: true, hyperlink: true, show-pid: (:), pid-priority: (), dedup-url-pid: true, custom-pids: (:), punct-style: "half-with-space", custom-punct: (:), pid-colon-style: auto, url-break-every: 1, url-break-hyphen: true, url-break-hyphen-at-delimiters: true, version: 2015) = {
  let show-url = mark-medium.gate(show-url, entry, version: version)
  let p = name => _punct(name, entry, punct-style, custom-punct)
  let _brk = s => _break-url(str(s), url-break-every, url-break-hyphen, url-break-hyphen-at-delimiters)
  let _link-fn = (target, body) => if hyperlink and target != none { link(target, body) } else { body }
  let parts = ()
  let _bov = name => if type(custom-pids) == dictionary and name in custom-pids and type(custom-pids.at(name)) == dictionary { custom-pids.at(name) } else { (:) }
  let _bfield = (name, dflt) => _bov(name).at("field", default: dflt)
  let url = field.get(entry, "url")
  let doi = field.get(entry, _bfield("doi", "doi")); let cstr = field.get(entry, _bfield("cstr", "cstr")); let eprint = field.get(entry, _bfield("eprint", "eprint"))
  let isbn = field.get(entry, _bfield("isbn", "isbn")); let issn = field.get(entry, _bfield("issn", "issn"))

  let url-str = if show-url and url != none { str(url) } else { "" }

  if version == 2025 and url == none and eprint != none {
    let prefix = _eprint-prefix(entry)
    let eprint-value = _strip-label-prefix(eprint, prefix)
    let synthesized = _resolve-eprint(entry, eprint-value, custom-pids: custom-pids)
    if synthesized != none {
      url = synthesized
      url-str = if show-url { str(url) } else { "" }
    }
  }
  if show-url and url != none {
    parts.push(_link-fn(str(url), _brk(url)))
  }

  let _pid-off-2005 = version == 2005
  let _default-show = (
    doi: not _pid-off-2005,
    cstr: version == 2025,

    eprint: not _pid-off-2005,
    isbn: false,
    issn: false,
  )

  let pcolon = _pid-colon(entry, punct-style, custom-punct, pid-colon-style: pid-colon-style)

  let _label = (name, dflt) => _pid-label-text(_bov(name), entry, dflt)
  let _resolve = (name, value, built-in-target) => {
    let ov = _bov(name)
    if ov.at("resolver", default: none) != none { _resolve-custom-pid(ov, value) } else { built-in-target }
  }
  let _effective(name, value) = _pid-effective(name, value, show-pid, url-str, _default-show.at(name), entry: entry, custom-pids: custom-pids, dedup-url-pid: dedup-url-pid, version: version)
  let _emit-built-in(name) = {
    if name == "doi" and _effective("doi", doi) {
      _link-fn(_resolve("doi", doi, _resolve-doi(doi)), [#(_label("doi", "DOI"))#pcolon#(_brk(doi))])
    } else if name == "cstr" and _effective("cstr", cstr) {
      let cstr-value = _strip-label-prefix(cstr, _label("cstr", "CSTR"))
      _link-fn(_resolve("cstr", cstr-value, _resolve-cstr(cstr-value)), [#(_label("cstr", "CSTR"))#pcolon#(_brk(cstr-value))])
    } else if name == "eprint" and _effective("eprint", eprint) {
      let prefix = _eprint-prefix(entry)
      let prefix-text = if prefix != none { prefix } else { "eprint" }
      let eprint-value = _strip-label-prefix(eprint, prefix-text)
      _link-fn(_resolve("eprint", eprint-value, _resolve-eprint(entry, eprint-value, custom-pids: custom-pids)), [#(_label("eprint", prefix-text))#pcolon#eprint-value])
    } else if name == "isbn" and _effective("isbn", isbn) {
      _link-fn(_resolve("isbn", isbn, none), [#(_label("isbn", "ISBN"))#pcolon#_field-text(entry, _bfield("isbn", "isbn"))])
    } else if name == "issn" and _effective("issn", issn) {
      _link-fn(_resolve("issn", issn, none), [#(_label("issn", "ISSN"))#pcolon#_field-text(entry, _bfield("issn", "issn"))])
    } else { none }
  }

  let _custom-effective(name, value) = _pid-effective(name, value, show-pid, url-str, not _pid-off-2005, entry: entry, custom-pids: custom-pids, dedup-url-pid: dedup-url-pid, version: version)
  let _emit-custom(term-name) = _emit-custom-pid(term-name, custom-pids, entry, _custom-effective, pcolon, _brk, _link-fn)

  let max-pids = show-pid.at("max", default: none)
  let quota = if max-pids == none { none } else { calc.max(0, int(max-pids)) }

  if quota == none or quota > 0 {
    let emitted = 0
    for name in _pid-name-order(pid-priority, custom-pids) {
      let item = if name in ("doi", "cstr", "eprint", "isbn", "issn") {
        _emit-built-in(name)
      } else {
        _emit-custom(name)
      }
      if item != none {
        parts.push(item)
        emitted += 1
        if quota != none and emitted >= quota { break }
      }
    }
  }

  if parts.len() > 0 { parts.join(p("period")) } else { none }
}
