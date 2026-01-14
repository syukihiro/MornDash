# MornDash iOSアプリ設計書 (Swift/SwiftUI)

## 1. アーキテクチャ概要
- **Architecture**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Language**: Swift 5.0+
- **Minimum iOS Version**: iOS 16.0+ (Screen Time API要件のため)

## 2. 主要技術スタック
このアプリの核となる機能は Apple の **Screen Time API** を使用して実装します。

| 機能 | 使用フレームワーク/クラス | 役割 |
|---|---|---|
| **アプリ制限・ブロック** | `ManagedSettings` | 特定のアプリやカテゴリに対して「シールド（使用不可）」を適用する。 |
| **アプリ選択** | `FamilyControls` | ユーザーにブロック対象のアプリを選択させるピッカーと権限管理。 |
| **アクティビティ監視** | `DeviceActivity` | アプリの使用状況監視やスケジュール実行（補助的に使用）。 |
| **アラーム・通知** | `UserNotifications` / `AVFoundation` | アラーム音の再生とローカル通知。 |
| **データ永続化** | `UserDefaults` / `AppStorage` | アラーム設定時刻や選択されたアプリトークンの保存。 |

---

## 3. アプリケーションフロー詳細

### 3.1 アラーム発火〜ブロック開始フロー
1.  **アラーム設定**: ユーザーが時刻を設定。`UserNotifications`でローカル通知を予約。
2.  **アラーム発火**: 指定時刻に通知/音が鳴る。
3.  **ユーザーアクション**: ユーザーが通知をタップ、またはアプリを開いて「停止」ボタンを押す。
4.  **ブロック開始 (Action)**:
    - アラーム停止イベントをトリガーに、`ManagedSettingsStore` に制限を適用。
    - 選択されたアプリ群 (`ApplicationToken`, `WebDomainToken`) にシールドがかかる。
    - 3分間のカウントダウンタイマーを開始。
5.  **ブロック中**: 対象アプリを開こうとすると、システム標準のシールド画面（またはカスタマイズしたシールド）が表示される。
6.  **ブロック解除**: 3分経過後、`ManagedSettingsStore.clearAllSettings()` を呼び出し、制限を解除する。

---

## 4. データモデル設計

### `AlarmSettings`
アラームの設定状態を管理します。
```swift
struct AlarmSettings: Codable {
    var isEnabled: Bool
    var time: Date
    var selectedWeekdays: Set<Int> // 1=Sun, 2=Mon...
}
```

### `BlockSelectionModel`
ユーザーが選択したブロック対象を管理します。`FamilyControls` のデータを保存します。
```swift
// NOTE: FamilyActivitySelection自体はCodableであり、そのまま保存可能
import FamilyControls

class BlockSelectionModel: ObservableObject {
    @Published var activitySelection: FamilyActivitySelection
}
```

---

## 5. 主要コンポーネント設計

### 5.1 View Layer (SwiftUI)
- **`HomeView`**: メイン画面。アラーム設定、現在のステータス表示、ブロック対象設定への遷移。
- **`AlarmSetupView`**: 時刻設定ピッカー。
- **`BlockAppSelectionView`**: `FamilyActivityPicker` を表示し、ブロックするアプリを選択させる。
- **`ActiveBlockView`**: （オプション）現在ブロック中であることを示すアプリ内画面。カウントダウン表示。

### 5.2 ViewModel Layer
- **`HomeViewModel`**: アラームのセット、通知権限の確認、Screen Time権限の確認を統括。
- **`BlockManager`**: `ManagedSettingsStore` を操作し、実際のブロック適用・解除ロジックを持つ。

### 5.3 Extension (DeviceActivityMonitor)
- バックグラウンドでの動作を保証するために、Device Activity Extensionターゲットが必要になる可能性がありますが、今回の「アラーム停止時（アプリ起動時）に即時ブロック」の要件であれば、メインアプリ内のロジックで完結できる見込みです。ただし、アプリがキルされている状態からの動作を考慮すると、Extensionの利用も視野に入れます。

---

## 6. 技術的制約と対策 (Risk Management)
- **権限**: `FamilyControls` の認可にはユーザーの明示的な許可が必要です。「スクリーンタイムへのアクセス」を許可してもらうためのオンボーディングフローが重要です。
- **Sandbox**: 開発中のビルド（Debug）ではScreen Time APIが正しく動作しない場合があります。TestFlightまたは実機へのインストールで検証する必要があります。
- **シールドのカスタマイズ**: `ShieldConfigurationDataSource` を実装したExtensionを作成することで、ブロック画面（シールド）の文言やアイコンを「MornDash」仕様にカスタマイズ可能です（推奨）。

## 7. ディレクトリ構成案
```
MornDash/
├── App/
│   ├── MornDashApp.swift (Entry Point)
│   └── AppDelegate.swift (Notification Handling)
├── Views/
│   ├── HomeView.swift
│   ├── Components/
│   └── Settings/
├── ViewModels/
│   ├── AlarmViewModel.swift
│   └── BlockManager.swift
├── Models/
│   ├── AlarmSettings.swift
│   └── AppError.swift
├── Services/
│   ├── NotificationManager.swift
│   └── ScreenTimeService.swift
├── Resources/
│   └── Assets.xcassets
└── Extensions/ (Targets)
    └── ShieldConfiguration/ (ブロック画面のカスタマイズ)
```
