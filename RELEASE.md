# Releasing SideKick (Sparkle auto-updates)

SideKick ships auto-updates with [Sparkle](https://sparkle-project.org). Updates are
distributed through **GitHub Releases**, and the app reads a signed `appcast.xml`
served from `main`:

```
SUFeedURL     = https://raw.githubusercontent.com/synth-inc/onit/main/appcast.xml
SUPublicEDKey = Exm1gtRzTJItzeYn3oywxb3r0W75AVEhdCEHK5A1mec=   (Info.plist)
```

> ⚠️ The feed is served by `raw.githubusercontent.com`, so **the repository must be
> public** for clients to fetch updates.

## Signing keys (EdDSA)

Each app has its own EdDSA key pair. The **private** key lives in the macOS Keychain
under the account `onit-sidekick` and is also backed up (outside any repo) at
`~/.sparkle-keys/onit-sidekick_eddsa.private`. The **public** key is in `Info.plist`
(`SUPublicEDKey`) and must never change once users are in the wild — rotating it
breaks updates for everyone on an older build.

To inspect or re-import the key:

```bash
# print the public key associated with the account
.../Sparkle/bin/generate_keys -p --account onit-sidekick
# re-import the private key on a new machine / CI
.../Sparkle/bin/generate_keys -f ~/.sparkle-keys/onit-sidekick_eddsa.private --account onit-sidekick
```

For CI, store the contents of `onit-sidekick_eddsa.private` as a GitHub Actions secret
and import it before signing.

## Cutting a release

1. Bump the version: set `MARKETING_VERSION` (and increment `CURRENT_PROJECT_VERSION`)
   in the Xcode project.
2. Make sure notarization credentials are exported (used by `build_and_notarize.sh`):
   ```bash
   export NOTARY_KEY_PATH=/path/to/AuthKey_XXXX.p8
   export NOTARY_KEY_ID=XXXXXXХXXX
   export NOTARY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```
3. Authenticate the GitHub CLI once: `gh auth status` (or `gh auth login`).
4. Run the release script from `macos/`:
   ```bash
   cd macos
   ./release.sh                 # uses the project's MARKETING_VERSION
   # or: ./release.sh 4.1.0 --notes "What's new…"
   ```

The script: builds & notarizes the app → publishes a GitHub Release `vX.Y.Z` with
`SideKick-X.Y.Z.dmg` → regenerates and **EdDSA-signs** `appcast.xml` (preserving past
items, pointing enclosures at the release asset) → commits and pushes `appcast.xml`
to `main`. Sparkle clients pick it up at their next check.

### Useful flags

| Flag | Effect |
|------|--------|
| `--skip-build` | Reuse the existing `build/SideKick.dmg` (skip build + notarize). |
| `--no-push`    | Generate the signed appcast locally only — no Release, no commit, no push. Good for a dry run. |
| `--notes "…"`  | Custom release notes (otherwise auto-generated from commits). |

## How updates are signed & verified

`generate_appcast` hashes each `.dmg`, signs it with the private key, and writes the
`sparkle:edSignature`/`length` enclosure attributes into `appcast.xml`. The app
verifies that signature against the bundled `SUPublicEDKey` before installing —
so a tampered or unsigned build is rejected.

## Homebrew

The app is also distributed as a Homebrew cask in
[`synth-inc/homebrew-tap`](https://github.com/synth-inc/homebrew-tap):

```bash
brew install --cask synth-inc/homebrew-tap/onit-sidekick
```

`release.sh` updates the cask **automatically** on every release — it computes the new
`sha256`, bumps `version`, points the `url` at the GitHub Release asset, and pushes to the
tap. The tap defaults to `~/SynthInc/homebrew-tap` (override with `TAP_DIR=…`). The cask
becomes installable only after the first real release fills in its `version`/`sha256`.

## First publication checklist

- [ ] Repository is **public** (required for the raw appcast URL).
- [ ] Rotate any leaked secrets first (see the open-source audit).
- [ ] Confirm `SUPublicEDKey` in `Info.plist` matches `generate_keys -p --account onit-sidekick`.
- [ ] Cut the first release with `./release.sh` and verify the appcast enclosure URL
      resolves (the uploaded `.dmg` is downloadable).
