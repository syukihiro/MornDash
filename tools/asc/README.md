# App Store Connect メタデータ管理ツール

MornDash のアプリ情報・メタデータを App Store Connect API 経由で取得/更新する。
ファイル配置は fastlane deliver と互換なので、将来 fastlane に移行してもそのまま使える。

## なぜ fastlane ではなくこれか

この Mac の rbenv Ruby(3.3.6)は OpenSSL 連携が壊れており、Ruby の HTTPS 通信が
全滅している(fastlane / spaceship も内部で失敗する)。本ツールは **JWT 生成と JSON 処理だけ
Ruby**、**HTTP 通信は curl** に委譲することでこれを回避している。
Ruby 環境を修復できたら `fastlane/Deliverfile`・`Fastfile` 側に移行してよい。

## 前提

`fastlane/.keys/asc_api_key.json`(App Store Connect API キー)が存在すること。
無い場合は `fastlane/.keys/README.md` の手順で生成する。

## 使い方

すべて `MornDash/`(このプロジェクトのルート)から実行する。

```sh
# アプリ/編集対象バージョンの状態とロケール一覧を表示
ruby tools/asc/asc.rb status

# App Store Connect の現在値を fastlane/metadata/<locale>/*.txt に取得
ruby tools/asc/asc.rb pull

# ローカルの *.txt を App Store Connect へ反映(差分のあるフィールドのみ PATCH)
ruby tools/asc/asc.rb push
```

## 管理できる項目(ロケールごと)

| ファイル | 対応する項目 |
|---|---|
| `name.txt` | アプリ名(30字) |
| `subtitle.txt` | サブタイトル(30字) |
| `description.txt` | 説明文(4000字) |
| `keywords.txt` | キーワード(カンマ区切り・合計100字) |
| `promotional_text.txt` | プロモーションテキスト(170字) |
| `marketing_url.txt` | マーケティングURL |
| `support_url.txt` | サポートURL |
| `privacy_url.txt` | プライバシーポリシーURL |
| `release_notes.txt` | このバージョンの新機能 |

## 運用フロー

1. `pull` で現在値を取得
2. `fastlane/metadata/<locale>/*.txt` を編集
3. `git diff` で変更を確認
4. `push` で反映(**審査提出はしない**。App Store Connect 上で下書きが更新されるだけ)
5. 審査提出は App Store Connect の画面から手動で行う

## 注意

- `push` は編集可能なバージョン(例: `PREPARE_FOR_SUBMISSION`)にのみ反映される。
  審査中/公開済みのみの状態では、先に App Store Connect で新バージョンを作成する。
- `name` / `subtitle` / `privacy_url` はアプリ情報(appInfo)側、それ以外はバージョン側に
  保存される(API の仕様)。本ツールは自動で振り分ける。
