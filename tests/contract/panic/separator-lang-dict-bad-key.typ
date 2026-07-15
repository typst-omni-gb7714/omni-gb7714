// 分隔符多语言字典的键拼错一律 panic 并列出合法键。没有插入序兜底之后，错键会静默失效
// （悄悄退回预设值），不报出来更坑。
#import "/lib.typ": *
#show: gb7714.with(full: true, page-range-separator: (cn: "～"))
#bibliography(bytes("@article{a, author={A, X}, title={T}, journaltitle={J}, year={2020}, volume={1}, pages={321-328}, langid={english}}"), title: none)
