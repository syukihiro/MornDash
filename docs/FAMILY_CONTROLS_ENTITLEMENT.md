# Family Controls Distribution エンタイトルメント

MornDash は Screen Time / Family Controls API を使用するため、**Family Controls (Distribution)** エンタイトルメントの Apple 承認が必要です。

## 現状（コード側）

以下3ターゲットすべてに `com.apple.developer.family-controls` が設定済み:

| ターゲット | entitlements |
|---|---|
| MornDash | `MornDash/MornDash.entitlements` |
| MornDashMonitor | `MornDashMonitor/MornDashMonitor.entitlements` |
| MornDashReport | `MornDashReport/MornDashReport.entitlements` |

App Group: `group.danchi.MornDash`

## 確認手順

1. [Apple Developer](https://developer.apple.com/account/resources/identifiers/list) にログイン
2. Identifiers → `danchi.MornDash` を開く
3. **Family Controls (Distribution)** が Enabled か確認
4. 未申請の場合: [Request Family Controls Entitlement](https://developer.apple.com/contact/request/family-controls-distribution/) から申請

## 申請時に記載する内容（例）

- **App name:** MornDash
- **Bundle ID:** danchi.MornDash
- **Purpose:** ユーザーが設定した朝の時間帯に、ユーザー自身が選択したアプリを Screen Time シールドでブロックし、朝ルーティン（タスク）完了まで使用不可にする
- **Data handling:** ブロック対象アプリの選択は端末内のみ。外部サーバーに Screen Time データを送信しない
- **Target audience:** 一般ユーザー（13+）

## 承認後

1. Provisioning Profile を再生成（Automatic Signing なら Xcode が自動更新）
2. TestFlight ビルドで Monitor 拡張がキル状態でもブロック発火することを確認
3. App Store 審査に提出

## 参考

- [Apple Documentation: Family Controls](https://developer.apple.com/documentation/familycontrols)
- 審査メモ: `fastlane/metadata/review_information/notes.txt`
