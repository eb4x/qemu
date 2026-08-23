# CI branch

This orphan branch holds only the GitHub Actions workflow that cross-builds
the QEMU guest agent MSI installers (i386, x86_64, aarch64) in a Fedora
container. The i386 job auto-skips on refs newer than the 10.x series:
QEMU dropped 32-bit x86 host support in 11.0 (commit c1997d85cb), so
`stable-10.2` is the last branch that produces qemu-ga-i386.msi. It is kept separate so the release branches (`master`,
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

## Release naming

Releases are created by hand (the workflow only builds and uploads MSIs).
Keep them consistent:

- **Title**: `qemu-ga <version>: Windows MSI (<archs>)`, architectures in build
  order `x86_64, i386, aarch64`, listing only those actually attached. The
  title stays arch-agnostic: these are guest-agent builds for all Windows
  guests, not an ARM64-only drop.
- **Tag**: `v<version>-qga-arm64.<n>`, kept as-is for URL stability despite the
  arm64 in the name.
- **Body**: asset table with one row per MSI, `x86_64` first; state that the
  only delta from upstream is the Windows-on-ARM64 `qemu-ga` patch; close with
  the `msiexec` snippet and the `SHA256SUMS` line.
- Mark RC builds `--prerelease` and open the body with `**Pre-release.**`.
