import SwiftUI

struct FreeRunDrinkTicketSheet: View {
    let store: FreeRunStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    var body: some View {
        ScrollView {
            if let ticket = store.scanTicket, let feedback = store.drinkFeedback {
                VStack(spacing: 20) {
                    Text(store.isDemoTicket ? "龍蛇酒雜・示範票" : "龍蛇酒雜酒票")
                        .font(.title2.bold())
                    Text(ticket.option.name).font(.headline)
                    Text("剩餘 \(ticket.remainingCups) 杯")
                        .font(.title3.bold()).monospacedDigit().contentTransition(.numericText())
                    PassQRCodeView(payload: DrinkPassArtwork.qrCodePayload(for: ticket))
                        .overlay(alignment: .top) {
                            if feedback.phase == .scanning, !reduceMotion, !appReduceMotion {
                                Rectangle().fill(AppTheme.accent)
                                    .frame(width: 154, height: 3)
                                    .offset(y: 18 + (sin(feedback.elapsed * .pi * 2) + 1) * 77)
                                    .accessibilityHidden(true)
                            }
                        }
                    Text("票號：\(ticket.ticketNumber)")
                        .font(.caption.monospaced()).textSelection(.enabled)
                    if feedback.phase == .scanning {
                        Text("掃描中…")
                            .font(.headline)
                        ProgressView(value: min(feedback.elapsed / FreeRunDemoScript.scanSeconds, 1))
                            .accessibilityLabel("示範掃描進度")
                    } else {
                        Label(store.didRedeemCup ? "掃描成功" : "這張酒票已用完",
                              systemImage: store.didRedeemCup ? "checkmark.circle.fill" : "ticket")
                            .font(.title.bold()).foregroundStyle(AppTheme.accentOnDark)
                            .accessibilityAddTraits(.updatesFrequently)
                        Text(store.didRedeemCup ? "已兌換 1 杯" : "未扣杯，仍可繼續路跑")
                        Button("完成", action: store.completeDrinkFeedback)
                            .buttonStyle(FreeRunActionButtonStyle(prominent: true))
                    }
                    Text("示範自動掃描，QR Code 內容：\(DrinkPassArtwork.qrCodePayload(for: ticket))")
                        .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
        .overlay {
            if let feedback = store.drinkFeedback {
                FreeRunCelebrationView(elapsed: feedback.elapsed)
                    .id(feedback.id)
            }
        }
        .sensoryFeedback(.success, trigger: store.didRedeemCup)
        .onChange(of: store.didRedeemCup) { _, redeemed in
            if redeemed { AccessibilityNotification.Announcement("掃描成功，已兌換 1 杯").post() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
    }
}
