import Foundation

/// 論壇假資料（台中市）。店名一律虛構或不寫，不鼓勵拚酒、酒駕。
enum ForumMockData {
    static let authors: [ForumAuthor] = [
        ForumAuthor(name: "小安", initials: "安", colorIndex: 0),
        ForumAuthor(name: "Kevin 走走", initials: "K", colorIndex: 1),
        ForumAuthor(name: "柚子", initials: "柚", colorIndex: 2),
        ForumAuthor(name: "阿哲不加冰", initials: "哲", colorIndex: 3),
        ForumAuthor(name: "Mia", initials: "M", colorIndex: 4),
        ForumAuthor(name: "中興散步社", initials: "散", colorIndex: 5),
        ForumAuthor(name: "小魚", initials: "魚", colorIndex: 6),
        ForumAuthor(name: "Jerry", initials: "J", colorIndex: 7),
    ]

    private static func a(_ i: Int) -> ForumAuthor { authors[i] }

    static func posts(now: Date) -> [ForumPost] {
        func ago(minutes: Double) -> Date { now.addingTimeInterval(-minutes * 60) }
        func c(_ author: Int, _ body: String, _ minutesAgo: Double) -> ForumComment {
            ForumComment(author: a(author), body: body, createdAt: ago(minutes: minutesAgo))
        }

        return [
            ForumPost(
                id: "mock-1", author: a(0), createdAt: ago(minutes: 42), category: .routeShare,
                title: "草悟道散步三站，全程不到 2 公里",
                body: "從勤美誠品前面出發，沿著草悟道一路往北走。第一站是巷子裡只有吧台座位的小店，老闆很會聊天；第二站在綠園道旁邊，有手寫酒單，也有不少無酒精選項；最後走到市民廣場附近收尾。\n\n整條都是平路，草悟道晚上人多燈也亮，自己走也覺得安心。建議每站停 40 分鐘左右，不會太趕。",
                tags: ["#西區", "#草悟道", "#路線分享"], likeCount: 128,
                comments: [
                    c(2, "草悟道晚上散步真的很舒服！收藏起來這週去", 30),
                    c(4, "第二站是不是門口有一盞黃色的燈？我去過，氣氛很好", 18),
                    c(0, "對就是那間！", 12),
                ],
                route: ForumRouteSummary(stopCount: 3, distanceMeters: 1850, walkingSeconds: 1500)),
            ForumPost(
                id: "mock-2", author: a(5), createdAt: ago(minutes: 95), category: .meetup,
                title: "【揪團】期末考完一中街慢走團，不拚酒只聊天",
                body: "考完試想放鬆一下但不想去太吵的地方？這週五晚上 7 點一中街口集合，先吃點東西墊胃，再往台中公園方向散步，中間停兩站，主要是聊天跟認識新朋友。\n\n不會喝酒也歡迎，兩站都有無酒精特調。預計 10 點前結束。目前 5 人，上限 8 人，留言 +1 就好。",
                tags: ["#北區", "#一中", "#揪團"], likeCount: 56,
                comments: [
                    c(6, "+1！我不太會喝，有無酒精的太好了", 80),
                    c(7, "+1 帶室友一起可以嗎", 61),
                    c(5, "可以呀，記得兩個人都留言就好", 55),
                ]),
            ForumPost(
                id: "mock-3", author: a(3), createdAt: ago(minutes: 60 * 3), category: .newbie,
                title: "第一次規劃路線，每站停留時間抓多久比較剛好？",
                body: "想帶朋友走七期三站，App 預設每站 30 分鐘，但總覺得聊開了會不夠。大家通常會設多久？還有站跟站之間走路多久比較舒服？",
                tags: ["#新手", "#七期"], likeCount: 23,
                comments: [
                    c(0, "我習慣 40～50 分鐘，站間走路 10 分鐘內最舒服，剛好散散步", 150),
                    c(1, "七期街廓很大，看地圖很近其實要走一陣子，第一次建議兩站就好", 120),
                ]),
            ForumPost(
                id: "mock-4", author: a(4), createdAt: ago(minutes: 60 * 5), category: .venueReview,
                title: "審計新村旁邊，無酒精調酒很認真的小店",
                body: "最近在減少酒精但還是想跟朋友出門，意外發現這間的無酒精特調超用心：用烏龍茶、柚子和氣泡水調的那杯很有層次，完全不輸一般調酒。店員也不會因為你點無酒精就給你臉色看。\n\n座位不多，週末審計新村人潮多，建議平日去。",
                tags: ["#西區", "#審計新村", "#無酒精"], likeCount: 214,
                comments: [
                    c(2, "烏龍柚子那杯我也喝過！好喝", 250),
                    c(3, "求推薦更多有無酒精選項的店", 210),
                    c(4, "之後整理一篇分享～", 200),
                ]),
            ForumPost(
                id: "mock-5", author: a(1), createdAt: ago(minutes: 60 * 9), category: .routeShare,
                title: "中區舊城老屋巡禮：台中車站 → 綠川 → 老屋酒吧",
                body: "傍晚從台中車站出發，先沿著綠川水岸走，晚上河道點燈很好拍。接著往繼光街、中區舊城的巷子鑽，第一站是老屋改建的小酒館，木頭窗框超有味道。之後再走兩站，最後繞回車站。\n\n整條路線 4 站、2.6 公里，中區很多單行道，走路反而最方便。",
                tags: ["#中區", "#舊城", "#路線分享"], likeCount: 302,
                comments: [
                    c(6, "綠川夜景 + 散步這個組合太讚了", 500),
                    c(7, "上週照著走一次，老屋真的很好拍", 420),
                ],
                route: ForumRouteSummary(stopCount: 4, distanceMeters: 2600, walkingSeconds: 2100)),
            ForumPost(
                id: "mock-6", author: a(6), createdAt: ago(minutes: 60 * 14), category: .newbie,
                title: "一個人去酒吧會不會很尷尬？",
                body: "想試試看自己一個人出門走走，但很怕坐下來不知道要幹嘛。有沒有人分享一下一個人去的經驗？適合坐吧台還是找角落？",
                tags: ["#新手", "#一個人"], likeCount: 87,
                comments: [
                    c(4, "坐吧台！跟調酒師聊天很自然，也可以只點一杯慢慢喝", 800),
                    c(0, "帶本書或耳機也可以，沒人會覺得奇怪", 700),
                    c(3, "選有 live 音樂的店，聽歌就不會無聊", 650),
                ]),
            ForumPost(
                id: "mock-7", author: a(7), createdAt: ago(minutes: 60 * 20), category: .meetup,
                title: "週六爵士之夜，找人一起去精明一街聽 live",
                body: "週六晚上八點精明一街附近有一場小型爵士演出，在一間地下室小店，低消一杯（有無酒精）。想找 2～3 個也喜歡爵士的人一起去，聽完可以散步去下一站聊聊。",
                tags: ["#西屯", "#精明一街", "#揪團"], likeCount: 41,
                comments: [
                    c(1, "我想去！大學爵士社的", 1100),
                ]),
            ForumPost(
                id: "mock-8", author: a(2), createdAt: ago(minutes: 60 * 26), category: .venueReview,
                title: "公益路巷子裡的精釀小店，有手寫酒單跟貓",
                body: "公益路大家都是去吃燒肉，但轉進巷子裡有一間很小的精釀店，酒單每週換，老闆會手寫每支酒的風味。店裡有一隻很親人的橘貓。\n\n小提醒：店裡有提供免費的水，每杯之間記得喝一點。",
                tags: ["#南屯", "#公益路", "#精釀"], likeCount: 176,
                comments: [
                    c(5, "有貓直接加分", 1500),
                    c(6, "吃完燒肉散步過去剛好消化", 1400),
                ]),
            ForumPost(
                id: "mock-9", author: a(0), createdAt: ago(minutes: 60 * 36), category: .newbie,
                title: "聊太晚之後大家都怎麼安全回家？",
                body: "上次在逢甲聊太晚，公車都沒了，最後在路邊等車有點不安。想問大家都怎麼安排回家？我自己之後會在 App 裡先把最後一站排在大路或公車站附近。",
                tags: ["#安全回家", "#新手"], likeCount: 132,
                comments: [
                    c(1, "我都會設 23:30 的鬧鐘提醒自己", 2000),
                    c(7, "跟朋友一起叫車分攤，到家互傳訊息報平安", 1900),
                    c(3, "有騎車來的話就別喝了，或是直接搭車回家隔天再牽", 1850),
                ]),
            ForumPost(
                id: "mock-10", author: a(3), createdAt: ago(minutes: 60 * 48), category: .routeShare,
                title: "逢甲夜市外圍散步：避開人潮的三站路線",
                body: "逢甲夜市人太多？其實外圍的巷子很好逛。從逢甲大學正門出發，繞過夜市主街往福星路方向走，中間兩站都是小小的社區型酒吧，價格也很學生友善。\n\n全程 2.1 公里，平路，邊走還可以順便買點小吃。",
                tags: ["#西屯", "#逢甲", "#路線分享"], likeCount: 95,
                comments: [
                    c(2, "逢甲外圍真的比主街舒服很多", 2700),
                ],
                route: ForumRouteSummary(stopCount: 3, distanceMeters: 2100, walkingSeconds: 1680)),
            ForumPost(
                id: "mock-11", author: a(4), createdAt: ago(minutes: 60 * 72), category: .venueReview,
                title: "勤美附近的黑膠小酒館，安靜適合聊天",
                body: "勤美商圈旁邊的巷子裡，整面牆都是黑膠唱片，可以自己挑一張請店員放。音量剛好可以聊天，很適合第一次約會或跟久沒見的朋友敘舊。",
                tags: ["#西區", "#勤美", "#黑膠"], likeCount: 158,
                comments: [
                    c(7, "可以自己選歌太浪漫了", 4000),
                    c(0, "加入我的下一條路線！", 3900),
                ]),
            ForumPost(
                id: "mock-12", author: a(1), createdAt: ago(minutes: 60 * 96), category: .routeShare,
                title: "精明一街小巷散步：三站都在 500 公尺內",
                body: "精明一街一帶的巷子比想像中好逛，三站彼此都很近，適合不想走太多路的朋友。晚上的徒步區很漂亮，常常有街頭藝人表演。",
                tags: ["#西屯", "#精明一街", "#路線分享"], likeCount: 64,
                comments: [
                    c(6, "精明一街晚上很有氣氛，很喜歡", 5600),
                ],
                route: ForumRouteSummary(stopCount: 3, distanceMeters: 1300, walkingSeconds: 1020)),
            ForumPost(
                id: "mock-13", author: a(5), createdAt: ago(minutes: 60 * 120), category: .meetup,
                title: "【揪團】七期下班散步團，還差 2 人",
                body: "週五 7 點市政府附近集合，走秋紅谷、七期一圈，中間停兩站。主打散步跟拍夜景，喝什麼隨意。走路大約 3 公里，記得穿好走的鞋！",
                tags: ["#西屯", "#七期", "#揪團"], likeCount: 38,
                comments: [
                    c(2, "+1 我可以！秋紅谷夜景超美", 7000),
                ],
                route: ForumRouteSummary(stopCount: 2, distanceMeters: 3000, walkingSeconds: 2400)),
        ]
    }
}
