import SwiftUI

// MARK: - Liquid Glass (液態微醺毛玻璃) 樣式修飾器

struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.02),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 7)
    }
}

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
    }
}

/// 「你」個人分頁：全面採用 Liquid Glass（液態毛玻璃）微醺風格
struct ProfileTabView: View {
    @Environment(UserProfileStore.self) private var userProfile
    @State private var showingAvatarPicker = false
    @State private var showingPassRedemption = false
    @State private var showingRideAlert = false
    @State private var showingSuccessRedeemAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - 液態微醺流光背景 (Liquid Ambient Canvas)
                Color(red: 10 / 255, green: 12 / 255, blue: 22 / 255)
                    .ignoresSafeArea()

                GeometryReader { proxy in
                    Circle()
                        .fill(Color(red: 255 / 255, green: 42 / 255, blue: 133 / 255).opacity(0.35))
                        .frame(width: 280, height: 280)
                        .blur(radius: 80)
                        .offset(x: -50, y: -20)

                    Circle()
                        .fill(Color(red: 255 / 255, green: 110 / 255, blue: 0 / 255).opacity(0.28))
                        .frame(width: 250, height: 250)
                        .blur(radius: 70)
                        .offset(x: proxy.size.width - 170, y: 190)

                    Circle()
                        .fill(Color(red: 128 / 255, green: 45 / 255, blue: 255 / 255).opacity(0.32))
                        .frame(width: 300, height: 300)
                        .blur(radius: 90)
                        .offset(x: 20, y: proxy.size.height - 240)
                }
                .ignoresSafeArea()

                // MARK: - 主內容列表
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. 個人檔案 Liquid Glass 卡片
                        profileHeaderCard

                        // 2. 跑吧通票 Liquid Glass 尊爵卡
                        barHoppingPassCard

                        // 3. 跑吧數據 Liquid Glass 網格
                        statsOverviewSection

                        // 4. 微醺成就徽章冊
                        badgesSection

                        // 5. 平安微醺（安全叫車／代駕捷徑）
                        safetyRideCard

                        // 6. 地圖資料來源與版本資訊
                        legalAttributionSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("你")
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
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
                        .frame(width: 76, height: 76)
                        .background(Color.pink.opacity(0.2))
                        .foregroundStyle(.pink)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink.opacity(0.5), lineWidth: 2))
                } else {
                    Image(UserAvatarIcon.assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink.opacity(0.4), lineWidth: 2))
                        .accessibilityLabel("大頭貼")
                }

                Button {
                    showingAvatarPicker = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 24))
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(userProfile.nickname)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(userProfile.levelTitle)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.purple.opacity(0.4), .pink.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                        )
                        .overlay(Capsule().stroke(Color.pink.opacity(0.3), lineWidth: 1))
                        .foregroundStyle(.white)
                }

                Text("西屯逢甲商圈 • 活躍跑吧者")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 22)
    }

    private var barHoppingPassCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(.orange)
                    Text("我的跑吧通票")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("使用中")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.18))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(userProfile.passName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text("每間合作酒吧限換 1 杯迎賓特調 • 逢甲商圈專用")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            // 進度條與額度顯示
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(userProfile.passRedeemedDrinks) / CGFloat(max(1, userProfile.passTotalDrinks)), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("已兌換 \(userProfile.passRedeemedDrinks) 杯")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text("還可換 \(userProfile.remainingDrinks) 杯")
                        .font(.caption.bold())
                        .foregroundStyle(userProfile.remainingDrinks > 0 ? Color.orange : Color.white.opacity(0.5))
                }
            }
            .padding(.vertical, 2)

            Button {
                showingPassRedemption = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 16, weight: .bold))
                    Text("出示換酒碼")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(red: 255 / 255, green: 110 / 255, blue: 0 / 255), Color(red: 255 / 255, green: 60 / 255, blue: 110 / 255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.orange.opacity(0.35), radius: 8, x: 0, y: 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.15), Color.purple.opacity(0.12), Color.pink.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .liquidGlassCard(cornerRadius: 22)
    }

    private var statsOverviewSection: some View {
        HStack(spacing: 12) {
            statItem(title: "已踩點酒吧", value: "\(userProfile.visitedBarsCount) 間", icon: "wineglass.fill", color: .purple)
            statItem(title: "累積步行", value: String(format: "%.1f km", userProfile.totalWalkingKm), icon: "figure.walk", color: .cyan)
            statItem(title: "目前狀態", value: userProfile.soberScore, icon: "heart.fill", color: .pink)
        }
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 6)

            Text(value)
                .font(.headline)
                .foregroundStyle(.white)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .liquidGlassCard(cornerRadius: 18)
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("微醺成就徽章")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("已解鎖 3 / 4")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    badgeView(title: "逢甲首跑", subtitle: "初次出發", icon: "flag.fill", unlocked: true, accentColor: .orange)
                    badgeView(title: "暗門探險", subtitle: "黑洞酒吧", icon: "sparkles", unlocked: true, accentColor: .pink)
                    badgeView(title: "飛鏢神手", subtitle: "Wales飛鏢吧", icon: "target", unlocked: true, accentColor: .cyan)
                    badgeView(title: "四店制霸", subtitle: "一晚跑滿", icon: "crown.fill", unlocked: false, accentColor: .yellow)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func badgeView(title: String, subtitle: String, icon: String, unlocked: Bool, accentColor: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(unlocked ? accentColor.opacity(0.2) : Color.white.opacity(0.06))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle().stroke(unlocked ? accentColor.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(unlocked ? accentColor : Color.white.opacity(0.3))
                    .shadow(color: unlocked ? accentColor.opacity(0.5) : Color.clear, radius: 6)
            }

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(unlocked ? .white : .white.opacity(0.4))

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: 86)
        .padding(.vertical, 14)
        .liquidGlassCard(cornerRadius: 16)
    }

    private var safetyRideCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "car.side.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .shadow(color: .green.opacity(0.4), radius: 6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("平安微醺 • 安全回家")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("開車不喝酒，隨時為您一鍵呼叫代駕或計程車。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Button("叫車") {
                showingRideAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.green)
            .font(.caption.bold())
            .clipShape(Capsule())
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18)
    }

    private var legalAttributionSection: some View {
        VStack(spacing: 6) {
            Text("地圖與路網技術由 OpenStreetMap contributors、MapLibre 及 Valhalla 提供。")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.5))

            Text("BarHopping v1.0 • 專為台中夜生活打造")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
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
                                    .background(preset.color.opacity(0.18))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(preset.color.opacity(0.3), lineWidth: 1))

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
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .frame(width: 210, height: 210)
                        .shadow(color: .black.opacity(0.2), radius: 10)

                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 135, height: 135)
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
                        .font(.caption.bold())
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
