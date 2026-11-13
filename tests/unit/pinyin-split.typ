// 拼音双音节切分（`split-syllables`）与拼音名检测的边界探针。
// 切点从长到短找（与李泽平 bst `is.double.pinyin` 同向）：changan 必须得 chang|an（长安），不是 chan|gan。
#import "/src/detect/pinyin.typ": split-syllables, is-name-pinyin
#assert.eq(split-syllables("yanshuo"), ("yan", "shuo"), message: "yanshuo -> yan|shuo")
#assert.eq(split-syllables("changan"), ("chang", "an"), message: "方向哨兵：changan -> chang|an（长安），非 chan|gan")
#assert.eq(split-syllables("jiangning"), ("jiang", "ning"), message: "jiangning -> jiang|ning")
#assert.eq(split-syllables("erting"), ("er", "ting"), message: "erting -> er|ting（Pan E T）")
#assert.eq(split-syllables("xinya"), ("xin", "ya"), message: "xinya -> xin|ya（Wang X Y）")
#assert.eq(split-syllables("xian"), none, message: "xian 单音节，不切（西安要写 Xi'an）")
#assert.eq(split-syllables("shuo"), none, message: "shuo 整词是一个音节，不切成 shu|o")
#assert.eq(split-syllables("martin"), none, message: "martin 不是拼音，不切")
#assert.eq(split-syllables("anna"), ("an", "na"), message: "anna 能切（假阳性留档，由阻断表在检测层拦）")
// 检测层：阻断表只拦「西文常用名」，拼音名照常
#assert(is-name-pinyin((family: "Chu", given: "Yanshuo")), message: "Chu Yanshuo 是拼音名")
#assert(not is-name-pinyin((family: "Wang", given: "Anna")), message: "Anna Wang：阻断表拦下，不算拼音名")
#assert(not is-name-pinyin((family: "Chen", given: "Lisa")), message: "Lisa Chen：阻断表拦下")
#assert(is-name-pinyin((family: "Long", given: "Bin")), message: "Long Bin：单音节，照旧判拼音（已知假阳性来源）")
拼音切分校验通过
