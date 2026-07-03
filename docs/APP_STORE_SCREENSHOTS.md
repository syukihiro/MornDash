# App Store スクリーンショットガイド

fastlane は `skip_screenshots(true)` のため、スクリーンショットは App Store Connect に手動アップロードします。

## 必須サイズ

| デバイス | 解像度 | 必須 |
|---|---|---|
| iPhone 6.7" (15 Pro Max 等) | 1290 × 2796 | Yes |
| iPhone 6.5" (11 Pro Max 等) | 1284 × 2778 | Yes (6.7" が無い場合) |

## 推奨キャプチャ（5〜8枚）

1. **BlockingView** — 朝のブロック画面（タスクリスト表示）
2. **CompletedHomeView** — タスク完了後のホーム（ストリーク表示）
3. **TasksTabView** — タスク編集画面
4. **StatsTabView** — ストリーク・統計画面
5. **OnboardingView** — 仕組み説明ステップ
6. **CustomPaywallView** — Pro 機能紹介
7. **BlockingView + Workout** — AI ワークアウト（差別化要素）
8. **SettingsView** — 設定画面

## 撮影手順

1. 実機またはシミュレータ（iPhone 15 Pro Max 推奨）でアプリを起動
2. Xcode → Debug → View Debugging → Capture View Hierarchy ではなく、実機のスクリーンショット（Side Button + Volume Up）を使用
3. シミュレータ: File → Save Screen または `Cmd+S`
4. ダークモード固定のため、追加の Light/Dark 対応は不要

## App Store Connect でのアップロード

1. App Store Connect → MornDash → App Store → [バージョン] → Screenshots
2. 6.7" Display に上記画像をドラッグ&ドロップ
3. 各ロケール（en-US, ja）で同じ画像セットを使用可能（テキストオーバーレイ不要）

## 注意

- Screen Time シールド画面そのものは Apple UI のためキャプチャ不可。BlockingView で代替
- 個人情報（メール、電話番号）が写らないよう注意
