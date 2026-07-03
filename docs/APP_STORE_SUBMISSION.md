# App Store 提出ランブック

P0 バグ修正・QA 完了後にこの手順で提出します。

## 前提チェック

- [ ] `docs/QA_CHECKLIST.md` の P0 シナリオすべて Pass
- [ ] `docs/FAMILY_CONTROLS_ENTITLEMENT.md` の Distribution 承認済み
- [ ] `docs/APP_STORE_PRIVACY_LABEL.md` に従い App Privacy 入力済み
- [ ] スクリーンショット準備済み（`docs/APP_STORE_SCREENSHOTS.md`）

## Step 1: メタデータ反映

```bash
cd MornDash
bundle exec fastlane deliver --skip_binary_upload true --skip_screenshots true
```

反映される項目:
- privacy_url, primary_category, release_notes, review_information

## Step 2: Archive & Upload

1. Xcode → Product → Archive（Release / Any iOS Device）
2. Organizer → Distribute App → App Store Connect → Upload
3. または `fastlane` で `upload_to_app_store`（要 API Key 設定）

## Step 3: App Store Connect 設定

1. **App Information**
   - Privacy Policy URL 確認
   - Category: Productivity

2. **Pricing and Availability**
   - 価格: Free（IAP: Pro サブスク）

3. **App Privacy**
   - `docs/APP_STORE_PRIVACY_LABEL.md` 参照

4. **Screenshots**
   - 6.7" Display に 5〜8 枚アップロード

5. **Version Information**
   - What's New: `fastlane/metadata/en-US/release_notes.txt` の内容
   - 日本語: `fastlane/metadata/ja/release_notes.txt`

6. **App Review Information**
   - Notes: `fastlane/metadata/review_information/notes.txt`
   - Contact: email_address.txt, first_name.txt

7. **In-App Purchases**
   - pro_weekly_dash / pro_monthly_dash / pro_yearly_dash が Approved

## Step 4: 審査提出

1. 「Add for Review」をクリック
2. Export Compliance: No（ITSAppUsesNonExemptEncryption = false）
3. Content Rights / Advertising Identifier: No（Firebase Analytics は IDFA 不使用）

## Step 5: 審査中

- 審査期間: 通常 24〜48 時間（Family Controls アプリは長めの可能性）
- Rejected 時: Resolution Center の指摘に対応 → 修正 → 再提出

## Step 6: リリース後

- TestFlight 内部テスターに本番ビルド通知
- Analytics ダッシュボードで以下を監視:
  - onboarding_completed
  - routine_completed
  - give_up
  - paywall_purchase_success

## トラブルシューティング

| 問題 | 対処 |
|---|---|
| Family Controls entitlement missing | Distribution 承認を確認、Provisioning Profile 再生成 |
| Screen Time デモ不可 | review_information/notes.txt の手順を更新 |
| IAP 審査 Reject | Sandbox テスト手順と Terms of Service URL を確認 |
| Privacy 不一致 | SDK privacy manifest と App Privacy フォームを再確認 |
