import Foundation
#if DEBUG && canImport(UIKit)
import UIKit
#endif

/// 論壇假資料：以超商買得到的材料調酒為主。
/// 只用通用品名，不寫真實品牌或超商名稱；份量適中，不鼓勵拚酒或混很多種烈酒。
enum ForumMockData {
    static let authors: [ForumAuthor] = [
        ForumAuthor(name: "小安", initials: "安", colorIndex: 0),
        ForumAuthor(name: "Kevin 調調", initials: "K", colorIndex: 1),
        ForumAuthor(name: "柚子", initials: "柚", colorIndex: 2),
        ForumAuthor(name: "阿哲不加冰", initials: "哲", colorIndex: 3),
        ForumAuthor(name: "Mia", initials: "M", colorIndex: 4),
        ForumAuthor(name: "宿舍小酒保", initials: "保", colorIndex: 5),
        ForumAuthor(name: "小魚", initials: "魚", colorIndex: 6),
        ForumAuthor(name: "Jerry", initials: "J", colorIndex: 7),
    ]

    private static func a(_ i: Int) -> ForumAuthor { authors[i] }

    private static func i(_ name: String, _ amount: String) -> RecipeIngredient {
        RecipeIngredient(name: name, amount: amount)
    }

    static func posts(now: Date) -> [ForumPost] {
        func ago(minutes: Double) -> Date { now.addingTimeInterval(-minutes * 60) }
        func c(_ author: Int, _ body: String, _ minutesAgo: Double) -> ForumComment {
            ForumComment(author: a(author), body: body, createdAt: ago(minutes: minutesAgo))
        }

        let posts: [ForumPost] = [
            ForumPost(
                id: "mock-1", author: a(5), createdAt: ago(minutes: 35), category: .convenience,
                title: "宿舍十分鐘：檸檬紅茶＋伏特加",
                body: "期中考完室友說想喝一點，樓下超商就搞定。檸檬紅茶本身夠甜夠酸，伏特加幾乎沒味道，混起來就是很順口的冰紅茶調酒。\n\n重點是伏特加不要倒太多，30ml 就很夠了，喝起來很順反而容易不小心喝太快。",
                tags: ["#超商調酒", "#伏特加", "#十分鐘上手"], likeCount: 236,
                comments: [
                    c(2, "這個真的經典，我都再擠半顆檸檬", 28),
                    c(6, "順口是真的，記得慢慢喝、旁邊放杯水", 20),
                    c(5, "對！我們都一人一杯水配著喝", 15),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("檸檬紅茶", "150ml"), i("伏特加", "30ml"), i("冰塊", "半杯"), i("檸檬片", "1 片（可省略）")],
                    steps: ["杯子先放半杯冰塊。", "倒入伏特加 30ml。", "加入檸檬紅茶到約八分滿，輕輕攪拌幾下。", "放上檸檬片就完成。"],
                    difficulty: .easy, estimatedCost: "約 NT$60", sources: [.convenienceStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-2", author: a(0), createdAt: ago(minutes: 80), category: .convenience,
                title: "乳酸飲料＋燒酎，酸甜像在喝氣泡優格",
                body: "超商冰櫃那種乳酸菌飲料加燒酎，再補一點氣泡水，口感會變輕盈很多。燒酎酒精濃度不高，很適合不太會喝的朋友。",
                tags: ["#超商調酒", "#燒酎", "#酸甜系"], likeCount: 188,
                comments: [
                    c(4, "加氣泡水這招好！原本覺得太甜", 60),
                    c(3, "用水蜜桃口味的乳酸飲料也很搭", 52),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("乳酸菌飲料", "120ml"), i("燒酎", "40ml"), i("無糖氣泡水", "60ml"), i("冰塊", "半杯")],
                    steps: ["杯中放冰塊。", "倒入燒酎和乳酸菌飲料，攪拌均勻。", "最後沿杯緣慢慢倒入氣泡水，不要攪太大力以免氣泡跑掉。"],
                    difficulty: .easy, estimatedCost: "約 NT$90", sources: [.convenienceStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-3", author: a(2), createdAt: ago(minutes: 60 * 3), category: .convenience,
                title: "梅酒蘇打：最不會失敗的一杯",
                body: "梅酒直接喝有點甜膩，加無糖氣泡水剛好。超商現在很多都有小瓶梅酒，一瓶可以調兩三杯，夏天在陽台喝超舒服。",
                tags: ["#超商調酒", "#梅酒", "#十分鐘上手"], likeCount: 154,
                comments: [
                    c(7, "加一片檸檬整個升級", 150),
                    c(0, "梅酒蘇打是我的入門酒", 140),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("梅酒", "45ml"), i("無糖氣泡水", "120ml"), i("冰塊", "滿杯"), i("檸檬片", "1 片")],
                    steps: ["杯子裝滿冰塊。", "倒入梅酒。", "慢慢加入氣泡水，輕輕攪一下。", "放上檸檬片。"],
                    difficulty: .easy, estimatedCost: "約 NT$70", sources: [.convenienceStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-4", author: a(4), createdAt: ago(minutes: 60 * 5), category: .convenience,
                title: "咖啡牛奶＋咖啡香甜酒，懶人版白色俄羅斯",
                body: "正統白色俄羅斯要伏特加＋咖啡香甜酒＋鮮奶油，我的懶人版只用超商咖啡牛奶加一點咖啡香甜酒，喝起來像大人版的咖啡牛奶。咖啡香甜酒超市或酒行都有，買一瓶可以用很久。\n\n提醒：有咖啡因又有酒精，晚上喝要注意睡眠。",
                tags: ["#超商調酒", "#咖啡香甜酒", "#甜點系"], likeCount: 201,
                comments: [
                    c(1, "這個當飯後甜點太讚", 290),
                    c(6, "咖啡因＋酒精容易睡不好，我都下午喝", 270),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("咖啡牛奶", "150ml"), i("咖啡香甜酒", "30ml"), i("冰塊", "半杯")],
                    steps: ["杯中放冰塊。", "倒入咖啡香甜酒。", "慢慢倒入咖啡牛奶，想要分層就沿著湯匙背倒。", "喝之前攪拌均勻。"],
                    difficulty: .easy, estimatedCost: "約 NT$80", sources: [.convenienceStore, .supermarket], containsAlcohol: true)),
            ForumPost(
                id: "mock-5", author: a(3), createdAt: ago(minutes: 60 * 8), category: .convenience,
                title: "薑汁汽水＋威士忌：超商版 Highball",
                body: "Highball 本來是威士忌加蘇打水，我改用薑汁汽水，比較有味道也比較好入口。冰塊一定要放滿，杯子越冰越好喝。",
                tags: ["#超商調酒", "#威士忌", "#Highball"], likeCount: 167,
                comments: [
                    c(5, "冰塊放滿真的差很多", 420),
                    c(2, "換成無糖氣泡水就是原版，也推", 400),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("威士忌", "30ml"), i("薑汁汽水", "120ml"), i("冰塊", "滿杯"), i("檸檬角", "1 塊（可省略）")],
                    steps: ["杯子裝滿冰塊，先攪拌幾圈讓杯子變冰，倒掉融出來的水。", "倒入威士忌 30ml。", "沿杯緣倒入薑汁汽水。", "用吸管從底部輕輕往上提一次就好。"],
                    difficulty: .easy, estimatedCost: "約 NT$75", sources: [.convenienceStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-6", author: a(7), createdAt: ago(minutes: 60 * 12), category: .convenience,
                title: "葡萄柚汁＋琴酒，加一點鹽超神",
                body: "這杯有點像簡化版的鹹狗。葡萄柚汁的苦甜跟琴酒的草本味很合，杯口抹一點鹽會讓甜味更明顯。超商的葡萄柚汁就可以用。",
                tags: ["#超商調酒", "#琴酒", "#葡萄柚"], likeCount: 98,
                comments: [
                    c(4, "抹鹽那步好可愛，拍照很好看", 700),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("葡萄柚汁", "150ml"), i("琴酒", "30ml"), i("鹽", "一小撮"), i("冰塊", "半杯")],
                    steps: ["杯口沾一點水，再倒扣在鹽上，沾一圈鹽邊。", "放入冰塊。", "倒入琴酒和葡萄柚汁，攪拌均勻。"],
                    difficulty: .easy, estimatedCost: "約 NT$85", sources: [.convenienceStore, .liquorStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-7", author: a(6), createdAt: ago(minutes: 60 * 18), category: .convenience,
                title: "啤酒＋檸檬汽水：低酒精的夏天清爽杯",
                body: "不太能喝的話推這杯，啤酒跟檸檬汽水一比一，酒精濃度直接減半，苦味也不見了。烤肉或宿舍聚會很適合。",
                tags: ["#超商調酒", "#啤酒", "#低酒精"], likeCount: 143,
                comments: [
                    c(0, "這個叫 Shandy 對吧！", 1000),
                    c(6, "對～低酒精版很適合邊聊天邊喝", 980),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("啤酒", "150ml"), i("檸檬汽水", "150ml"), i("冰塊", "少許（可省略）")],
                    steps: ["啤酒和檸檬汽水都先冰過。", "杯子斜放，先倒啤酒，再倒檸檬汽水。", "不用攪拌，直接喝。"],
                    difficulty: .easy, estimatedCost: "約 NT$65", sources: [.convenienceStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-8", author: a(1), createdAt: ago(minutes: 60 * 24), category: .classic,
                title: "琴通寧：經典調酒第一杯就從這裡開始",
                body: "Gin Tonic 材料只有三樣，做法超簡單，但很能喝出琴酒的差異。通寧水超市有，萊姆買不到用檸檬也可以。",
                tags: ["#經典調酒", "#琴酒", "#GinTonic"], likeCount: 176,
                comments: [
                    c(3, "通寧水一定要冰！", 1400),
                    c(2, "加小黃瓜片也很清爽", 1380),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("琴酒", "30ml"), i("通寧水", "120ml"), i("萊姆或檸檬", "1 角"), i("冰塊", "滿杯")],
                    steps: ["杯子裝滿冰塊。", "倒入琴酒。", "擠一點萊姆汁，把萊姆角丟進杯中。", "沿杯緣倒入通寧水，輕輕攪一下。"],
                    difficulty: .easy, estimatedCost: "約 NT$90", sources: [.supermarket, .liquorStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-9", author: a(4), createdAt: ago(minutes: 60 * 30), category: .classic,
                title: "簡化版莫希托：沒有搗棒用湯匙也行",
                body: "莫希托看起來很難，其實只是薄荷＋萊姆＋糖＋蘭姆酒＋氣泡水。薄荷超市就買得到，糖漿可以用砂糖加熱水自己做。",
                tags: ["#經典調酒", "#蘭姆酒", "#莫希托"], likeCount: 212,
                comments: [
                    c(7, "薄荷不要搗太爛，不然會苦", 1750),
                    c(5, "好看又好喝，派對必備", 1700),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("白蘭姆酒", "40ml"), i("新鮮薄荷葉", "8～10 片"), i("萊姆", "半顆，切塊"), i("糖漿", "15ml"), i("無糖氣泡水", "90ml"), i("冰塊", "滿杯")],
                    steps: ["薄荷、萊姆塊、糖漿放進杯底。", "用湯匙背輕輕壓幾下，聞到薄荷香就好。", "加滿冰塊，倒入白蘭姆酒。", "補上氣泡水，從底部往上拌勻。"],
                    difficulty: .medium, estimatedCost: "約 NT$120", sources: [.supermarket, .liquorStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-10", author: a(3), createdAt: ago(minutes: 60 * 40), category: .classic,
                title: "威士忌酸，用果醬罐搖也能起泡",
                body: "經典版會加蛋白，新手可以先省略。重點是檸檬汁一定要現擠，酸甜平衡就靠它。沒有雪克杯就用有蓋的果醬罐。",
                tags: ["#經典調酒", "#威士忌", "#酸酒"], likeCount: 121,
                comments: [
                    c(1, "果醬罐 yyds，洗乾淨就好", 2300),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("威士忌", "45ml"), i("現擠檸檬汁", "20ml"), i("糖漿", "15ml"), i("冰塊", "1 杯")],
                    steps: ["把威士忌、檸檬汁、糖漿和冰塊放進罐子。", "蓋緊用力搖 15 秒。", "濾掉冰塊倒進杯子，可以再加新的冰塊。"],
                    difficulty: .medium, estimatedCost: "約 NT$100", sources: [.supermarket, .liquorStore], containsAlcohol: true)),
            ForumPost(
                id: "mock-11", author: a(6), createdAt: ago(minutes: 60 * 46), category: .nonAlcoholic,
                title: "無酒精莫希托，不喝酒也能一起舉杯",
                body: "聚會有朋友不喝酒，就幫他們做這杯。把蘭姆酒拿掉、氣泡水加多一點，再加一點蜂蜜，清爽到我自己也比較想喝這杯。",
                tags: ["#無酒精", "#莫希托", "#聚會"], likeCount: 189,
                comments: [
                    c(4, "大推！開車的朋友也能一起玩", 2700),
                    c(0, "加一點蘋果汁也很好喝", 2650),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("新鮮薄荷葉", "8～10 片"), i("檸檬", "半顆，切塊"), i("蜂蜜", "1 湯匙"), i("無糖氣泡水", "200ml"), i("冰塊", "滿杯")],
                    steps: ["薄荷、檸檬塊和蜂蜜放進杯底。", "用湯匙背輕壓出香味。", "加滿冰塊。", "倒入氣泡水拌勻。"],
                    difficulty: .easy, estimatedCost: "約 NT$50", sources: [.supermarket, .convenienceStore], containsAlcohol: false)),
            ForumPost(
                id: "mock-12", author: a(2), createdAt: ago(minutes: 60 * 60), category: .nonAlcoholic,
                title: "超商無酒精日出：柳橙汁＋莓果汁做漸層",
                body: "外觀很像龍舌蘭日出，但完全沒有酒精。重點是莓果汁最後沿杯緣慢慢倒，它比較重會沉下去，就會有漂亮的漸層。",
                tags: ["#無酒精", "#超商調酒", "#好拍"], likeCount: 132,
                comments: [
                    c(7, "做給妹妹喝她超開心", 3500),
                ],
                recipe: ForumRecipe(
                    ingredients: [i("柳橙汁", "150ml"), i("蔓越莓汁", "40ml"), i("無糖氣泡水", "50ml"), i("冰塊", "滿杯")],
                    steps: ["杯子裝滿冰塊，倒入柳橙汁和氣泡水。", "沿著杯緣慢慢倒入蔓越莓汁，讓它沉到底部。", "不要攪拌，先拍照再喝。"],
                    difficulty: .easy, estimatedCost: "約 NT$55", sources: [.convenienceStore], containsAlcohol: false)),
            ForumPost(
                id: "mock-13", author: a(1), createdAt: ago(minutes: 60 * 72), category: .technique,
                title: "沒有器材也能調：宿舍替代工具整理",
                body: "雪克杯 → 有蓋的果醬罐或保溫瓶\n量酒器 → 一湯匙大約 15ml，兩湯匙就是 30ml\n搗棒 → 湯匙背或擀麵棍\n吧匙 → 筷子\n濾冰器 → 罐子蓋子開一條縫\n\n先用量好的份量調，習慣之後就知道一杯大概多少，不用每次都倒很多。",
                tags: ["#技巧器材", "#宿舍", "#新手必看"], likeCount: 265,
                comments: [
                    c(5, "一湯匙 15ml 這個超實用", 4300),
                    c(3, "保溫瓶搖完記得洗乾淨，不然隔天泡茶會有酒味", 4200),
                ]),
            ForumPost(
                id: "mock-14", author: a(6), createdAt: ago(minutes: 60 * 96), category: .newbie,
                title: "第一次自己調，怎麼知道酒有沒有放太多？",
                body: "看網路上的酒譜都說 30ml、45ml，但我們家沒有量杯，怕不小心倒太多。大家都怎麼抓份量？",
                tags: ["#新手問題", "#份量"], likeCount: 76,
                comments: [
                    c(1, "用湯匙量，一湯匙 15ml，兩湯匙就夠一杯了", 5700),
                    c(0, "寧可先少放，喝起來太淡再加一點點", 5650),
                    c(4, "還有一杯酒配一杯水，慢慢喝，不要比誰喝得快", 5600),
                ]),
            ForumPost(
                id: "mock-16", author: a(7), createdAt: ago(minutes: 60 * 6), category: .classic,
                title: "週末串酒吧：兩站之間留一段散步時間",
                body: "這次只排兩間酒吧，第一站聊聊天，第二站慢慢喝一杯。比起趕場，我更喜歡在兩站之間走走，看看夜裡的街道。\n\n挑店時先看座位和吧檯氛圍，點酒前也會跟店員說自己喜歡偏酸還是偏甜。回程就搭車，不開車。",
                tags: ["#串酒吧", "#週末散步", "#酒吧氛圍"], likeCount: 87),
            ForumPost(
                id: "mock-15", author: a(0), createdAt: ago(minutes: 60 * 120), category: .newbie,
                title: "不太會喝酒，有推薦入門的超商組合嗎？",
                body: "朋友都在玩超商調酒，我酒量很差，喝一點就會臉紅。有沒有酒精少一點、好入口的組合？",
                tags: ["#新手問題", "#低酒精"], likeCount: 64,
                comments: [
                    c(6, "啤酒＋檸檬汽水一比一，或梅酒加很多氣泡水", 7000),
                    c(2, "其實無酒精版本也很好喝，不用勉強自己", 6900),
                    c(7, "臉紅就是身體在提醒你了，喝水休息最重要", 6850),
                ]),
        ]
        let images: [String: [ForumPhoto]] = [
            "mock-1": [ForumPhotoLibrary.citrusGlass, ForumPhotoLibrary.citrusPrep],
            "mock-2": [ForumPhotoLibrary.whiteDrink],
            "mock-3": [ForumPhotoLibrary.lemonSoda],
            "mock-5": [ForumPhotoLibrary.whiskyAmber],
            "mock-6": [ForumPhotoLibrary.orangeCocktail, ForumPhotoLibrary.grapefruitGlass],
            "mock-7": [ForumPhotoLibrary.beerTall, ForumPhotoLibrary.beerMug],
            "mock-8": [ForumPhotoLibrary.gardenGlass, ForumPhotoLibrary.ginHighball],
            "mock-9": [ForumPhotoLibrary.mintLime, ForumPhotoLibrary.mojitoTall],
            "mock-10": [ForumPhotoLibrary.whiskyBar],
            "mock-11": [ForumPhotoLibrary.lemonMint],
            "mock-12": [ForumPhotoLibrary.orangeLayers],
            "mock-13": [ForumPhotoLibrary.barTools],
            "mock-16": [ForumPhotoLibrary.barBrick, ForumPhotoLibrary.barStools, ForumPhotoLibrary.nightStreet],
        ]
        let illustratedPosts = posts.map { post in
            var illustrated = post
            illustrated.photos = images[post.id] ?? []
            return illustrated
        }
        #if DEBUG && canImport(UIKit)
        ForumPhotoLibrary.validate(illustratedPosts) { UIImage(named: $0) != nil }
        #endif
        return illustratedPosts
    }
}
