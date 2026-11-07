import CoreLocation
import SwiftUI
import UIKit

struct OnboardingLocationStep: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var provider = LocationProvider()
    // 僅讀取系統權限；請求仍統一交給 LocationProvider。
    @State private var authorizationReader = CLLocationManager()
    @State private var authorization = CLAuthorizationStatus.notDetermined
    @State private var isRequesting = false
    @State private var problem: String?

    private var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }
    private var isDenied: Bool { authorization == .denied || authorization == .restricted }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("附近酒吧，一眼找到", systemImage: "mappin.and.ellipse")
            Label("抵達店家，完成「買酒」打卡", systemImage: "checkmark.seal")
            Text("只需允許「使用 App 期間」定位。稍後也能到設定開啟。")
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            if isAuthorized {
                Label("定位已開啟，可以直接下一步", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accentOnDark)
            } else if isDenied {
                Text("可到設定開啟定位，也可以先繼續。")
                    .foregroundStyle(AppTheme.textSecondary)
                Button("前往設定", systemImage: "gearshape") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.large)
            } else {
                Button(isRequesting ? "正在確認定位…" : "開啟定位", systemImage: "location.fill") {
                    isRequesting = true
                    problem = nil
                }
                .modifier(OnboardingActionStyle()).tint(AppTheme.accent).controlSize(.large)
                .disabled(isRequesting)
            }
            if let problem, !isAuthorized, !isDenied {
                Text(problem).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appGradientCard(cornerRadius: 28)
        .task(id: isRequesting) {
            guard isRequesting else { return }
            let result = await provider.requestLocation()
            refreshAuthorization()
            if case .failure = result, !isAuthorized, !isDenied {
                problem = "暫時無法取得位置，可以稍後重試或先繼續。"
            }
            isRequesting = false
        }
        .onAppear { refreshAuthorization() }
        .task(id: isRequesting) {
            // 權限允許後即可繼續，不必等單次 GPS 定位完成。
            while isRequesting && !Task.isCancelled {
                refreshAuthorization()
                do { try await Task.sleep(for: .milliseconds(300)) }
                catch { return }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshAuthorization() }
        }
    }

    private func refreshAuthorization() {
        authorization = authorizationReader.authorizationStatus
    }
}
