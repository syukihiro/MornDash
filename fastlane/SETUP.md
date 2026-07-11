# fastlane セットアップ（YouTrainy / WaitOn と同じ）

TestFlight 配信・App Store 提出を App Store Connect API キーで自動化する。

```bash
cd MornDash
bundle install
cp fastlane/.env.example fastlane/.env
# ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_P8 を設定
# （既存の fastlane/.keys/asc_api_key.json からも生成可）

bundle exec fastlane auth_check
bundle exec fastlane beta                  # ビルド → TestFlight
bundle exec fastlane release               # メタデータのみ
bundle exec fastlane release submit:true   # 審査提出まで
```

バージョン / ビルド番号は `MornDash.xcodeproj` の `MARKETING_VERSION` /
`CURRENT_PROJECT_VERSION` を手動更新する（既存 TestFlight より大きい build 番号にすること）。
