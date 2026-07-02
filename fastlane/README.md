fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios fetch_metadata

```sh
[bundle exec] fastlane ios fetch_metadata
```

App Store Connect の既存メタデータを fastlane/metadata に取得する

初回セットアップ後に最初に実行。CLI の `fastlane deliver download_metadata` と同等。

### ios push_metadata

```sh
[bundle exec] fastlane ios push_metadata
```

ローカルの fastlane/metadata を App Store Connect へ反映する

審査提出はしない(下書き保存のみ)。反映前に内容を git diff で必ず確認すること。

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
