# CI branch

This orphan branch holds only the GitHub Actions workflow that cross-builds
the QEMU guest agent MSI installers (i386, x86_64, aarch64) in a Fedora
container. It is kept separate so the release branches (`master`,
`stable-11.0`, `staging-11.0`) stay exactly "upstream + one patch".

Trigger it manually:

```sh
gh workflow run build-msi.yml --ref ci \
    -f ref=master \
    -f release_tag=v11.1.0-rc3-qga-arm64.1   # optional: attach MSIs to a release
```

`ref` is the branch/tag/SHA of this repository to build. Without
`release_tag` the MSIs are only uploaded as workflow artifacts.

The aarch64 job uses the clang/lld `ucrtarm64-*` toolchain from the
[ebbex/mingw Copr](https://copr.fedorainfracloud.org/coprs/ebbex/mingw/).
SHA256SUMS on releases are maintained by hand after uploads.
