# MornDash UI/UX デザインガイドライン

## 1. カラーパレット (Color Palette)

アプリ全体を通して**「完全な黒 (#000000)」**を基調とし、没入感とストイックな雰囲気を演出します。

### Base Colors
- **Main Background**: `#000000` (Pure Black)
  - 一般的なダークモードのグレー (`#1C1C1E`) ではなく、有機ELディスプレイで完全に消灯する「真の黒」を使用。
- **Secondary Background**: `#1A1A1A` (Dark Gray)
  - カードやリストアイテムなど、背景と区別が必要な要素に使用。

### Text Colors
- **Primary Text**: `#FFFFFF` (White)
  - 最も重要な情報。
- **Secondary Text**: `#8E8E93` (Light Gray)
  - 補足説明やラベル。

### Accent Colors (TBD)
「覚悟」「警告」をイメージさせるアクセントカラーを1色定義します。
- **Candidate A (Alert Red)**: `#FF3B30` - 警告、禁止、緊急性
- **Candidate B (Neon Blue/Cyan)**: `#0A84FF` - クール、デジタル、サイバーパンク的

## 2. タイポグラフィ (Typography)
あえてシステムフォント(San Francisco)を使用しつつ、ウェイト（太さ）で強弱をつけます。

- **Headings**: San Francisco Rounded / Bold or Heavy
  - 力強さを表現。
- **Body**: San Francisco Default / Regular
  - 可読性を重視。

## 3. UIコンポーネント方針

### 3.1 アトモスフィア
- **Glassmorphism (Frosted Glass)**: なし、または最小限。
  - 今回は「黒」の深みを重視するため、透過やすりガラス効果よりも、**ソリッドでマットな質感**を優先します。
- **Borders**: 細い（0.5pt - 1pt）グレーのボーダーで区切りを表現。

### 3.2 インタラクション
- アラーム停止ボタンなどの重要アクションは、単純なタップではなく「長押し」や「スワイプ」など、**能動的な意思**を必要とするジェスチャーを採用することを検討（誤操作防止のため）。

## 4. ダークモード対応
- iOSの設定に関わらず、**常にダークモード（黒背景）**で動作するようにアプリ全体を強制します (`preferredColorScheme(.dark)` modifierを使用)。

---

## 5. 画面イメージ (Wireframe Description)

### Home Screen
- 背景：真っ黒 (`#000000`)
- 中央：巨大なデジタル時計（白文字）
- 下部：アラーム設定状態を示すインジケーター

### Blocking Screen (Shield)
- 全画面真っ黒。
- 中央に「MornDash」のロゴ、または「残り 02:59」のカウントダウンのみが白く光る。
- 一切の装飾を排除し、スマホを触る意欲を削ぐデザイン。
