# MornDash 世界配信向け 言語設定・ローカライズ戦略（Swift / iOS）

## 目的
- Swift製 iOSアプリ **MornDash** を世界に配信する
- 実装・運用コストを最小化しつつ、100万DLに耐える言語設計を行う
- 朝の集中体験を壊さないシンプルな多言語対応を実現する

---

## 結論（最初にやることは3つだけ）
1. **アプリ内言語は英語＋日本語から開始**
2. **iOS標準のローカライズ機構を使用**
3. **App Store文言とアプリ内翻訳は分離して考える**

---

## ① 言語戦略（プロダクト方針）

### 初期対応言語
- 🇺🇸 英語（デフォルト）
- 🇯🇵 日本語

### この構成にする理由
- 世界配信は英語だけで成立する
- 日本語は初期ユーザー・改善拠点として重要
- 翻訳コスト・実装コストを最小化できる
- 朝の集中アプリは母語体験の価値が高い

※ 初期から多言語（5〜10言語）対応は行わない

---

## ② 実装方針（Swift / iOS）

### 使用する仕組み
- Xcode標準の **String Catalog**（Xcode 15+）
  - または `Localizable.strings`
- **NSLocalizedString を全画面で徹底**
- 文字列のハードコードは禁止

### Swift 実装例
```swift
Text(NSLocalizedString("lock_title", comment: "Screen lock title"))
```

### ファイル構造例
```
Localization/
 ├─ en.lproj/
 │   └─ Localizable.strings
 └─ ja.lproj/
     └─ Localizable.strings
```

### App Store 側の多言語対応（別枠）
必須対応
- アプリ名
- サブタイトル
- 説明文
- スクリーンショット内テキスト

初期言語
- 英語
日本語
余力が出たら追加
韓国語
中国語（簡体）
スペイン語

※ アプリ内翻訳より App Store文言の翻訳を優先