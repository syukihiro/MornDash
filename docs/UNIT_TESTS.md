# ユニットテスト

`MornDashTests/` にコアロジックのテストを配置しています。

## テストファイル

| ファイル | 対象 |
|---|---|
| `BlockWindowLogicTests.swift` | ブロック時間判定（開始〜23:59） |
| `TaskStoreTests.swift` | タスク完了判定、最低1タスクガード |

## Xcode でテストターゲットを追加（初回のみ）

1. Xcode → File → New → Target
2. **Unit Testing Bundle** を選択
3. Product Name: `MornDashTests`
4. Target to be Tested: `MornDash`
5. 生成されたテストファイルを削除し、既存の `MornDashTests/` フォルダをターゲットに追加

## 実行

```bash
cd MornDash
xcodebuild test \
  -project MornDash.xcodeproj \
  -scheme MornDash \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

または Xcode → Product → Test (⌘U)

## 追加推奨テスト

- [ ] `StreakStore` ストリーク計算
- [ ] `RevenueCatConfig` 無料枠ゲート
- [ ] `HomeViewModel.appState` 状態遷移（give up / 完了 / 空タスク）
