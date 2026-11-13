#let _to-int(s, ctx) = {
  let t = s.trim()
  assert(t.match(regex("^-?[0-9]+$")) != none,
    message: "quan: invalid number \"" + t + "\" in range string \"" + ctx + "\"")
  int(t)
}

#let _parse-int-ranges(s) = {
  let result = ()
  for part in s.split(",") {
    let p = part.trim()
    if p == "" { continue }

    let body = if p.starts-with("-") { p.slice(1) } else { p }
    let dash = body.position("-")
    if dash != none {
      let cut = dash + (p.len() - body.len())
      let a = _to-int(p.slice(0, cut), s)
      let b = _to-int(p.slice(cut + 1), s)
      assert(a <= b, message: "quan: invalid range \"" + p + "\" (start > end)")
      for i in range(a, b + 1) { result.push(i) }
    } else {
      result.push(_to-int(p, s))
    }
  }
  result
}

#let _u(n) = calc.rem(n, 10)
#let _t(n) = calc.floor(n / 10)

#let _weight-num(w) = {
  if type(w) == int { w } else {
    (thin: 100, extralight: 200, light: 300, regular: 400, medium: 500,
     semibold: 600, bold: 700, extrabold: 800, black: 900).at(w, default: 400)
  }
}

#let _quan-state = state("quan", (
  digits: range(1, 11),
))

#let _FONT-CLASS = (

  "simsun": "song", "nsimsun": "song", "simhei": "song", "kaiti": "song", "fangsong": "song",
  "songti sc": "song", "stsong": "song", "stsongti": "song", "kaiti sc": "song", "stfangsong": "song",
  "fandolsong": "song", "fandolhei": "song", "fandolkai": "song", "fandolfang": "song",
  "fzshusong-z01": "song", "fzhei-b01": "song", "fzkai-z03": "song", "fzfangsong-z02": "song",
  "宋体": "song", "黑体": "song", "楷体": "song", "仿宋": "song",

  "noto serif cjk sc": "wide", "noto serif cjk tc": "wide", "noto serif cjk jp": "wide", "noto serif cjk kr": "wide",
  "noto sans cjk sc": "wide", "noto sans cjk tc": "wide", "noto sans cjk jp": "wide", "noto sans cjk kr": "wide",
  "source han serif sc": "wide", "source han sans sc": "wide", "source han serif": "wide", "source han sans": "wide",
  "heiti sc": "wide", "hiragino sans gb": "wide",

  "noto serif": "wide", "noto sans": "wide", "source serif": "wide", "source sans": "wide",
  "source serif 4": "wide", "source sans 3": "wide", "source serif pro": "wide", "source sans pro": "wide",

  "times new roman": "latin", "times": "latin", "tex gyre termes": "latin", "libertinus serif": "latin",
  "new computer modern": "latin", "stix two text": "latin",
)

#let _RULE-SINGLE = (values: range(0, 10), style: (inset: (x: 0.25em, y: 0.015em)))

#let _RULES = (

  song: (

    (values: range(0, 10),
     style:  (inset: (x: 0.25em, y: 0.015em))),

    (values: (11,),
     style:  (inset: (x: 0.09em, y: 0.015em), kern: -0.15em)),

    (values: (12, 21),
     style:  (inset: (x: 0.09em, y: 0.015em), kern: -0.125em)),

    (values: range(10, 20).filter(n => _u(n) != 1 and _u(n) != 2) + range(20, 100).filter(n => _u(n) == 1 and _t(n) >= 3),
     style:  (inset: (x: 0.08em, y: 0.015em), kern: -0.125em)),

    (values: range(20, 100).filter(n => _u(n) != 1),
     style:  (inset: (x: 0.07em, y: 0.015em), kern: -0.1em)),
  ),

  wide: (
    _RULE-SINGLE,
    (values: range(10, 100),
     style:  (size: 0.72em, kern: 0em, inset: (x: 0.05em, y: 0.04em))),
  ),

  "latin-song": (
    _RULE-SINGLE,
    (values: (11,),
     style:  (kern: -0.06em, inset: (x: 0.05em, y: 0.025em))),
    (values: range(10, 100).filter(n => n != 11),
     style:  (kern: -0.05em, inset: (x: 0.05em, y: 0.025em))),
  ),

  "latin-wide": (
    _RULE-SINGLE,
    (values: range(10, 100),
     style:  (size: 0.78em, kern: -0.06em, inset: (x: 0.05em, y: 0.04em))),
  ),
)

#let _covers-char(entry, ch) = {
  if type(entry) != dictionary { return true }
  let c = entry.at("covers", default: none)
  if c == none { return true }
  if c == "latin-in-cjk" { return ch.match(regex("[\u{0}-\u{2FF}]")) != none }
  ch.match(c) != none
}

#let _class-of(entry) = {
  let name = if type(entry) == dictionary { entry.at("name", default: "") } else { entry }
  _FONT-CLASS.at(lower(str(name)), default: none)
}

#let _pick-rules(font) = {
  let stack = if type(font) == array { font } else { (font,) }
  let digit-entry = stack.find(f => _covers-char(f, "0"))
  let digit = if digit-entry == none { none } else { _class-of(digit-entry) }
  let circle = stack.filter(f => _covers-char(f, "①")).map(_class-of).find(c => c == "song" or c == "wide")

  let digit = if digit == none and circle != none { "latin" } else { digit }
  if digit == "song" { (cap: 0.684, rules: _RULES.song) }
  else if digit == "wide" { (cap: 0.733, rules: _RULES.wide) }
  else if digit == "latin" and circle == "wide" { (cap: 0.662, rules: _RULES.at("latin-wide")) }
  else if digit == "latin" { (cap: 0.662, rules: _RULES.at("latin-song")) }
  else { (cap: 0.684, rules: _RULES.song) }
}

#let _DIGIT-FIT = (
  "fandolsong": (
    "fandolsong": (
      regular: (
        "single-1": (1.0000, 0.6400, +0.0000, +0.0200, 1.000, 1.000),
        "single": (1.0000, 0.6600, +0.0000, +0.0300, 1.000, 1.000),
        "all-ones": (0.7485, 0.6600, +0.0175, +0.0300, 0.688, 0.872),
        "two-with-1": (0.7485, 0.6600, +0.0175, +0.0300, 0.611, 0.780),
        "two": (0.7485, 0.6600, +0.0175, +0.0300, 0.611, 0.780),
      ),
      bold: (
        "single-1": (1.0000, 0.6300, +0.0000, -0.0350, 1.000, 1.000),
        "single": (1.0000, 0.6400, +0.0000, -0.0300, 1.000, 1.000),
        "all-ones": (0.7485, 0.6600, +0.0175, +0.0300, 0.587, 0.796),
        "two-with-1": (0.7485, 0.6600, +0.0175, +0.0300, 0.546, 0.712),
        "two": (0.7485, 0.6600, +0.0175, +0.0300, 0.546, 0.712),
      ),
    ),
  ),
  "fzshusong-z01s": (
    "fzshusong-z01s": (
      regular: (
        "single-1": (1.1636, 0.6923, +0.0000, +0.0055, 1.000, 1.000),
        "single": (1.0430, 0.7060, +0.0000, +0.0069, 0.878, 1.000),
      ),
      bold: (
        "single-1": (1.1636, 0.6923, +0.0000, +0.0055, 1.000, 1.000),
        "single": (1.0430, 0.7060, +0.0000, +0.0069, 0.747, 1.000),
      ),
    ),
  ),
  "heiti sc": (
    "heiti sc": (
      regular: (
        "single-1": (1.2821, 0.7167, -0.0861, -0.0139, 0.877, 1.000),
        "single": (0.9124, 0.7389, -0.0083, +0.0028, 0.877, 1.000),
        "all-ones": (0.6339, 0.6722, -0.0139, -0.0028, 0.966, 1.000),
        "two-with-1": (0.6339, 0.6722, -0.0139, -0.0028, 0.719, 0.717),
        "two": (0.6339, 0.6722, -0.0139, -0.0028, 0.719, 0.717),
      ),
      bold: (
        "single-1": (1.2821, 0.7167, -0.0861, -0.0139, 0.725, 1.000),
        "single": (0.9124, 0.7389, -0.0083, +0.0028, 0.725, 0.983),
        "all-ones": (0.6339, 0.6722, -0.0139, -0.0028, 0.865, 1.000),
        "two-with-1": (0.6339, 0.6722, -0.0139, -0.0028, 0.650, 0.801),
        "two": (0.6339, 0.6722, -0.0139, -0.0028, 0.650, 0.801),
      ),
    ),
  ),
  "libertinus serif": (
    "libertinus": (
      regular: (
        "single-1": (0.6727, 0.5984, +0.0079, -0.0118, 1.000, 1.000),
        "single": (0.6489, 0.6063, +0.0098, -0.0118, 1.000, 1.000),
        "all-ones": (0.5103, 0.5984, +0.0039, -0.0118, 0.888, 1.000),
        "two-with-1": (0.5392, 0.6102, +0.0295, -0.0118, 0.610, 0.798),
        "two": (0.5392, 0.6102, +0.0295, -0.0118, 0.610, 0.798),
      ),
      bold: (
        "single-1": (0.6486, 0.5033, -0.0098, +0.0000, 1.000, 1.000),
        "single": (0.6525, 0.5033, -0.0016, +0.0016, 1.000, 1.000),
        "all-ones": (0.5318, 0.5033, -0.0131, +0.0000, 0.967, 1.000),
        "two-with-1": (0.5896, 0.5033, +0.0000, +0.0000, 0.859, 0.963),
        "two": (0.6087, 0.5098, +0.0196, -0.0033, 0.788, 0.882),
      ),
    ),
  ),
  "noto sans cjk sc": (
    "noto sans cjk": (
      regular: (
        "single-1": (0.4615, 0.5531, -0.0335, -0.0056, 1.000, 1.000),
        "single": (0.8117, 0.5754, +0.0000, -0.0084, 1.000, 1.000),
        "all-ones": (0.4565, 0.5531, -0.0335, -0.0056, 1.000, 1.000),
        "two-with-1": (0.5798, 0.5754, -0.0084, -0.0084, 1.000, 1.000),
        "two": (0.6164, 0.5810, +0.0000, -0.0084, 0.914, 1.000),
      ),
      bold: (
        "single-1": (0.5349, 0.5580, -0.0331, -0.0055, 1.000, 1.000),
        "single": (0.8135, 0.5746, +0.0014, -0.0055, 1.000, 1.000),
        "all-ones": (0.4774, 0.5580, -0.0304, -0.0055, 1.000, 1.000),
        "two-with-1": (0.5767, 0.5746, -0.0138, -0.0055, 0.821, 0.944),
        "two": (0.6019, 0.5801, +0.0000, -0.0055, 0.832, 0.939),
      ),
    ),
  ),
  "noto serif cjk sc": (
    "noto serif cjk": (
      regular: (
        "single-1": (0.8986, 0.5674, -0.0056, -0.0140, 1.000, 1.000),
        "single": (0.8104, 0.5730, +0.0028, -0.0084, 1.000, 1.000),
        "all-ones": (0.6101, 0.5674, -0.0028, -0.0140, 1.000, 1.000),
        "two-with-1": (0.6086, 0.5758, +0.0084, -0.0098, 1.000, 1.000),
        "two": (0.6406, 0.5787, -0.0042, -0.0084, 0.911, 0.974),
      ),
      bold: (
        "single-1": (0.8889, 0.5611, -0.0056, -0.0139, 1.000, 1.000),
        "single": (0.7905, 0.5722, +0.0000, -0.0056, 1.000, 1.000),
        "all-ones": (0.6358, 0.5611, -0.0028, -0.0139, 1.000, 1.000),
        "two-with-1": (0.6027, 0.5722, +0.0069, -0.0083, 0.945, 1.000),
        "two": (0.6097, 0.5722, -0.0042, -0.0083, 0.819, 0.924),
      ),
    ),
    "times": (
      regular: (
        "single-1": (1.2400, 0.5674, -0.0056, -0.0140, 1.000, 1.000),
        "single": (0.9034, 0.5730, +0.0028, -0.0084, 1.000, 1.000),
        "all-ones": (0.6978, 0.5674, -0.0028, -0.0140, 1.000, 1.000),
        "two-with-1": (0.6556, 0.5758, +0.0084, -0.0098, 0.962, 1.000),
        "two": (0.7028, 0.5787, -0.0042, -0.0084, 0.901, 0.960),
      ),
      bold: (
        "single-1": (0.9412, 0.5611, -0.0056, -0.0139, 1.000, 1.000),
        "single": (0.9146, 0.5722, +0.0000, -0.0056, 1.000, 1.000),
        "all-ones": (0.6688, 0.5611, -0.0028, -0.0139, 1.000, 1.000),
        "two-with-1": (0.6531, 0.5722, +0.0069, -0.0083, 0.848, 0.975),
        "two": (0.7111, 0.5722, -0.0042, -0.0083, 0.811, 0.915),
      ),
    ),
  ),
  "simsun": (
    "courier": (
      regular: (
        "single-1": (0.7222, 0.5989, +0.0000, +0.0028, 1.000, 1.000),
        "single": (1.0959, 0.6130, -0.0056, +0.0000, 1.000, 1.000),
        "all-ones": (0.5213, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two-with-1": (0.5213, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two": (0.5213, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
      ),
      bold: (
        "single-1": (0.6190, 0.5989, +0.0000, +0.0028, 1.000, 1.000),
        "single": (0.9589, 0.6130, -0.0056, +0.0000, 1.000, 1.000),
        "all-ones": (0.4925, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two-with-1": (0.4925, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two": (0.4925, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
      ),
    ),
    "simsun": (
      regular: (
        "single-1": (0.9455, 0.5989, +0.0000, +0.0028, 1.000, 1.000),
        "single": (1.0998, 0.6130, -0.0056, +0.0000, 1.000, 1.000),
        "all-ones": (0.6125, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two-with-1": (0.6125, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two": (0.6125, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
      ),
      bold: (
        "single-1": (0.9455, 0.5989, +0.0000, +0.0028, 1.000, 1.000),
        "single": (1.0998, 0.6130, -0.0056, +0.0000, 1.000, 1.000),
        "all-ones": (0.6125, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two-with-1": (0.6125, 0.6045, +0.0141, -0.0056, 0.945, 1.000),
        "two": (0.6125, 0.6045, +0.0141, -0.0056, 0.945, 1.000),
      ),
    ),
    "times": (
      regular: (
        "single-1": (1.0400, 0.5989, +0.0000, +0.0028, 1.000, 1.000),
        "single": (1.0123, 0.6130, -0.0056, +0.0000, 1.000, 1.000),
        "all-ones": (0.6049, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two-with-1": (0.6049, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two": (0.6049, 0.6045, +0.0141, -0.0056, 0.964, 1.000),
      ),
      bold: (
        "single-1": (0.7647, 0.5989, +0.0000, +0.0028, 1.000, 1.000),
        "single": (1.0060, 0.6130, -0.0056, +0.0000, 1.000, 1.000),
        "all-ones": (0.5698, 0.6045, +0.0141, -0.0056, 1.000, 1.000),
        "two-with-1": (0.5698, 0.6045, +0.0141, -0.0056, 0.945, 1.000),
        "two": (0.5698, 0.6045, +0.0141, -0.0056, 0.945, 1.000),
      ),
    ),
  ),
  "songti sc": (
    "songti sc": (
      regular: (
        "single-1": (1.2909, 0.7039, +0.0028, -0.0307, 1.000, 1.000),
        "single": (1.0000, 0.7039, +0.0000, -0.0140, 1.000, 1.000),
        "all-ones": (0.7862, 0.7062, +0.0000, -0.0282, 0.882, 1.000),
        "two-with-1": (0.7143, 0.7401, +0.0056, -0.0169, 0.646, 0.748),
        "two": (0.7143, 0.7401, +0.0056, -0.0169, 0.550, 0.681),
      ),
      bold: (
        "single-1": (0.9167, 0.7017, -0.0166, -0.0166, 1.000, 1.000),
        "single": (1.0310, 0.7348, -0.0083, +0.0000, 0.867, 1.000),
        "all-ones": (0.6400, 0.6906, -0.0028, -0.0166, 0.942, 1.000),
        "two-with-1": (0.6605, 0.7072, +0.0221, -0.0069, 0.571, 0.783),
        "two": (0.6824, 0.7017, +0.0193, -0.0166, 0.459, 0.682),
      ),
    ),
  ),
)

#let _FIT-ALIASES = (
  "simsun": "simsun", "nsimsun": "simsun",
  "libertinus serif": "libertinus serif",
  "noto serif cjk sc": "noto serif cjk sc",
  "noto serif cjk tc": "noto serif cjk sc",
  "noto serif cjk jp": "noto serif cjk sc",
  "noto serif cjk kr": "noto serif cjk sc",
  "source han serif sc": "noto serif cjk sc",
  "source han serif": "noto serif cjk sc",
  "noto sans cjk sc": "noto sans cjk sc",
  "noto sans cjk tc": "noto sans cjk sc",
  "noto sans cjk jp": "noto sans cjk sc",
  "noto sans cjk kr": "noto sans cjk sc",
  "source han sans sc": "noto sans cjk sc",
  "source han sans": "noto sans cjk sc",
  "songti sc": "songti sc",
  "fzshusong-z01s": "fzshusong-z01s",
  "fandolsong": "fandolsong",
  "heiti sc": "heiti sc",
)

#let _FIT-DIGIT-ALIASES = (
  "simsun": "simsun", "nsimsun": "simsun",
  "times new roman": "times", "times": "times", "tex gyre termes": "times",
  "courier new": "courier", "courier": "courier",
  "libertinus serif": "libertinus",
  "noto serif cjk sc": "noto serif cjk",
  "noto serif cjk tc": "noto serif cjk",
  "noto serif cjk jp": "noto serif cjk",
  "noto serif cjk kr": "noto serif cjk",
  "source han serif sc": "noto serif cjk",
  "source han serif": "noto serif cjk",
  "noto sans cjk sc": "noto sans cjk",
  "noto sans cjk tc": "noto sans cjk",
  "noto sans cjk jp": "noto sans cjk",
  "noto sans cjk kr": "noto sans cjk",
  "source han sans sc": "noto sans cjk",
  "source han sans": "noto sans cjk",
  "songti sc": "songti sc",
  "fzshusong-z01s": "fzshusong-z01s",
  "fandolsong": "fandolsong",
  "heiti sc": "heiti sc",
)

#let _CIRCLE-STROKES = (
  "simsun": (0.03530, 0.03530),
  "libertinus serif": (0.05589, 0.06587),
  "noto serif cjk sc": (0.03123, 0.03553),
  "noto sans cjk sc": (0.03412, 0.03910),
  "songti sc": (0.03421, 0.06352),
  "fzshusong-z01s": (0.02877, 0.02877),
  "fandolsong": (0.03827, 0.03829),
  "heiti sc": (0.06343, 0.06343),
  "pingfang sc": (0.03815, 0.04839),
  "microsoft yahei": (0.06483, 0.06483),
  "simhei": (0.04881, 0.04881),
  "kaiti": (0.04881, 0.04881),
  "fangsong": (0.03513, 0.03513),
  "hiragino sans gb": (0.03450, 0.04383),
  "stsong": (0.02805, 0.02805),
)

#let _circle-family(font, reference) = {
  let stack = if type(font) == array { font } else { (font,) }
  for f in stack {
    if not _covers-char(f, reference) { continue }
    let name = lower(if type(f) == dictionary { f.at("name", default: "") } else { str(f) })
    let family = _FIT-ALIASES.at(name, default: name)
    if family in _CIRCLE-STROKES { return family }
    if (_FIT-DIGIT-ALIASES.at(name, default: none) not in ("times", "courier")
      and name not in ("arial", "new computer modern", "stixgeneral")) { return none }
  }
  none
}

#let _fit-groups-for(font, weight, reference: "①") = {
  let stack = if type(font) == array { font } else { (font,) }
  let provider = _circle-family(font, reference)
  if provider == none or provider not in _DIGIT-FIT { return none }
  let digit = none
  let digit-seen = false
  for f in stack {
    let name = lower(if type(f) == dictionary { f.at("name", default: "") } else { str(f) })
    if not digit-seen and _covers-char(f, "0") {
      digit-seen = true
      digit = _FIT-DIGIT-ALIASES.at(name, default: none)
    }
  }
  if provider == none or digit == none or digit not in _DIGIT-FIT.at(provider) {
    none
  } else {
    let weights = _DIGIT-FIT.at(provider).at(digit)
    weights.at(if _weight-num(weight) >= 600 { "bold" } else { "regular" },
               default: weights.at("regular", default: none))
  }
}

#let _fit-group(n) = {
  if n < 10 { if n == 1 { "single-1" } else { "single" } }
  else if n == 11 { "all-ones" }
  else if str(n).contains("1") { "two-with-1" }
  else { "two" }
}

#let _quan-draw-state = state("quan-draw", (
  default: (
    stroke:   0.0315em,
    radius:   50%,

    inset:    (x: 0.05em, y: 0.015em),
    outset:   (y: 0.15em),
    baseline: -0.06em,
    size:     0.825em,

    height:   auto,
    kern:     -0.075em,
    gap:      0.1em,

    digit-fit: none,
  ),

  rules: _RULES.song,

  user-rules: (),
  user-keys: (),
))

#let quan-init(digits: none) = {
  let parsed = if digits != none { _parse-int-ranges(digits) } else { () }
  _quan-state.update(_ => (digits: parsed))
}

#let quan-style(
  stroke:   none,
  radius:   none,
  inset:    none,
  outset:   none,
  baseline: none,
  size:     none,
  height:   none,
  kern:     none,
  gap:      none,
  digit-fit: none,
  ..rules,
) = {
  assert(digit-fit in (none, true, false),
    message: "quan-style: `digit-fit` must be a boolean, got " + repr(digit-fit))

  let parsed = rules.pos().map(rule => {
    assert(
      type(rule) == array and rule.len() == 2
        and type(rule.at(0)) == str and type(rule.at(1)) == dictionary,
      message: "quan-style: positional args must be (range-str, style-dict) tuples",
    )
    (values: _parse-int-ranges(rule.at(0)), style: rule.at(1))
  })
  let named = (stroke: stroke, radius: radius, inset: inset, outset: outset,
               baseline: baseline, size: size, height: height, kern: kern, gap: gap,
               digit-fit: digit-fit)
  _quan-draw-state.update(prev => {
    let d = prev.default
    let keys = prev.user-keys
    for (k, v) in named.pairs() {
      if v != none {
        d.insert(k, v)
        if k not in keys { keys.push(k) }
      }
    }
    (default: d, rules: prev.rules,
     user-rules: prev.user-rules + parsed, user-keys: keys)
  })
}

#let _circled-digit(n) = {
  if      n == 0               { str.from-unicode(0x24EA) }
  else if n >= 1  and n <= 20  { str.from-unicode(0x245F + n) }
  else if n >= 21 and n <= 35  { str.from-unicode(0x3251 + (n - 21)) }
  else if n >= 36 and n <= 50  { str.from-unicode(0x32B1 + (n - 36)) }
  else { none }
}

#let _resolve-style(value, draw-cfg, picked: none) = {
  let s = draw-cfg.default
  let user-keys = draw-cfg.user-keys
  let rules = if picked == none { draw-cfg.rules } else { picked.rules }
  s.insert("cap", if picked == none { 0.684 } else { picked.cap })
  if type(value) == int {
    for rule in rules {
      if value in rule.values {
        for (k, v) in rule.style.pairs() { s.insert(k, v) }
        break
      }
    }

    for k in draw-cfg.user-keys {
      s.insert(k, draw-cfg.default.at(k))
    }
    for rule in draw-cfg.user-rules {
      if value in rule.values {
        for (k, v) in rule.style.pairs() {
          s.insert(k, v)
          if k not in user-keys { user-keys.push(k) }
        }
      }
    }
  }
  s.insert("user-keys", user-keys)
  s
}

#let _side(value, side) = {
  if type(value) != dictionary { return value.to-absolute() }
  let axis = if side in ("left", "right") { "x" } else { "y" }
  value.at(side, default: value.at(axis, default: value.at("rest", default: 0pt))).to-absolute()
}

#let _FIT-APPROX = (
  regular: (
    "single-1": (0.9803, 0.6338),
    "single": (0.9178, 0.6471),
    "all-ones": (0.6018, 0.6063),
    "two-with-1": (0.6325, 0.6341),
    "two": (0.6440, 0.5798),
  ),
  bold: (
    "single-1": (0.9047, 0.6202),
    "single": (0.9158, 0.6354),
    "all-ones": (0.5754, 0.5782),
    "two-with-1": (0.6078, 0.6057),
    "two": (0.6383, 0.5909),
  ),
)

#let _fit-approx(value, ref-h, inner, weight) = {
  if inner <= 0pt { return none }
  let groups = _FIT-APPROX.at(if _weight-num(weight) >= 600 { "bold" } else { "regular" })
  let short = value >= 0 and value <= 99
  let group = if short { _fit-group(value) } else if value > -10 and value < 0 { "single" } else { "two" }
  let (sx, fh) = groups.at(group)
  let digits = text(tracking: 0.04em, top-edge: "bounds", bottom-edge: "bounds", str(value))
  let bounds = measure(digits)
  if bounds.width <= 0pt or bounds.height <= 0pt { return none }
  let target-h = calc.min(fh * ref-h, 0.8 * inner)
  let sy = target-h / bounds.height
  let sx = if short {
    let max-width = calc.sqrt(calc.max(0, calc.pow(inner / 1pt, 2) - calc.pow(target-h / 1pt, 2))) * 1pt
    calc.min(sx, max-width / bounds.width)
  } else {
    let diagonal = calc.sqrt(calc.pow(bounds.width / 1pt, 2) + calc.pow(bounds.height / 1pt, 2)) * 1pt
    calc.min(sy, inner / diagonal)
  }
  let sy = if short { sy } else { sx }
  (scale(x: sx * 100%, y: sy * 100%, reflow: true, digits), 0pt, 0pt)
}

#let _fit-drawn(value, ref-h, available, font, weight, inner, reference: "①", clearance-scale: 1) = {
  let groups = _fit-groups-for(font, weight, reference: reference)
  if groups == none { _fit-approx(value, ref-h, inner, weight) } else {
    let n = value
    let entry = if n >= 0 and n <= 99 { groups.at(_fit-group(n), default: none) } else { none }
    if entry != none {

      let (sx, fh, dxf, dyf, kx-small, kx-large) = entry
      let size-pt = text.size.to-absolute() / 1pt
      let t = calc.clamp((size-pt - 10) / 14, 0, 1)
      let kx = (kx-small + (kx-large - kx-small) * t) * clearance-scale
      let digits = text(top-edge: "bounds", bottom-edge: "bounds", str(value))
      let sy = fh * ref-h / measure(digits).height
      (scale(x: sx * kx * 100%, y: sy * 100%, reflow: true, digits),
       dxf * ref-h, dyf * ref-h)
    } else {

      let base = calc.abs(n)
      let e = groups.at(if base <= 9 { "single" } else { "two" }, default: none)
      if e == none { _fit-approx(value, ref-h, inner, weight) } else {
        let digits = text(top-edge: "bounds", bottom-edge: "bounds", str(value))
        let f = e.at(1) * ref-h / measure(digits).height
        let diagonal = calc.sqrt(calc.pow(measure(digits).width * f / 1pt, 2)
          + calc.pow(measure(digits).height * f / 1pt, 2)) * 1pt
        let k = if diagonal > available { available / diagonal } else { 1 }
        (scale(x: f * k * 100%, y: f * k * 100%, reflow: true, digits), 0pt, 0pt)
      }
    }
  }
}

#let _CIRCLE-AXES = (
  "simsun": ((0.0365312, 0.0305543, 0.0351575), (0.0365312, 0.0305543, 0.0351575)),
  "libertinus serif": ((0.0558691, 0.0553056, 0.0555564), (0.0655761, 0.0655354, 0.0656235)),
  "noto serif cjk sc": ((0.0325327, 0.0300897, 0.0312265), (0.0363378, 0.0339991, 0.0356954)),
  "noto sans cjk sc": ((0.0343184, 0.0343460, 0.0338938), (0.0389174, 0.0392369, 0.0389498)),
  "songti sc": ((0.0386988, 0.0333719, 0.0340214), (0.0669689, 0.0616468, 0.0634961)),
  "fzshusong-z01s": ((0.0307799, 0.0285738, 0.0293936), (0.0307799, 0.0285738, 0.0293936)),
  "fandolsong": ((0.0383874, 0.0381963, 0.0382658), (0.0383792, 0.0384459, 0.0382000)),
  "heiti sc": ((0.0669744, 0.0615601, 0.0634298), (0.0669744, 0.0615601, 0.0634298)),
  "pingfang sc": ((0.0383184, 0.0377012, 0.0377201), (0.0490897, 0.0480524, 0.0478397)),
  "microsoft yahei": ((0.0650908, 0.0650125, 0.0647242), (0.0650908, 0.0650125, 0.0647242)),
  "simhei": ((0.0481495, 0.0435150, 0.0473325), (0.0481495, 0.0435150, 0.0473325)),
  "kaiti": ((0.0481495, 0.0435150, 0.0473325), (0.0481495, 0.0435150, 0.0473325)),
  "fangsong": ((0.0359323, 0.0299534, 0.0342961), (0.0359323, 0.0299534, 0.0342961)),
  "hiragino sans gb": ((0.0346290, 0.0347382, 0.0346238), (0.0438022, 0.0439094, 0.0440122)),
  "stsong": ((0.0326710, 0.0269253, 0.0281853), (0.0326710, 0.0269253, 0.0281853)),
)

#let _ellipse-contour(cx, cy, rx, ry, control: 0.5522847498307936) = {
  let k = control
  (
    curve.move((cx + rx, cy)),
    curve.cubic((cx + rx, cy + k * ry), (cx + k * rx, cy + ry), (cx, cy + ry)),
    curve.cubic((cx - k * rx, cy + ry), (cx - rx, cy + k * ry), (cx - rx, cy)),
    curve.cubic((cx - rx, cy - k * ry), (cx - k * rx, cy - ry), (cx, cy - ry)),
    curve.cubic((cx + k * rx, cy - ry), (cx + rx, cy - k * ry), (cx + rx, cy)),
    curve.close(),
  )
}

#let _directional-ring(diameter, horizontal, vertical, paint, diagonal: none) = {
  let r = diameter / 2
  assert(horizontal > 0pt and vertical > 0pt and calc.max(horizontal, vertical) < r,
    message: "quan: invalid calibrated ring thickness")

  let k = if diagonal == none { 0.5522847498307936 } else {
    let diagonal-radius = calc.sqrt(calc.pow((r - horizontal) / 1pt, 2)
      + calc.pow((r - vertical) / 1pt, 2)) * 1pt
    ((r - diagonal) / diagonal-radius - 0.5) / 0.375
  }
  assert(k > 0 and k < 1, message: "quan: invalid inner ring contour")
  curve(
    fill: paint,
    stroke: none,
    fill-rule: "even-odd",
    .._ellipse-contour(r, r, r, r),
    .._ellipse-contour(r, r, r - horizontal, r - vertical, control: k),
  )
}

#let _drawn-core(body, value: none) = context {
  let s = _resolve-style(value, _quan-draw-state.get(), picked: _pick-rules(text.font))
  let sk = stroke(s.stroke)

  let factor = calc.max(1.0, 1.0 + (_weight-num(text.weight) - 400) / 400 * 0.6)
  let legacy-thickness = (0.0315em * factor).to-absolute()
  let half = s.gap / 2
  let it = _side(s.inset, "top")
  let ib = _side(s.inset, "bottom")
  let il = _side(s.inset, "left")
  let ir = _side(s.inset, "right")
  let ot = _side(s.outset, "top")
  let ob = _side(s.outset, "bottom")
  let ol = _side(s.outset, "left")
  let oright = _side(s.outset, "right")
  let coverage = _quan-state.get().digits.filter(n => _circled-digit(n) != none)
  let reference-value = if coverage.len() == 0 { none } else if 10 in coverage { 10 } else { coverage.last() }
  let glyph = if reference-value == none { none } else { _circled-digit(reference-value) }
  let reference = text(top-edge: "bounds", bottom-edge: "bounds", if glyph == none { "0" } else { glyph })
  let custom-geometry = s.user-keys.any(k => k in ("size", "height", "inset", "outset"))
  let native-geometry = glyph != none and s.height == auto and not custom-geometry
  let axes = if (native-geometry and "stroke" not in s.user-keys
    and "radius" not in s.user-keys and reference-value >= 1 and reference-value <= 10) {
    let family = _circle-family(text.font, glyph)
    if family == none or family not in _CIRCLE-AXES { none } else {
      _CIRCLE-AXES.at(family).at(if _weight-num(text.weight) >= 600 { 1 } else { 0 })
    }
  } else { none }
  let calibrated = if axes != none {

    measure(reference).height * calc.max(..axes)
  } else if (native-geometry and "stroke" not in s.user-keys
    and reference-value >= 1 and reference-value <= 10) {
    let family = _circle-family(text.font, glyph)
    if family == none { none } else {
      measure(reference).height * _CIRCLE-STROKES.at(family).at(if _weight-num(text.weight) >= 600 { 1 } else { 0 })
    }
  } else { none }
  if sk.paint == auto {
    let th = if sk.thickness == auto { 0.0315em } else { sk.thickness }
    sk = stroke((paint: text.fill, thickness: if calibrated == none { th * factor } else { calibrated },
                 cap: sk.cap, join: sk.join, dash: sk.dash, miter-limit: sk.miter-limit))
  }
  let thickness = if sk.thickness == auto { 0pt } else { sk.thickness.to-absolute() }
  let diameter = if native-geometry {

    calc.max(1pt, measure(reference).height - thickness)
  } else {
    (if s.height == auto { s.size * s.cap + it + ib } else { s.height }).to-absolute() + ot + ob
  }
  let descent = measure(text(top-edge: "baseline", bottom-edge: "bounds", if glyph == none { "0" } else { glyph })).height
  let line-height = measure(text(if glyph == none { "0" } else { glyph })).height
  let line-descent = measure(text(top-edge: "baseline", if glyph == none { "0" } else { glyph })).height

  let ot = if native-geometry { measure(reference).height - descent - line-height + line-descent - thickness / 2 } else { ot }
  let ob = if native-geometry { descent - line-descent - thickness / 2 } else { ob }

  let stroke-outset = if calibrated == none { 0pt } else { (legacy-thickness - thickness) / 2 }
  let ol = if native-geometry { stroke-outset } else { ol }
  let oright = if native-geometry { stroke-outset } else { oright }
  let height = diameter - ot - ob

  let width = diameter - ol - oright
  assert(width > 0pt and height > 0pt, message: "quan: outset exceeds the circle size")
  let available = calc.max(1pt, if calibrated == none {
    diameter - calc.max(il + ir, it + ib) - thickness
  } else {

    let old = calc.max(1pt, measure(reference).height - legacy-thickness) - calc.max(il + ir, it + ib) - legacy-thickness
    let clear = measure(reference).height - 2 * thickness - 2 * calc.max(0.02 * measure(reference).height, 0.12pt)
    calc.min(old, clear)
  })
  let fit = if s.at("digit-fit", default: none) == true and native-geometry and value != none {
    let ref-h = measure(reference).height

    let inner = ref-h - 2 * thickness - 2 * calc.max(0.02 * ref-h, 0.12pt)

    let clearance-scale = if calibrated == none or thickness <= legacy-thickness { 1 } else {
      let margin = calc.max(0.005 * ref-h, 0.12pt)
      calc.min(1, calc.max(0pt, ref-h - 2 * thickness - 2 * margin) / calc.max(0.01pt, ref-h - 2 * legacy-thickness))
    }
    _fit-drawn(value, ref-h, available, text.font, text.weight, inner, reference: glyph, clearance-scale: clearance-scale)
  } else { none }
  let fitted = if fit != none { fit.at(0) } else {
    let digits = text(size: s.size, tracking: s.kern, top-edge: "bounds", bottom-edge: "bounds", body)
    let ink = measure(text(top-edge: "bounds", bottom-edge: "bounds", digits))

    let diagonal = calc.sqrt(calc.pow(ink.width / 1pt, 2) + calc.pow(ink.height / 1pt, 2)) * 1pt
    let factor = if diagonal > available { available / diagonal } else { 1 }
    if factor < 1 { scale(x: factor * 100%, y: factor * 100%, reflow: true, digits) } else { digits }
  }
  let fit-dx = if fit == none { 0pt } else { fit.at(1) }
  let fit-dy = if fit == none { 0pt } else { fit.at(2) }
  let baseline = if native-geometry { line-descent + if "baseline" in s.user-keys { s.baseline } else { 0pt } }
    else { descent + (diameter - measure(reference).height) / 2 + s.baseline }
  h(half)
  box(
    stroke:   if axes == none { sk } else { none },
    radius:   s.radius,
    inset:    0pt,
    outset:   (top: ot, bottom: ob, left: ol, right: oright),
    baseline: baseline,
    width:    width,
    height:   height,
    {
      if axes != none {
        place(top + left, dx: -ol - thickness / 2, dy: -ot - thickness / 2,
          _directional-ring(diameter + thickness,
            measure(reference).height * axes.at(0),
            measure(reference).height * axes.at(1), sk.paint,
            diagonal: measure(reference).height * axes.at(2)))
      }
      place(center + horizon, dx: (oright - ol) / 2 + fit-dx, dy: (ob - ot) / 2 + fit-dy, fitted)
    },
  )

  "\u{200C}"
  h(half)
}

#let _drawn(body, value: none) = context {
  let up = measure(box(width: 0pt, height: 0pt, baseline: 1em)).height
  let down = measure(box(width: 0pt, height: 0pt, baseline: -1em)).height

  let shift = (down - up) / 2
  let scripted = (
    sys.version >= version(0, 14, 0)
    and calc.abs(shift - text.baseline.to-absolute()) > 0.01pt
  )
  if scripted {

    let reset(body) = sub(typographic: false, size: 1em, baseline: 0em, text(baseline: 0pt, body))
    let coverage = _quan-state.get().digits.filter(n => _circled-digit(n) != none)
    let reference-value = if coverage.len() == 0 { none } else if 10 in coverage { 10 } else { coverage.last() }
    let glyph = if reference-value == none { none } else { _circled-digit(reference-value) }
    let bounds = text(top-edge: "bounds", bottom-edge: "bounds", if glyph == none { "0" } else { glyph })

    let factor = measure(bounds).width / measure(reset(bounds)).width
    box(move(dy: if sys.version >= version(0, 15, 0) { shift } else { 0pt },
      scale(x: factor * 100%, y: factor * 100%, reflow: true, reset(_drawn-core(body, value: value)))))
  } else {
    _drawn-core(body, value: value)
  }
}

#let quan(value) = {
  assert(type(value) == int, message: "quan: expected int, got " + str(type(value)))
  context {
    let cfg = _quan-state.get()
    let g = _circled-digit(value)
    if g == none or value not in cfg.digits {
      _drawn(str(value), value: value)
    } else {
      g
    }
  }
}

#let quan-footnote(body) = {
  set footnote(numbering: quan)
  body
}
