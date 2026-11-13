// 保留动态列表身份，防止稳定矩阵夹具掩盖运行时的位置与配置回归。
#import "/tests/_fixture/probe.typ": *
#let _case-n = counter("gb7714-convergence-case")
#let case(label, config, cites: (), bib: MAIN, body: none, full: true, title: none, bib-args: (:), own-bib: true) = {
  _case-n.step()
  context {
    let tag = "c" + str(_case-n.get().first())
    block(width: 100%, breakable: false, above: 6pt, below: 2pt,
          stroke: (top: 0.6pt + luma(150)), inset: (top: 4pt, bottom: 5pt))[
      #text(weight: "bold", fill: rgb("#166534"))[▸ #label]
      #v(2pt)
      #[
        #show: config
        #set-bib-label(tag)
        #if body != none {
          body
          linebreak()
        } else if cites.len() > 0 {
          [正文：]
          cites.map(k => cite(k)).join([ ])
          linebreak()
        }
        #if own-bib { bibliography(bib, title: title, full: full, label: tag, ..bib-args) }
      ]
    ]
  }
}
