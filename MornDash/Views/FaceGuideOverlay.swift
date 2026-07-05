import SwiftUI

/// フォーカス検出セッション用の顔ガイドと検出枠。
struct FaceGuideOverlay: View {
    let boundingBox: CGRect?
    let showsGuide: Bool
    var strokeColor: Color = .white

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                if showsGuide {
                    let guide = Self.guideRect(in: size)
                    var guidePath = Path(roundedRect: guide, cornerRadius: 24, style: .continuous)
                    context.stroke(
                        guidePath,
                        with: .color(strokeColor.opacity(0.5)),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [10, 7])
                    )
                }

                if let box = boundingBox {
                    let rect = Self.mapRect(box, in: size)
                    var facePath = Path(roundedRect: rect, cornerRadius: 12, style: .continuous)
                    context.stroke(facePath, with: .color(strokeColor.opacity(0.95)), lineWidth: 3)
                    context.stroke(
                        facePath,
                        with: .color(strokeColor.opacity(0.25)),
                        lineWidth: 8
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func guideRect(in size: CGSize) -> CGRect {
        let width = size.width * 0.52
        let height = size.height * 0.34
        return CGRect(
            x: (size.width - width) / 2,
            y: size.height * 0.28,
            width: width,
            height: height
        )
    }

    /// Vision 座標（左下原点）→ ミラー済みプレビュー座標（左上原点）
    private static func mapRect(_ box: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: (1 - box.origin.x - box.width) * size.width,
            y: (1 - box.origin.y - box.height) * size.height,
            width: box.width * size.width,
            height: box.height * size.height
        )
    }
}
