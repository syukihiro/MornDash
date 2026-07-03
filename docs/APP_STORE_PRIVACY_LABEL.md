# App Store プライバシーラベル整合ガイド

App Store Connect の「App Privacy」と `PrivacyInfo.xcprivacy` / 実際の SDK 利用を整合させます。

## SDK 一覧とデータ収集

| SDK | 用途 | 収集データ | Privacy Manifest |
|---|---|---|---|
| Firebase Analytics | ファネル計測（オンボーディング、Paywall、完了率） | 使用状況（匿名） | SDK 同梱 |
| RevenueCat | サブスク管理 | 購入情報、デバイス ID | SDK 同梱 |
| Apple Family Controls | アプリブロック | 端末内のみ、外部送信なし | N/A |

## App Store Connect 申告（推奨）

### Data Not Collected（端末内のみ）
- タスク内容、ブロック対象アプリ選択、ストリーク → **収集しない**（UserDefaults / App Group のみ）
- カメラ映像 → **収集しない**（端末上 ML Kit / Vision のみ）

### Data Collected（第三者 SDK 経由）

| カテゴリ | データタイプ | 用途 | 第三者とリンク | トラッキング |
|---|---|---|---|---|
| Analytics | Product Interaction | App Functionality | No | No |
| Purchases | Purchase History | App Functionality | No | No |

### PrivacyInfo.xcprivacy（MornDash 本体）

`MornDash/MornDash/PrivacyInfo.xcprivacy` の設定:

- `NSPrivacyTracking`: **false**
- `NSPrivacyCollectedDataTypes`: 空（SDK 側 manifest に委譲）
- `NSPrivacyAccessedAPITypes`: UserDefaults（CA92.1, 1C8F.1）

Monitor / Report 拡張も同様に UserDefaults のみ。

## 確認手順

1. Xcode → MornDash target → Build Phases → 各 SDK の `PrivacyInfo.xcprivacy` が Embed されているか確認
2. App Store Connect → App Privacy → 「Get Started」
3. 上記表に従ってデータタイプを入力
4. Privacy Policy URL: `https://nostalgic-calendula-e60.notion.site/MornDash-Privacy-Policy-390484266af4816e9185eeddb06fd2e0`
5. fastlane metadata の `privacy_url.txt` と一致確認

## 注意

- Screen Time / Family Controls データは Apple の API 経由で端末内処理。App Privacy では「収集しない」
- カメラは `NSCameraUsageDescription` のみ。映像は端末外に出ない
- `NSPhotoLibraryAddUsageDescription` は削除済み（共有は UIActivityViewController のみ）

## 参考ファイル

- `MornDash/MornDash/PrivacyInfo.xcprivacy`
- `MornDash/MornDashMonitor/PrivacyInfo.xcprivacy`
- `MornDash/MornDashReport/PrivacyInfo.xcprivacy`
- `MornDash/MornDash/Models/AnalyticsService.swift`
- `MornDash/MornDash/Models/SubscriptionManager.swift`
- `RevenueCatConfig.privacyPolicyURL`
