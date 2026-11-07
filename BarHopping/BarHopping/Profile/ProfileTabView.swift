import SwiftUI

/// 「你」個人分頁：個人檔案、通票狀態、跑吧統計、安全代駕與圖資授權
struct ProfileTabView: View {
    @Environment(UserProfileStore.self) private var userProfile
    @State private var showingAvatarPicker = false
    @State private var showingPassRedemption = false
    @State private var showingRideAlert = false
    @State private var showingSuccessRedeemAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 1. 個人檔案卡片
                    profileHeaderCard

                    // MARK: - 2. 跑吧通票狀態（Demo 核心亮點）
                    barHoppingPassCard

                    // MARK: - 3. 跑吧數據統計
                    statsOverviewSection

                    // MARK: - 4. 微醺成就徽章
                    badgesSection

                    // MARK: - 5. 平安微醺（安全叫車／代駕捷徑）
                    safetyRideCard

                    // MARK: - 6. 地圖資料來源與版本資訊
                    legalAttributionSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("你")
            .sheet(isPresented: $showingAvatarPicker) {
                avatarPickerSheet
            }
            .sheet(isPresented: $showingPassRedemption) {
                passRedemptionSheet
            }
            .alert("已準備為您叫車", isPresented: $showingRideAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text("正在為您開啟合作計程車／代駕平台，微醺愉快，安全回家！")
            }
            .alert("核銷成功！", isPresented: $showingSuccessRedeemAlert) {
                Button("太棒了", role: .cancel) { }
            } message: {
                Text("已成功兌換一杯特調飲品！通票剩餘額度已更新。")
            }
        }
    }

    // MARK: - 視圖元件

    private var profileHeaderCard: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let avatar = userProfile.customAvatarImage {
                    avatar
                        .resizable()
                        .scaledToFit()
                        .padding(14)
                        .frame(width: 74, height: 74)
                        .background(Color.pink.opacity(0.15))
                        .foregroundStyle(.pink)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink.opacity(0.3), lineWidth: 2))
                } else {
                    Image(UserAvatarIcon.assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 74, height: 74)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink.opacity(0.3), lineWidth: 2))
                        .accessibilityLabel("大頭貼")
                }

                Button {
                    showingAvatarPicker = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 24))
                        .background(Circle().fill(Color(.systemBackground)))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(userProfile.nickname)
                        .font(.title3.bold())

                    Text(userProfile.levelTitle)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.15))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }

                Text("西屯逢甲商圈 • 活躍跑吧者")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var barHoppingPassCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("我的跑吧通票", systemImage: "ticket.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Spacer()

                Text("使用中")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(userProfile.passName)
                    .font(.system(size: 17, weight: .bold))

                Text("每間合作酒吧限換 1 杯迎賓特調 • 逢甲商圈專用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 進度條
            VStack(spacing: 6) {
                ProgressView(value: Double(userProfile.passRedeemedDrinks), total: Double(userProfile.passTotalDrinks))
                    .tint(.orange)

                HStack {
                    Text("已兌換 \(userProfile.passRedeemedDrinks) 杯")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("還可換 \(userProfile.remainingDrinks) 杯")
                        .font(.caption.bold())
                        .foregroundStyle(userProfile.remainingDrinks > 0 ? .orange : .secondary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    showingPassRedemption = true
                } label: {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("出示換酒碼")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statsOverviewSection: some View {
        HStack(spacing: 12) {
            statItem(title: "已踩點酒吧", value: "\(userProfile.visitedBarsCount) 間", icon: "wineglass.fill", color: .purple)
            statItem(title: "累積步行", value: String(format: "%.1f km", userProfile.totalWalkingKm), icon: "figure.walk", color: .blue)
            statItem(title: "目前狀態", value: userProfile.soberScore, icon: "heart.fill", color: .pink)
        }
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("微醺成就徽章")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    badgeView(title: "逢甲首跑", subtitle: "初次出發", icon: "flag.fill", unlocked: true)
                    badgeView(title: "暗門探險", subtitle: "黑洞酒吧", icon: "sparkles", unlocked: true)
                    badgeView(title: "飛鏢神手", subtitle: "Wales飛鏢吧", icon: "target", unlocked: true)
                    badgeView(title: "四店制霸", subtitle: "一晚跑滿", icon: "crown.fill", unlocked: false)
                }
            }
        }
    }

    private func badgeView(title: String, subtitle: String, icon: String, unlocked: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(unlocked ? Color.orange : Color.gray)
            }

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(unlocked ? .primary : .secondary)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var safetyRideCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "car.side.fill")
                .font(.title)
                .foregroundStyle(.green)
                .frame(width: 44, height: 44)
                .background(Color.green.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("平安微醺 • 安全回家")
                    .font(.subheadline.bold())
                Text("開車不喝酒，隨時為您一鍵呼叫代駕或計程車。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("叫車") {
                showingRideAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .font(.caption.bold())
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var legalAttributionSection: some View {
        VStack(spacing: 6) {
            Text("地圖與路網技術由 OpenStreetMap contributors、MapLibre 及 Valhalla 提供。")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("BarHopping v1.0 • 專為台中夜生活打造")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - 彈出表單

    private var avatarPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("選擇你喜歡的微醺頭像")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                    ForEach(UserProfileStore.presets) { preset in
                        Button {
                            userProfile.selectPreset(preset)
                            showingAvatarPicker = false
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: preset.systemImage)
                                    .font(.system(size: 36))
                                    .foregroundStyle(preset.color)
                                    .frame(width: 64, height: 64)
                                    .background(preset.color.opacity(0.15))
                                    .clipShape(Circle())

                                Text(preset.name)
                                    .font(.caption.bold())
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(userProfile.selectedPresetId == preset.id ? Color.pink : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding()

                Button("還原預設圖示", role: .destructive) {
                    userProfile.resetDefaultAvatar()
                    showingAvatarPicker = false
                }
                .font(.caption)

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("更換頭像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { showingAvatarPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var passRedemptionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("到店出示此畫面")
                        .font(.headline)
                    Text("提供給酒吧店員核銷即可領取專屬特調")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // QR 碼視覺模擬
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 200, height: 200)
                        .shadow(color: .black.opacity(0.1), radius: 8)

                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                            .foregroundStyle(.black)

                        Text(userProfile.passCode)
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }

                VStack(spacing: 6) {
                    Text(userProfile.passName)
                        .font(.subheadline.bold())
                    Text("剩餘兌換額度：\(userProfile.remainingDrinks) / \(userProfile.passTotalDrinks) 杯")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                // 供 Demo 使用的模擬店員按鈕
                Button {
                    userProfile.redeemDrink()
                    showingPassRedemption = false
                    showingSuccessRedeemAlert = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("模擬店家核銷（Demo 演示用）")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userProfile.remainingDrinks > 0 ? Color.green : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(userProfile.remainingDrinks == 0)

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("核銷跑吧券")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { showingPassRedemption = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ProfileTabView()
        .environment(UserProfileStore())
}
