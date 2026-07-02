import SwiftUI

/// SNS 共有用のストリークカード。
/// 画面表示ではなく `ImageRenderer` で画像化する前提のため、
/// カラースキームに依存せず常にダークのブランドデザインで描画する。
struct StreakShareCardView: View {
    let streak: Int
    let date: Date

    static let cardSize = CGSize(width: 340, height: 425)

    private let accentGold = Color(red: 1.0, green: 0.88, blue: 0.55)
    private let flameOrange = Color(red: 1.0, green: 0.58, blue: 0.20)
    private let backgroundBase = Color(red: 0.05, green: 0.04, blue: 0.03)

    var body: some View {
        ZStack {
            backgroundBase

            RadialGradient(
                colors: [flameOrange.opacity(0.28), flameOrange.opacity(0.06), .clear],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 300
            )

            VStack(spacing: 0) {
                Text("share_card_eyebrow")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [flameOrange, accentGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 44)

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentGold, flameOrange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: flameOrange.opacity(0.55), radius: 18)

                Text("\(streak)")
                    .font(.system(size: 104, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, accentGold.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: flameOrange.opacity(0.25), radius: 16)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                Text("main_completed_streak_unit")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .tracking(5)
                    .foregroundColor(.white.opacity(0.72))
                    .padding(.top, 6)

                Text(date.formatted(date: .long, time: .omitted))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.42))
                    .padding(.top, 14)

                Spacer()

                VStack(spacing: 14) {
                    Rectangle()
                        .fill(.white.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 44)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(flameOrange)
                        Text(verbatim: "MornDash")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(.bottom, 26)
            }
        }
        .frame(width: Self.cardSize.width, height: Self.cardSize.height)
    }
}

enum StreakShareCard {
    /// カードを共有用の `UIImage` に描画する。3x スケールで約 1020×1275px。
    /// `Image`（Transferable）で共有するとファイル扱いになり共有シートに
    /// 「画像を保存」が出ないため、UIImage + UIActivityViewController で共有する。
    @MainActor
    static func render(streak: Int, date: Date = Date()) -> UIImage? {
        let renderer = ImageRenderer(content: StreakShareCardView(streak: streak, date: date))
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// ストリークカードを共有シートで送るボタン。
struct StreakShareButton: View {
    let streak: Int
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    @State private var renderedImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        Button {
            showShareSheet = true
        } label: {
            label.opacity(renderedImage == nil ? 0.35 : 1)
        }
        .disabled(renderedImage == nil)
        .onAppear {
            if renderedImage == nil {
                renderedImage = StreakShareCard.render(streak: streak)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let renderedImage {
                ShareActivityView(image: renderedImage)
                    .ignoresSafeArea()
            }
        }
    }

    private var label: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 13, weight: .semibold))
            Text("share_streak_button")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: colorScheme == .dark ? 0.88 : 0.92))
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(
                    colorScheme == .dark
                        ? MornDashColors.fieldBackground(colorScheme)
                        : accentTheme.idleColor.opacity(0.12)
                )
                .overlay(
                    Capsule().strokeBorder(
                        accentTheme.idleColor.opacity(colorScheme == .dark ? 0.22 : 0.45),
                        lineWidth: 1
                    )
                )
        }
    }
}

/// UIImage を共有するための UIActivityViewController ラッパー。
/// 「画像を保存」「コピー」など画像向けアクションを共有シートに出すために使う。
private struct ShareActivityView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("Share card") {
    StreakShareCardView(streak: 14, date: .now)
}
