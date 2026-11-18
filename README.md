# nercone-infra/openssl

[OpenSSL の公式リリース](https://github.com/openssl/openssl/releases)を GitHub Actions でビルドし、[GitHub Releases](https://github.com/nercone-infra/openssl/releases)・コンテナイメージ・GitHub Action として配布するリポジトリです。nercone-infra の各コンポーネントは、ここでビルドした OpenSSL をリンクします。

このリポジトリに OpenSSL のソースコードは含まれていません。新しい安定版がないかを6時間ごとに確認し、各プラットフォーム向けにビルドします。

## 対応プラットフォーム

- Linux (x86_64, AArch64)
- macOS (x86_64, AArch64)
- Windows (x86_64, AArch64)

## リリースの内容

- アーカイブ: `openssl-<version>-<platform>-<arch>`。形式は `.zip`、`.tar.gz`、`.tar.xz`、`.7z`。
- チェックサム: 全アセット分の `SHA256SUMS`、`SHA384SUMS`、`SHA512SUMS`。

## 使い方

1. [Releases ページ](https://github.com/nercone-infra/openssl/releases)から、プラットフォームとアーキテクチャに合ったアーカイブをダウンロードします。
2. 同じリリースの `SHA256SUMS`、`SHA384SUMS`、`SHA512SUMS` のいずれかで照合します(例: `sha256sum -c SHA256SUMS --ignore-missing`)。
3. 展開し、`bin/` にある `openssl` を使います。

### コンテナイメージ(Linux)

`ghcr.io/nercone-infra/openssl:<version>` は、あるリリースの Linux ビルド(`linux/amd64`、`linux/arm64`)を `/opt/openssl` に格納したイメージです。ファイルを保持するだけなので、ビルドステージとして使い、ダイジェストで固定してください。

```dockerfile
FROM ghcr.io/nercone-infra/openssl:4.1.0@sha256:<digest> AS openssl
FROM debian:trixie-slim AS build
COPY --from=openssl /opt/openssl /opt/openssl
```

署名の確認: イメージは `image.yml` ワークフローが cosign(keyless)で署名しています。

```sh
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github\.com/nercone-infra/openssl/\.github/workflows/image\.yml@' \
  ghcr.io/nercone-infra/openssl@<digest>
```

アーカイブとの違い:
- `/opt/openssl/lib` は常に存在します(x86_64 では `lib64` へのリンク)。
- pkg-config ファイル(`lib/pkgconfig/*.pc`)のプレフィックスは `/opt/openssl` です。`PKG_CONFIG_PATH=/opt/openssl/lib/pkgconfig` をそのまま使えます。
- アーカイブは、イメージに含める前にリリースの `SHA384SUMS` と照合されます([`image/prepare.sh`](image/prepare.sh))。

公開の運用:
- 各バージョンのイメージは一度だけ公開します。再公開するには、ワークフローの `replace` 入力を指定します。
- 既存のリリースのイメージは、「Publish OpenSSL image」ワークフローを手動で実行して公開できます。
- 他のリポジトリのビルドから pull できるよう、パッケージは公開(public)にしておく必要があります。

### GitHub Actions

[`setup/action.yml`](setup/action.yml) は Linux ビルドをランナーにインストールします(`SHA384SUMS` と照合)。`bin/` を `PATH` の先頭に、ライブラリを `LD_LIBRARY_PATH` に追加します。

```yaml
- id: openssl
  uses: nercone-infra/openssl/setup@main
  with:
    version: 4.1.0
- run: cargo build
  env:
    OPENSSL_DIR: ${{ steps.openssl.outputs.prefix }}
    OPENSSL_LIB_DIR: ${{ steps.openssl.outputs.libdir }}
```

## 仕組み

ビルドワークフロー([`.github/workflows/build.yml`](.github/workflows/build.yml))の流れ:

1. スケジュール(6時間ごと)または手動実行で起動します。
2. ビルドするバージョンを決めます。
   - 自動: `openssl/openssl` の安定版リリースのうち最新の10件で、このリポジトリに対応するリリースがまだないもの。
   - 手動: 指定したバージョン。
3. ソースの tarball を取得し、OpenSSL の PGP 署名を検証します(署名者は固定したフィンガープリントに限る)。
4. OpenSSL 自身のビルドシステム(`Configure` + `make`/`nmake`、`no-tests`)で、全プラットフォーム/アーキテクチャ向けにビルドします。
5. `openssl` が実行でき、バージョンを出力することを確認します。
6. インストール結果を `.zip`、`.tar.gz`、`.tar.xz`、`.7z` にまとめます。
7. 全アーカイブとチェックサムを添付し、`openssl-<version>` タグの GitHub Release を公開します。複数のバージョンは古い順に公開するため、最も新しいバージョンが Latest になります。
8. Linux ビルドをコンテナイメージとして公開します([`.github/workflows/image.yml`](.github/workflows/image.yml))。

## 免責事項

バイナリは、改変していない OpenSSL のソースリリースから、ワークフローファイルに記載したオプションでそのままビルドしています。
いかなる保証もありません。特にセキュリティが重要な用途では、利用前にバイナリが用途に適しているかを確認してください。
