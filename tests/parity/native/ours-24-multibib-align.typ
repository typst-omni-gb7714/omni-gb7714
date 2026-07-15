// 回归：多列表连续编号，首表([1]-[12]双位数)与续表([13]-[15])的编号列/内容列必须*对齐*。
//   曾 bug：续表按自身条数(3)测编号宽成 "[3]" 窄列 → [13-15] 溢出、与首表对不齐。修法 eff-number-width 计入 number-offset。
//   run.sh 用像素量所有编号行左缘应*同一 x*（左对齐 + 各表对齐）。需 0.15（native-mode 连续编号）。
#import "/lib.typ": *
#set page(width: 300pt, height: auto, margin: 12pt)
#show: gb7714.with(full: true)
正文 @a1 @a2 @a3 @a4 @a5 @a6 @a7 @a8 @a9 @a10 @a11 @a12 @b1 @b2 @b3 
#bibliography(bytes("@book{a1,author={A1},title={T1},publisher={P},year={2020}}
@book{a2,author={A2},title={T2},publisher={P},year={2020}}
@book{a3,author={A3},title={T3},publisher={P},year={2020}}
@book{a4,author={A4},title={T4},publisher={P},year={2020}}
@book{a5,author={A5},title={T5},publisher={P},year={2020}}
@book{a6,author={A6},title={T6},publisher={P},year={2020}}
@book{a7,author={A7},title={T7},publisher={P},year={2020}}
@book{a8,author={A8},title={T8},publisher={P},year={2020}}
@book{a9,author={A9},title={T9},publisher={P},year={2020}}
@book{a10,author={A10},title={T10},publisher={P},year={2020}}
@book{a11,author={A11},title={T11},publisher={P},year={2020}}
@book{a12,author={A12},title={T12},publisher={P},year={2020}}"), title: none)
#bibliography(bytes("@book{b1,author={B1},title={U1},publisher={Q},year={2021}}
@book{b2,author={B2},title={U2},publisher={Q},year={2021}}
@book{b3,author={B3},title={U3},publisher={Q},year={2021}}"), title: none)
