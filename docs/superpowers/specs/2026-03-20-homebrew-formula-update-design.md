# Homebrew Formula Update for clipssh-paste

## Problem

The Homebrew formula for clipssh (`Formula/clipssh.rb` in `strubio-ray/homebrew-tap`) depends on `pngpaste` and only installs the `clipssh` bash script. The new `clipssh-paste` Swift CLI needs to be compiled from source and installed alongside the script, and the `pngpaste` dependency needs to be removed.

## Solution

Update the formula to compile `clipssh-paste` from Swift source during `brew install` and install both binaries.

## Updated Formula

```ruby
class Clipssh < Formula
  desc "Send clipboard images to remote SSH hosts"
  homepage "https://github.com/strubio-ray/clipssh"
  url "https://github.com/strubio-ray/clipssh/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  depends_on :macos

  def install
    # Compile Swift CLI helper
    system "swiftc", "-O", "-o", "clipssh-paste", "swift/ClipsshPaste.swift"

    # Embed version in shell script
    inreplace "clipssh", "%%VERSION%%", version.to_s

    # Install both binaries
    bin.install "clipssh"
    bin.install "clipssh-paste"
  end

  test do
    assert_match "clipssh #{version}", shell_output("#{bin}/clipssh --version")
    assert_match "clipssh-paste", shell_output("#{bin}/clipssh-paste --version")
  end
end
```

## Changes from Current Formula

- **Removed:** `depends_on "pngpaste"`
- **Updated:** `desc` from "screenshots" to "images"
- **Added:** `system "swiftc"` to compile `clipssh-paste` from source
- **Added:** `bin.install "clipssh-paste"` to install the compiled binary
- **Added:** Test assertion for `clipssh-paste --version`

## What Stays the Same

- `depends_on :macos` — still macOS-only
- `inreplace` for version embedding in the bash script
- Existing `clipssh --version` test
- Auto-bump workflow — `mislav/bump-homebrew-formula-action` in the clipssh source repo triggers on `v*` tags and updates only `url` and `sha256`, preserving the formula logic

## Swift Compilation

`swiftc` is provided by Xcode Command Line Tools, which Homebrew already requires on macOS. No explicit Swift dependency declaration is needed.

## Deployment Sequence

1. Merge the clipssh source changes (Swift CLI, script updates) to main
2. Update the formula in `strubio-ray/homebrew-tap` manually (this is a one-time logic change)
3. Tag and push `v1.2.0` (or appropriate version) in the clipssh source repo
4. The auto-bump action updates `url` and `sha256` in the formula
5. Future version bumps continue to work automatically

Note: Steps 2 and 3-4 must be coordinated. The formula should be updated before or at the same time as the version tag, so that the new tarball (containing `swift/ClipsshPaste.swift`) is fetched by a formula that knows how to compile it.

## Validation

After updating the formula, run:

```bash
brew audit --formula --tap strubio-ray/tap
brew style strubio-ray/tap
```

These are the same checks run by the tap's `lint.yml` CI workflow.
