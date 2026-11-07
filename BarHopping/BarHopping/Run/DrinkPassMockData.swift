enum DrinkPassMockData {
    static let event = DrinkPassEvent(
        name: "龍蛇酒雜 LONG SER 9 ZA",
        tagline: "慢慢走、聊一杯，串起城市裡的微醺夜晚。",
        dateTime: "2027 年 1 月 16 日（六）18:00–22:00（示範）",
        meetingPoint: "台中市西區・虛構星光廣場（示範，無實際集合點）",
        routeLength: "步行約 2.4 公里（示範）",
        introduction: "這是一場以步行串店為主的示範活動。持酒票到合作店家，每間可兌換一杯指定飲品，自選順序慢慢逛；不競速、不比酒量。可選無酒精飲品，請量力而飲。",
        options: [
            .init(id: "early", name: "早鳥單人票", price: 499, cups: 3,
                  validity: "2027/01/16 18:00–22:00，限活動當日（示範）"),
            .init(id: "single", name: "單人票", price: 699, cups: 4,
                  validity: "2027/01/16 18:00–22:00，限活動當日（示範）"),
            .init(id: "duo", name: "雙人票", price: 1299, cups: 8,
                  validity: "2027/01/16 18:00–22:00，限活動當日（示範）")
        ],
        venues: [
            .init(id: "cloud", name: "雲朵蜥蜴試飲所（虛構）",
                  address: "台中市西區示範雲朵路 101 號（虛構地址）", drink: "柚香氣泡調酒／柚子蘇打"),
            .init(id: "moon", name: "月球水獺小酒室（虛構）",
                  address: "台中市西區示範月球街 202 號（虛構地址）", drink: "桂花琴酒／桂花氣泡茶"),
            .init(id: "comet", name: "彗星紙鶴吧（虛構）",
                  address: "台中市西區示範彗星巷 303 號（虛構地址）", drink: "莓果沙瓦／莓果蘇打"),
            .init(id: "forest", name: "森林機器貓酒館（虛構）",
                  address: "台中市西區示範森林路 404 號（虛構地址）", drink: "烏龍威士忌／冷泡烏龍"),
            .init(id: "planet", name: "行星棉花糖俱樂部（虛構）",
                  address: "台中市西區示範行星街 505 號（虛構地址）", drink: "百香果調酒／百香果氣泡飲")
        ],
        questions: [
            .init(id: "age", title: "誰可以參加？",
                  answer: "限 18 歲以上，入場與兌換時需出示有效身分證件。未滿 18 歲禁止飲酒。"),
            .init(id: "redeem", title: "酒票怎麼用？",
                  answer: "示範規則為每間店每人限換一杯指定飲品，依票券總杯數為上限；雙人票共 8 杯，兩人各 4 杯。可選無酒精飲品。示範票券無法實際兌換。"),
            .init(id: "cash", title: "可以換現金或延後使用嗎？",
                  answer: "酒票不可兌換現金，限標示期限內使用。本頁沒有真實交易、收費、退票或訂位服務。"),
            .init(id: "safety", title: "活動後怎麼回家？",
                  answer: "禁止酒駕。請安排計程車、代駕或親友接送，不開車也不騎車。飲酒過量，有害健康。")
        ]
    )
}
