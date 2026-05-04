import FamilyControls
import ManagedSettings
import SwiftUI

struct TotalActivityView: View {
    let configuration: TotalActivityConfiguration

    private let rowLimit = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(TotalActivityReport.formatted(configuration.totalDuration))
                .font(.system(size: 34, weight: .thin, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if configuration.apps.isEmpty {
                Text(verbatim: "—")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.3))
            } else {
                VStack(spacing: 8) {
                    ForEach(configuration.apps.prefix(rowLimit)) { app in
                        row(for: app)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(for app: AppUsage) -> some View {
        HStack(spacing: 10) {
            Group {
                if let token = app.token {
                    Label(token)
                        .labelStyle(.iconOnly)
                } else {
                    Image(systemName: "app")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .frame(width: 22, height: 22)

            Text(app.name)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            Text(TotalActivityReport.formatted(app.duration))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .monospacedDigit()
        }
    }
}

#Preview {
    TotalActivityView(
        configuration: TotalActivityConfiguration(
            totalDuration: 3 * 3600 + 42 * 60,
            apps: []
        )
    )
    .padding()
    .background(Color.black)
}
