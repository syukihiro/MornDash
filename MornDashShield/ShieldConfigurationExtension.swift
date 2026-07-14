import ManagedSettings
import ManagedSettingsUI
import UIKit

/// ブロック中のアプリを開いたときに表示されるシールド画面の見た目を定義する。
/// 呼ばれるたびに「今日開こうとした回数」をカウントし、残りタスクと合わせて表示する。
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(appKey: application.bundleIdentifier ?? "app")
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appKey: application.bundleIdentifier ?? "app")
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(appKey: webDomain.domain ?? "web")
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appKey: webDomain.domain ?? "web")
    }

    /// - Parameter appKey: 試行回数をアプリ単位で集計するためのキー(バンドルID / ドメイン)
    private func makeConfiguration(appKey: String) -> ShieldConfiguration {
        let attempts = SharedStorage.incrementShieldAttemptsToday(for: appKey)
        let snapshot = SharedStorage.loadTaskSnapshot()
        let remaining = snapshot.filter { !$0.isCompletedToday }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: Palette.night,
            icon: Self.lockIcon,
            title: ShieldConfiguration.Label(
                text: NSLocalizedString("shield_title", comment: ""),
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText(remaining: remaining, attempts: attempts),
                color: UIColor.white.withAlphaComponent(0.72)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: NSLocalizedString("shield_close", comment: ""),
                color: Palette.night
            ),
            primaryButtonBackgroundColor: .white
        )
    }

    private func subtitleText(remaining: [SharedStorage.TaskSnapshot], attempts: Int) -> String {
        var lines: [String] = []

        if remaining.isEmpty {
            lines.append(NSLocalizedString("shield_tasks_unknown", comment: ""))
        } else {
            let shown = remaining.prefix(2).map(\.title)
            let separator = NSLocalizedString("shield_task_separator", comment: "")
            var list = shown.joined(separator: separator)
            if remaining.count > shown.count {
                list += NSLocalizedString("shield_task_more_suffix", comment: "")
            }
            lines.append(String(
                format: NSLocalizedString("shield_tasks_remaining", comment: ""),
                remaining.count, list
            ))
        }

        lines.append(String(
            format: NSLocalizedString("shield_attempts_today", comment: ""),
            attempts
        ))

        return lines.joined(separator: "\n")
    }

    // MARK: - Icon

    private enum Palette {
        /// アプリのブロック時テーマ(indigo)に寄せた深い夜色
        static let night = UIColor(red: 0.06, green: 0.05, blue: 0.14, alpha: 1)
        static let indigo = UIColor(red: 0.38, green: 0.36, blue: 0.94, alpha: 1)
        static let dawn = UIColor(red: 1.00, green: 0.62, blue: 0.26, alpha: 1)
    }

    /// 夜(indigo)から朝(orange)へのグラデーション円にロックシンボルを重ねたアイコン。
    private static let lockIcon: UIImage = {
        let size = CGSize(width: 112, height: 112)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)

            // 外周のソフトグロー
            cg.saveGState()
            cg.addEllipse(in: rect)
            cg.clip()
            cg.setFillColor(Palette.indigo.withAlphaComponent(0.30).cgColor)
            cg.fill(rect)
            cg.restoreGState()

            // 本体: 夜→朝焼けのグラデーション円
            let inset = rect.insetBy(dx: 7, dy: 7)
            cg.saveGState()
            cg.addEllipse(in: inset)
            cg.clip()
            let colors = [Palette.indigo.cgColor, Palette.dawn.cgColor]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            ) {
                cg.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: inset.midX, y: inset.minY),
                    end: CGPoint(x: inset.midX, y: inset.maxY),
                    options: []
                )
            }
            cg.restoreGState()

            // ロックシンボル
            let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
            if let symbol = UIImage(systemName: "lock.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let origin = CGPoint(
                    x: (size.width - symbol.size.width) / 2,
                    y: (size.height - symbol.size.height) / 2
                )
                symbol.draw(at: origin)
            }
        }
    }()
}
