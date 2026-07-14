import ManagedSettings
import ManagedSettingsUI
import UIKit

/// ブロック中のアプリを開いたときに表示されるシールド画面の見た目を定義する。
/// 呼ばれるたびに「今日開こうとした回数」をカウントして表示する。
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

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: Palette.night,
            icon: Self.lockIcon,
            title: ShieldConfiguration.Label(
                text: NSLocalizedString("shield_title", comment: ""),
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: String(
                    format: NSLocalizedString("shield_attempts_today", comment: ""),
                    attempts
                ),
                color: UIColor.white.withAlphaComponent(0.72)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: NSLocalizedString("shield_close", comment: ""),
                color: Palette.night
            ),
            primaryButtonBackgroundColor: .white
        )
    }

    // MARK: - Icon

    private enum Palette {
        /// アプリのブロック時テーマ(indigo)に寄せた深い夜色
        static let night = UIColor(red: 0.06, green: 0.05, blue: 0.14, alpha: 1)
    }

    /// 白の南京錠シンボルのみのシンプルなアイコン。
    private static let lockIcon: UIImage = {
        let size = CGSize(width: 112, height: 112)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let config = UIImage.SymbolConfiguration(pointSize: 76, weight: .semibold)
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
