# App Store Connect API キー置き場

このディレクトリには機密情報を置きます。`.gitignore` により
`*.p8` / `*.json` はコミットされません(この README と生成スクリプトのみ追跡)。

## セットアップ手順

1. App Store Connect でチーム用の API キーを発行し、`AuthKey_XXXX.p8` をダウンロード。
   - [App Store Connect](https://appstoreconnect.apple.com/) →「ユーザーとアクセス」
   - 「インテグレーション」タブ →「App Store Connect API」→「チームキー」
   - `+` でキーを生成(アクセス権は **App Manager** 以上)
   - **.p8 は一度しかダウンロードできない**。Key ID と Issuer ID も控える。

2. このディレクトリに `.p8` を置くか、下記でパス指定して JSON を生成:

   ```sh
   ruby fastlane/.keys/generate_key_json.rb <KeyID> <IssuerID> <path/to/AuthKey_XXXX.p8>
   ```

   → `fastlane/.keys/asc_api_key.json` ができれば認証完了。

3. 動作確認(既存メタデータの取得):

   ```sh
   fastlane fetch_metadata
   ```
