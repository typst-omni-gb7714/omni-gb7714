// 示例 8：逐条目语言——同一文献表内，中文条目截断作「等」、西文条目作「et al」。
#set page(width: 15cm, height: auto, margin: 10pt)
#set text(lang: "zh", font: "Noto Serif CJK SC", size: 10pt)
#import "/lib.typ": *
#show: gb7714(full: true)
#bibliography(bytes("
@book{zh, author={{张三} and {李四} and {王五} and {赵六}}, title={中文文献著录示例}, publisher={中华书局}, location={北京}, date={2020}, langid={chinese}}
@book{en, author={Smith, John and Doe, Jane and Brown, Kate and Lee, Sam}, title={An English Work}, publisher={Springer}, location={Berlin}, date={2021}, langid={english}}
"), title: none)
