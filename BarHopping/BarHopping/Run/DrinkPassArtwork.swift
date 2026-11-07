enum DrinkPassArtwork {
    static let qrPayloadOverride: String? = "https://tsaicy.dev"

    static func qrCodePayload(for purchase: DrinkPassPurchase) -> String {
        qrPayloadOverride ?? purchase.ticketNumber
    }

    /// Banner 與詳細頁共用使用者提供的官方主視覺。
    static let keyVisualImageName = "drinkpass-longser9za-keyvisual"
}
