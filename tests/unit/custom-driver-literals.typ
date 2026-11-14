// PDF 文本提取会合并软硬空格，这里直接检查模板拼接的精确字符。
#import "/src/drivers/custom.typ" as driver
#let plain(value) = {
  if value == none { "" }
  else if type(value) == str { value }
  else if value.has("text") { value.text }
  else if value.has("children") { value.children.map(plain).join() }
  else if value.has("body") { plain(value.body) }
  else { panic(repr(value)) }
}
#let opts = (custom-fields: (alpha: auto, beta: auto, gamma: auto, nop: auto),
  correct-punct: false, punct-style: "half-with-space", custom-punct: (:), version: 2025)
#let check(template, expected, fields: (:)) = {
  let entry = (entry_type: "book", parsed_names: (:), parsed_dates: (:),
    fields: (alpha: "A", gamma: "C", langid: "english", ..fields))
  let (body, _) = driver.render(entry, template, opts, (:))
  assert.eq(plain(body), expected, message: template)
}
#check("alpha {[S]} <beta => beta> .", "A [S]. ")
#check("alpha {[X]} <beta => beta>", "A [X]")
#check("alpha {[X]} <beta => beta> <nop => nop> gamma", "A [X] C")
#check("alpha <beta => beta> {[X]} gamma", "A [X] C")
#check("alpha . {[X]} <beta => beta> gamma", "A.  [X] C")
#check("alpha {[L]} . {[R]} <beta => beta> gamma", "A [L].  [R] C")
#check("alpha {[L]} . <beta => beta> {[R]}", "A [L]. [R]")
#check("alpha . <beta => beta> {[X]} gamma", "A. [X] C")
#check("alpha {[S]} <beta => beta> gamma", "A [S]//G", fields: (gamma: "//G"))
#check("alpha <beta => beta> {[X]} gamma", "A [X] //G", fields: (gamma: "//G"))
#check("alpha {.} <beta => beta> gamma", "A. C")
#check("alpha {.} <beta => beta> gamma", "A. C", fields: (alpha: "A."))
#check("alpha {[L]} <beta => beta> {[R]}", "A [L] [R]")
#check("alpha{  [X]  }<beta => beta>gamma", "A  [X]  C")
#check("alpha {[L]}{[R]} <beta => beta> gamma", "A [L][R] C")
#check("alpha {} <beta => beta> gamma", "A C")
#check("alpha <beta => beta> {} gamma", "A  C")
#check("alpha {} gamma", "A  C")
#check("alpha {[X]} <beta => beta> gamma", "A [X] B C", fields: (beta: "B"))
#check("alpha <beta => beta> {[X]} gamma", "A B [X] C", fields: (beta: "B"))
#check("alpha {[X]} <alpha => beta> gamma", "A [X] C")
#check("alpha <beta => {[NO]} beta> gamma", "A C")
#check("<beta => {[NO]}>", "")
#check("<alpha => {[YES]}>", "[YES]")
#check("alpha {[X]} < => {[NO]}> <alpha => gamma>", "A [X] C")
#check("alpha {[X]} <beta => beta> < => gamma>", "A [X] C")
#check("<alpha {[X]} <beta => beta> gamma>", "A [X] C")
#check("<alpha => alpha {[X]} <beta => beta> gamma>", "A [X] C")
#check("&<alpha {[X]} <beta => beta>>", "")
#check("alpha{：}beta", "A")
#check("alpha{：}beta", "A：B", fields: (beta: "B"))
#check("alpha {附：} beta", "A")
#check("alpha{”}<{, }beta>", "A")
#check("alpha {[X]} <beta>", "A")
#check("alpha <nop => nop> {：} beta", "A")
#check("alpha {[X]} beta <nop => nop> gamma", "A C")
#check("alpha beta {[X]} <nop => nop> gamma", "A [X] C")
#check("alpha <nop => nop> {[X]} beta gamma", "A C")
#check("beta {[X]} <nop => nop> gamma", "C")
#check("{[X]} <beta => beta> {[Y]}", "")
#check("{[X]}", "")
#check("<beta {[X]}>", "")
#check("alpha , <beta => beta> , gamma .", "A,  C. ")
#check("alpha , <beta => beta> , gamma .", "A,  B,  C. ", fields: (beta: "B"))
#check("alpha . <beta => beta> . gamma", "A. C")
#check("alpha , <beta => beta> gamma", "A//G", fields: (gamma: "//G"))
