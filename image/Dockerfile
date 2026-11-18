# 1つのリリースの Linux ビルドをまとめたマルチアーキテクチャイメージ。
# ビルドステージとして使う(COPY --from=ghcr.io/nercone-infra/openssl:<version> /opt/openssl ...)。
# ファイルを保持するだけ(シェルなし、何も実行しない)なので、ベースイメージにはしないこと。
# コンテキスト(<context>/amd64/、<context>/arm64/)は image/prepare.sh が用意する。
FROM scratch
ARG TARGETARCH
COPY --chown=0:0 ${TARGETARCH}/ /opt/openssl/
