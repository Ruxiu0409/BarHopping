import SwiftUI

struct DrinkPassDetailView: View {
    let event: DrinkPassEvent
    @Environment(DrinkPassStore.self) private var store

    @State private var selectedOptionID: String
    @State private var quantity = 1
    @State private var pendingPurchase: DrinkPassPurchase?
    @State private var showPurchaseConfirmation = false

    init(event: DrinkPassEvent) {
        self.event = event
        _selectedOptionID = State(initialValue: event.options.first?.id ?? "")
    }

    private var selectedOption: DrinkPassEvent.Option? {
        event.options.first { $0.id == selectedOptionID }
    }

    var body: some View {
        List {
            Group {
                Section {
                    DrinkPassKeyVisual(isDecorative: false)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                }
                .listRowInsets(EdgeInsets())

                Section {
                    Text("示範資料，非真實活動")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    DrinkPassSafetyNotice()
                }

                Section("活動介紹") {
                    Text(event.name).font(.title2.bold())
                    Text(event.tagline).foregroundStyle(AppTheme.textSecondary)
                    Label(event.dateTime, systemImage: "calendar")
                    Label(event.meetingPoint, systemImage: "mappin.and.ellipse")
                    Label(event.routeLength, systemImage: "figure.walk")
                    Text(event.introduction)
                }

                Section("酒票方案（示範）") {
                    ForEach(event.options) { option in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(option.name).font(.headline)
                            Text("NT$ \(option.price)／份・含 \(option.cups) 杯")
                            Text("使用期限：\(option.validity)")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Picker("方案", selection: $selectedOptionID) {
                        ForEach(event.options) { option in
                            Text(option.name).tag(option.id)
                        }
                    }
                    .pickerStyle(.inline)
                    Stepper("數量：\(quantity) 份", value: $quantity, in: 1...10)
                    if let option = selectedOption {
                        Text("合計 NT$ \(option.price * quantity)・共 \(option.cups * quantity) 杯")
                            .font(.headline)
                    }
                    Button("示範購買", action: requestPurchase)
                        .font(.headline)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(selectedOption == nil)
                        .accessibilityHint("確認後產生假酒票，不會收費")
                        .alert("確認示範購買", isPresented: $showPurchaseConfirmation,
                               presenting: pendingPurchase) { purchase in
                            Button("確認示範購買") { completePurchase(purchase) }
                            Button("取消", role: .cancel) { pendingPurchase = nil }
                        } message: { purchase in
                            Text("\(purchase.option.name) × \(purchase.quantity)，共 NT$ \(purchase.totalPrice)。僅供示範，不會付款或送出訂單。")
                        }
                } header: {
                    Text("購買（示範）")
                } footer: {
                    Text("此流程只在記憶體產生示範紀錄，不收費、不連線、不建立真實訂單。")
                }

                if !store.purchases.isEmpty {
                    Section("我的示範酒票") {
                        ForEach(store.purchases.reversed()) { purchase in
                            DrinkPassTicketView(purchase: purchase)
                        }
                    }
                }

                Section {
                    ForEach(event.venues) { venue in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(venue.name).font(.headline)
                            Text(venue.address)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("可兌換：\(venue.drink)")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("合作店家（全為虛構）")
                } footer: {
                    Text("以下店名、地址及合作關係皆為虛構，不代表任何真實店家參與。")
                }

                Section("注意事項／常見問題") {
                    ForEach(event.questions) { question in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(question.title).font(.headline)
                            Text(question.answer).font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    DrinkPassSafetyNotice()
                    SafeRideButton()
                    Text("示範資料，非真實活動")
                        .font(.footnote.bold())
                }
            }
            .listRowBackground(AppTheme.surface)
            .listRowSeparatorTint(AppTheme.separator)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
        .tint(AppTheme.accent)
        .navigationTitle("酒票介紹")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    }

    private func requestPurchase() {
        guard let option = selectedOption else { return }
        pendingPurchase = DrinkPassPurchase(eventName: event.name, option: option, quantity: quantity)
        showPurchaseConfirmation = true
    }

    private func completePurchase(_ purchase: DrinkPassPurchase) {
        store.record(purchase)
        pendingPurchase = nil
        AccessibilityNotification.Announcement("示範購買成功，未收取款項。可到路跑頁的我的酒票查看票券。").post()
    }
}
