#import "../category.typ"
#import "../elements/mark-medium/built-in.typ" as mark-medium
#import "../punct/built-in.typ" as punct
#import "built-in.typ" as built-in-driver
#import "custom.typ" as custom-driver

#let _maybe-annotation(rendered, entry, show-annotation) = {
  if not show-annotation { return rendered }

  let a = punct.field-text(entry, "annotation"); if a == none { a = punct.field-text(entry, "annote") }
  if a == none or a == "" { return rendered }
  [#rendered. #a]
}

#let entry(entry, registered-marks: (), show-sine-loco: true, show-sine-nomine: true, show-sine-anno: false, et-al-min: 4, et-al-use-first: 3, et-al-use-last: 0, show-url: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, end-with-period: true, hyperlink: true, italic-journal: false, bold-journal-volume: false, italic-book-title: false, space-before-mark: false, space-before-pages: true, page-range-separator: "-", page-range-style: none, period-after-creator: true, show-anon: false, show-et-al: true, name-style: (:), hyperlink-title: false, dedup-author-editor: false, skip-date: false, date-suffix: "", pages-override: none, skip-creator: false, creator-override: none, show-degree: false, show-series: false, prefix-last: false, custom-drivers: (:), custom-terms: (:), custom-fields: (:), custom-pids: (:), correct-punct: false, punct-style: "half-with-space", custom-punct: (:), url-break-every: 1, url-break-hyphen: true, url-break-hyphen-at-delimiters: true, version: 2015, name-suffix-separator: auto, et-al-translator-separator: auto, component-part-separator: "//", show-pid: (:), pid-priority: (), dedup-url-pid: true, show-annotation: false, volume-title-gutter: auto) = {
  let entry-category = category.get(entry, version: version)

  let show-urldate = show-urldate and not mark-medium.online-suppressed(show-url, entry, version: version)

  let _format-args = (
    show-sine-loco: show-sine-loco, show-sine-nomine: show-sine-nomine, show-sine-anno: show-sine-anno,
    et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last,
    show-url: show-url,
    show-mark: show-mark, show-medium: show-medium,
    show-patent-country: show-patent-country,
    short-journal: short-journal, show-urldate: show-urldate,
    hyperlink: hyperlink,
    italic-journal: italic-journal, bold-journal-volume: bold-journal-volume,
    italic-book-title: italic-book-title,
    space-before-mark: space-before-mark, space-before-pages: space-before-pages,
    page-range-separator: page-range-separator, page-range-style: page-range-style, period-after-creator: period-after-creator,
    show-anon: show-anon, show-et-al: show-et-al, name-style: name-style, name-suffix-separator: name-suffix-separator, et-al-translator-separator: et-al-translator-separator, component-part-separator: component-part-separator,
    hyperlink-title: hyperlink-title, dedup-author-editor: dedup-author-editor,
    skip-date: skip-date, date-suffix: date-suffix, pages-override: pages-override, skip-creator: skip-creator, creator-override: creator-override, show-degree: show-degree, show-series: show-series, prefix-last: prefix-last,
    correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct,
    url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters,
    version: version, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid,
    custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids,

    volume-title-gutter: volume-title-gutter,
  )

  if custom-drivers != none and custom-drivers != (:) {
    custom-driver.validate-driver-keys(custom-drivers, extra-marks: registered-marks)
    let template = custom-drivers.at(entry.entry_type, default: none)
    if template == none { template = custom-drivers.at(mark-medium.base-mark(entry), default: none) }
    if template != none {
      return _maybe-annotation(custom-driver.render(entry, template, _format-args, custom-terms, end-with-period: end-with-period), entry, show-annotation)
    }
  }
  let _result = if entry-category == "component-part" { built-in-driver.component-part(entry, _format-args) }
  else if entry-category == "preprint" { built-in-driver.preprint(entry, _format-args) }
  else if entry-category == "serial-article" { built-in-driver.serial-article(entry, _format-args) }
  else if entry-category == "serial-newspaper" { built-in-driver.serial-newspaper(entry, _format-args) }
  else if entry-category == "patent" { built-in-driver.patent(entry, _format-args) }
  else if entry-category == "electronic" { built-in-driver.electronic(entry, _format-args) }
  else if entry-category == "serial" { built-in-driver.serial(entry, _format-args) }
  else { built-in-driver.monograph(entry, _format-args) }
  _maybe-annotation(_result, entry, show-annotation)
}
