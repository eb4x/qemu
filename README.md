# CI branch

This orphan branch holds only the GitHub Actions workflow that cross-builds
the QEMU guest agent MSI installers (i386, x86_64, aarch64) in a Fedora
container. The i386 job auto-skips on refs newer than the 10.x series:
QEMU dropped 32-bit x86 host support in 11.0 (commit c1997d85cb), so
`qga-arm64/stable-10.2` is the last branch that produces qemu-ga-i386.msi.

## Branches

`master`, `stable-11.0`, `staging-11.0` and `stable-10.2` are unmodified
mirrors of the upstream QEMU branches. The patched code lives on
`qga-arm64/<base>`: the Windows-on-ARM64 `qemu-ga` patches on top of
`<base>`, plus, on the 10.2 and 11.0 branches, a cherry-pick of upstream
c3399b2868 (VssOption registry fix) that `master` already contains.

This branch is the repository's default because GitHub only dispatches
workflows that exist on the default branch, so GitHub's ahead/behind
banner compares every branch against `ci`. Compare each patch branch with
its base instead:

| Branch | Diff against upstream |
|---|---|
| `qga-arm64/master` | [master...qga-arm64/master](../../compare/master...qga-arm64/master) |
| `qga-arm64/stable-11.0` | [stable-11.0...qga-arm64/stable-11.0](../../compare/stable-11.0...qga-arm64/stable-11.0) |
| `qga-arm64/staging-11.0` | [staging-11.0...qga-arm64/staging-11.0](../../compare/staging-11.0...qga-arm64/staging-11.0) |
| `qga-arm64/stable-10.2` | [stable-10.2...qga-arm64/stable-10.2](../../compare/stable-10.2...qga-arm64/stable-10.2) |

## Mirror sync

`sync-mirrors.sh` force-pushes upstream QEMU's branches over the fork's
upstream-named branches. Nobody commits to those, so forcing loses nothing
and also follows upstream when it rewrites a branch (`staging-*` can be).
Both forks run it daily from this branch:

- GitHub: `.github/workflows/sync-mirrors.yml` (04:23 UTC) syncs all four
  branches. The workflow token cannot push commits that touch
  `.github/workflows`, so if upstream changes its `lockdown.yml` that run
  fails and the branch needs a manual push.
- GitLab ([eb4x/qemu](https://gitlab.com/eb4x/qemu)): `.gitlab-ci.yml`, run
  by a pipeline schedule on `ci`, syncs the same four branches. It pushes with the job
  token (Settings > CI/CD > Job token permissions > "Allow Git push
  requests") and with `-o ci.skip`, so QEMU's own CI does not start.

Run it by hand with
`gh workflow run sync-mirrors.yml --ref ci` or GitLab's "Run pipeline" on `ci`.

## Building

Trigger the workflow manually:

```sh
gh workflow run build-msi.yml --ref ci \
    -f ref=qga-arm64/master \
    -f release_tag=v11.1.0-rc3-qga-arm64.1   # optional: attach MSIs to a release
```

`ref` is the branch/tag/SHA of this repository to build. Use a
`qga-arm64/*` branch: the plain mirrors lack the patches this clang-only
toolchain needs (upstream's installer expects libgcc/libssp DLLs and has no
arm64 target). Without
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
  only delta from upstream is the `qga-arm64/<base>` patch set, linking its
  compare page from the table above; close with
  the `msiexec` snippet and the `SHA256SUMS` line.
- Mark RC builds `--prerelease` and open the body with `**Pre-release.**`.
