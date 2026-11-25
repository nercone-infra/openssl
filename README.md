# nercone-infra/openssl

Pre-built OpenSSL binaries, built and published automatically via GitHub Actions.

This repository does not contain OpenSSL source code. It periodically checks the [official OpenSSL releases](https://github.com/openssl/openssl/releases) for new stable versions, builds them for multiple platforms/architectures, and publishes the results as [GitHub Releases](https://github.com/nercone-infra/openssl/releases).

## Platforms

- Linux (x86_64, AArch64)
- macOS (x86_64, AArch64)
- Windows (x86_64, AArch64)

Each release asset is named `openssl-<version>-<platform>-<arch>` and is provided as `.zip`, `.tar.gz`, `.tar.xz`, and `.7z`.

Each release also includes `SHA256SUMS`, `SHA384SUMS`, and `SHA512SUMS` files with checksums for all assets in that release.

## How it works

The build workflow ([`.github/workflows/build.yml`](.github/workflows/build.yml)):

1. Runs on a schedule (every 6 hours) or on manual dispatch.
2. Determines which OpenSSL versions need to be built — the 10 most recent stable releases from `openssl/openssl` that don't already have a corresponding release in this repository, or a specific version if provided manually.
3. Builds each version for every target platform/architecture using OpenSSL's own `Configure` + `make`/`nmake` build system (`no-tests`).
4. Verifies the resulting `openssl` binary runs and reports its version.
5. Packages the install output into `.zip`, `.tar.gz`, `.tar.xz`, and `.7z` archives.
6. Publishes a GitHub Release tagged `openssl-<version>` with all platform archives attached.

## Usage

Download the archive matching your platform and architecture from the [Releases page](https://github.com/nercone-infra/openssl/releases), extract it, and use the `openssl` binary under `bin/`.

To verify an archive, download the corresponding `SHA256SUMS`, `SHA384SUMS`, or `SHA512SUMS` file from the same release and check it, e.g. `sha256sum -c SHA256SUMS --ignore-missing`.

## Use in GitHub Actions

Other repositories can install these binaries with the `setup` action:

```yaml
steps:
  - uses: nercone-infra/openssl/setup@main
    with:
      version: '3.5' # "latest" (default), a prefix such as "3" or "3.5", or an exact "x.y.z"
  - run: openssl version
```

The action picks the highest matching release, downloads the archive for the runner's OS and architecture (Linux/macOS/Windows, x86_64/AArch64), verifies it against `SHA256SUMS`, and adds `openssl` to `PATH`.

| Input | Default | Description |
| --- | --- | --- |
| `version` | `latest` | Version to install. |
| `path` | `$RUNNER_TEMP/openssl-<version>` | Install directory. Must be empty or not exist. |
| `repository` | `nercone-infra/openssl` | Repository that publishes the releases. |
| `github-token` | `github.token` | Token used to read the releases. |

| Output | Description |
| --- | --- |
| `version` | Installed version (`x.y.z`). |
| `root` | Installation root (`bin`, `lib`, `include`, `ssl`). |

The action also sets `OPENSSL_DIR`, `OPENSSL_ROOT_DIR`, `OPENSSL_CONF`, and `OPENSSL_MODULES` for the rest of the job. On Linux and macOS, `openssl` on `PATH` is a small wrapper that sets the library path for that command only, so other programs in the job keep using their own libraries.

## Disclaimer

Binaries are built directly from unmodified OpenSSL source releases using the options shown in the workflow file.
No warranty is provided; verify binaries are suitable for your use case before relying on them, especially in security-sensitive contexts.
