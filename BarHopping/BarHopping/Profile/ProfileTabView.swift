import SwiftUI
import PhotosUI
import UIKit

/// 「你」個人分頁：個人檔案、通票狀態、跑吧統計、安全代駕與圖資授權
struct ProfileTabView: View {
    @Environment(UserProfileStore.self) private var userProfile
    @State private var showingAvatarPicker = false
    @State private var showingCamera = false
    @State private var showingProfileEditor = false
    @State private var showingPassRedemption = false
    @State private var showingRideAlert = false
    @State private var showingSuccessRedeemAlert = false
    @State private var showingAvatarError = false
    @State private var avatarErrorMessage = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedConnections: ProfileConnectionKind?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 個人檔案與社群資訊
                    profileHeaderCard

                    // MARK: - 跑吧通票
                    barHoppingPassCard

                    // MARK: - 跑吧統計
                    statsOverviewSection

                    // MARK: - 成就徽章
                    badgesSection

                    // MARK: - 安全回家
                    safetyRideCard

                    // MARK: - 資料來源
                    legalAttributionSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.background)
            .navigationTitle("你")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("你")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .sheet(isPresented: $showingAvatarPicker) {
                avatarPickerSheet
            }
            .sheet(isPresented: $showingProfileEditor) {
                ProfileEditorSheet()
            }
            .sheet(item: $selectedConnections) { kind in
                ProfileConnectionsSheet(kind: kind)
            }
            .sheet(isPresented: $showingPassRedemption) {
                passRedemptionSheet
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraCaptureView(onImageCaptured: saveAvatar, onCancel: { showingCamera = false })
                    .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await loadPhoto(item) }
            }
            .alert("無法更新大頭貼", isPresented: $showingAvatarError) {
                Button("好", role: .cancel) { }
            } message: {
                Text(avatarErrorMessage)
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
        .foregroundStyle(AppTheme.textPrimary)
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
    }

    // MARK: - 視圖元件

    private var profileHeaderCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                avatarView(size: 92)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Text(userProfile.nickname)
                            .font(.title2.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(userProfile.levelTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accentOnDark)

                    Text(userProfile.profileHandle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 0)
            }

            Text(userProfile.profileBio.isEmpty ? "還沒有寫下個人介紹。" : userProfile.profileBio)
                .font(.subheadline)
                .lineSpacing(4)
                .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Label(userProfile.profileLocation, systemImage: "mappin.and.ellipse")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textTertiary)

            HStack(spacing: 0) {
                socialCount(value: userProfile.postCount, title: "貼文")
                socialDivider
                Button { selectedConnections = .following } label: {
                    socialCountLabel(value: userProfile.followingCount, title: "追蹤中")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看追蹤中，\(userProfile.followingCount) 人")
                socialDivider
                Button { selectedConnections = .followers } label: {
                    socialCountLabel(value: userProfile.followerCount, title: "粉絲")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看粉絲，\(userProfile.followerCount) 人")
            }
            .padding(.vertical, 3)

            HStack(spacing: 10) {
                Button {
                    showingProfileEditor = true
                } label: {
                    Label("編輯個人檔案", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProfileSecondaryButtonStyle())

                ShareLink(item: "來 BarHopping 看看 \(userProfile.nickname) 的台中夜生活路線！") {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 46, height: 42)
                }
                .buttonStyle(ProfileSecondaryButtonStyle())
                .accessibilityLabel("分享個人檔案")
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: [AppTheme.surface, AppTheme.surface.opacity(0.84), AppTheme.elevated.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .blur(radius: 34)
                        .offset(x: 40, y: -68)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(AppTheme.separator)
        }
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ProfilePhotoLoadError.unavailable
            }
            try userProfile.setCustomAvatar(image)
            showingAvatarPicker = false
            selectedPhoto = nil
        } catch {
            avatarErrorMessage = "讀取照片失敗，請重新選擇一張照片。"
            showingAvatarPicker = false
            showingAvatarError = true
            selectedPhoto = nil
        }
    }

    private func saveAvatar(_ image: UIImage) {
        do {
            try userProfile.setCustomAvatar(image)
            showingCamera = false
            showingAvatarPicker = false
        } catch {
            avatarErrorMessage = "無法儲存照片，請確認裝置空間後再試。"
            showingCamera = false
            showingAvatarError = true
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            avatarErrorMessage = "此裝置目前無法使用相機，請改從相簿選擇照片。"
            showingAvatarError = true
            return
        }
        showingAvatarPicker = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            showingCamera = true
        }
    }

    private var socialDivider: some View {
        Rectangle()
            .fill(AppTheme.separator)
            .frame(width: 1, height: 30)
            .padding(.horizontal, 4)
    }

    private func socialCount(value: Int, title: String) -> some View {
        socialCountLabel(value: value, title: title)
            .frame(maxWidth: .infinity)
    }

    private func socialCountLabel(value: Int, title: String) -> some View {
        VStack(spacing: 3) {
            Text(value.formatted())
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func avatarView(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let avatarData = userProfile.customAvatarData, let image = UIImage(data: avatarData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let preset = userProfile.customAvatarImage {
                    preset
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.25)
                        .foregroundStyle(AppTheme.accentOnDark)
                        .background(AppTheme.accentSoft)
                } else {
                    Image(UserAvatarIcon.assetName)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.accentOnDark, AppTheme.accent, AppTheme.accentOnDark.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
            }
            .accessibilityLabel("大頭貼")

            Button {
                showingAvatarPicker = true
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.accent, in: Circle())
                    .overlay(Circle().strokeBorder(AppTheme.background, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("更換大頭貼")
        }
        .frame(width: size, height: size)
    }

    private var barHoppingPassCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("我的跑吧通票", systemImage: "ticket.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accentOnDark)

                Spacer()

                Text("使用中")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.success.opacity(0.15))
                    .foregroundStyle(AppTheme.success)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(userProfile.passName)
                    .font(.system(size: 17, weight: .bold))

                Text("每間合作酒吧限換 1 杯迎賓特調 • 逢甲商圈專用")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // 進度條
            VStack(spacing: 6) {
                ProgressView(value: Double(userProfile.passRedeemedDrinks), total: Double(userProfile.passTotalDrinks))
                    .tint(AppTheme.accent)

                HStack {
                    Text("已兌換 \(userProfile.passRedeemedDrinks) 杯")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("還可換 \(userProfile.remainingDrinks) 杯")
                        .font(.caption.bold())
                        .foregroundStyle(userProfile.remainingDrinks > 0 ? AppTheme.accentOnDark : AppTheme.textSecondary)
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
                    .background(AppTheme.accent)
                    .foregroundStyle(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var statsOverviewSection: some View {
        HStack(spacing: 12) {
            statItem(title: "已踩點酒吧", value: "\(userProfile.visitedBarsCount) 間", icon: "wineglass.fill", color: AppTheme.accentOnDark)
            statItem(title: "累積步行", value: String(format: "%.1f km", userProfile.totalWalkingKm), icon: "figure.walk", color: AppTheme.info)
            statItem(title: "目前狀態", value: userProfile.soberScore, icon: "heart.fill", color: AppTheme.success)
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
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.surface)
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
                    .fill(unlocked ? AppTheme.accentSoft : AppTheme.elevated)
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(unlocked ? AppTheme.accentOnDark : AppTheme.textTertiary)
            }

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textSecondary)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var safetyRideCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "car.side.fill")
                .font(.title)
                .foregroundStyle(AppTheme.success)
                .frame(width: 44, height: 44)
                .background(AppTheme.success.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("平安微醺 • 安全回家")
                    .font(.subheadline.bold())
                Text("開車不喝酒，隨時為您一鍵呼叫代駕或計程車。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button("叫車") {
                showingRideAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.success)
            .font(.caption.bold())
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var legalAttributionSection: some View {
        VStack(spacing: 6) {
            Text("地圖與路網技術由 OpenStreetMap contributors、MapLibre 及 Valhalla 提供。")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)

            Text("BarHopping v1.0 • 專為台中夜生活打造")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - 彈出表單

    private var avatarPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("更新你的個人頭像")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                            Label("從相簿選擇", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(ProfileAccentButtonStyle())

                        Button(action: openCamera) {
                            Label("拍攝照片", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(ProfileSecondaryButtonStyle())
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                        ForEach(UserProfileStore.presets) { preset in
                            Button {
                                userProfile.selectPreset(preset)
                                showingAvatarPicker = false
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: preset.systemImage)
                                        .font(.system(size: 36))
                                        .foregroundStyle(AppTheme.accentOnDark)
                                        .frame(width: 64, height: 64)
                                        .background(AppTheme.accentSoft)
                                        .clipShape(Circle())

                                    Text(preset.name)
                                        .font(.caption.bold())
                                        .foregroundStyle(AppTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(userProfile.selectedPresetId == preset.id ? AppTheme.accentOnDark : Color.clear, lineWidth: 2)
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
            }
            .background(AppTheme.background)
            .navigationTitle("更換頭像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { showingAvatarPicker = false }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationBackground(AppTheme.background)
        .presentationDetents([.medium, .large])
    }

    private var passRedemptionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("到店出示此畫面")
                            .font(.headline)
                        Text("提供給酒吧店員核銷即可領取專屬特調")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    // QR 碼視覺模擬
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
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
                            .foregroundStyle(AppTheme.accentOnDark)
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
                        .background(userProfile.remainingDrinks > 0 ? AppTheme.success : AppTheme.textTertiary)
                        .foregroundStyle(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(userProfile.remainingDrinks == 0)

                    Spacer()
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("核銷跑吧券")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { showingPassRedemption = false }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationBackground(AppTheme.background)
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ProfileTabView()
        .environment(UserProfileStore())
}
