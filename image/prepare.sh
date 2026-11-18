#!/bin/sh
# 1つのリリースの Linux アーカイブから image/Dockerfile のビルドコンテキストを用意する。
#   使い方: image/prepare.sh <version> <アーカイブと SHA384SUMS のあるディレクトリ> <context>
# 各アーカイブは展開前に SHA384SUMS と照合する。結果:
#   - インストールツリーを <context>/<docker のアーキテクチャ>/ に置く(イメージでは /opt/openssl)。
#   - lib/ は常に存在する(x86_64 では lib64/ へのリンク)。利用側で場合分けは不要。
#   - pkg-config ファイルはビルドマシンのパスではなく /opt/openssl を指す。
set -eu
version="$1"
archives="$2"
context="$3"

for pair in amd64:x86_64 arm64:aarch64; do
    platform="${pair%%:*}"
    arch="${pair#*:}"
    name="openssl-${version}-linux-${arch}"
    (cd "$archives" && grep " ${name}.tar.gz\$" SHA384SUMS | sha384sum -c -)
    rm -rf "$context/$platform" "$context/$name"
    mkdir -p "$context"
    tar -xzf "$archives/${name}.tar.gz" -C "$context"
    mv "$context/$name" "$context/$platform"
    tree="$context/$platform"
    if [ -d "$tree/lib64" ] && [ ! -e "$tree/lib" ]; then
        ln -s lib64 "$tree/lib"
    fi
    for file in "$tree"/lib/pkgconfig/*.pc; do
        sed "s|^prefix=.*|prefix=/opt/openssl|" "$file" > "$file.new"
        mv "$file.new" "$file"
    done
    grep -q "^Version: ${version}\$" "$tree/lib/pkgconfig/openssl.pc"
done
