# Homebrew Formula Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the Homebrew formula to compile and install `clipssh-paste` from Swift source, remove the `pngpaste` dependency, and inject version numbers into both binaries.

**Architecture:** Single formula file change in the `strubio-ray/homebrew-tap` repo. The formula adds an `inreplace` on the Swift source for version injection, a `swiftc` compile step, and installs both `clipssh` and `clipssh-paste` to the bin path.

**Tech Stack:** Ruby (Homebrew formula DSL), GitHub CLI (`gh`)

**Spec:** `docs/superpowers/specs/2026-03-20-homebrew-formula-update-design.md`

**Target repo:** `strubio-ray/homebrew-tap` (Formula/clipssh.rb)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `Formula/clipssh.rb` | Updated Homebrew formula with Swift compilation |

---

### Task 1: Clone the homebrew-tap repo

- [ ] **Step 1: Clone the repo**

```bash
gh repo clone strubio-ray/homebrew-tap /vm-clipssh/.homebrew-tap
```

- [ ] **Step 2: Verify the current formula exists**

```bash
cat /vm-clipssh/.homebrew-tap/Formula/clipssh.rb
```

Expected: The current formula with `depends_on "pngpaste"` and no Swift compilation.

---

### Task 2: Update the formula

**Files:**
- Modify: `.homebrew-tap/Formula/clipssh.rb`

- [ ] **Step 1: Replace the formula contents**

Replace the full contents of `.homebrew-tap/Formula/clipssh.rb` with:

```ruby
class Clipssh < Formula
  desc "Send clipboard images to remote SSH hosts"
  homepage "https://github.com/strubio-ray/clipssh"
  url "https://github.com/strubio-ray/clipssh/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "454583b42326053b14c3e5aed7a83fda7b0aade02e0b86d2370c50c6106c8ede"
  license "MIT"

  depends_on :macos

  def install
    # Embed version in Swift source before compiling
    inreplace "swift/ClipsshPaste.swift", 'let version = "1.0.0"', "let version = \"#{version}\""

    # Compile Swift CLI helper (explicit AppKit link for robustness)
    system "swiftc", "-O", "-framework", "AppKit", "-o", "clipssh-paste", "swift/ClipsshPaste.swift"

    # Embed version in shell script
    inreplace "clipssh", "%%VERSION%%", version.to_s

    # Install both binaries
    bin.install "clipssh"
    bin.install "clipssh-paste"
  end

  test do
    assert_match "clipssh #{version}", shell_output("#{bin}/clipssh --version")
    assert_match "clipssh-paste #{version}", shell_output("#{bin}/clipssh-paste --version")
  end
end
```

Note: The `url` and `sha256` are kept at the current `v1.1.2` values. They will be auto-bumped by `mislav/bump-homebrew-formula-action` when the new version tag is pushed to the clipssh source repo. The formula logic (install block, test block) persists across auto-bumps.

- [ ] **Step 2: Verify the changes look correct**

Check that:
- `depends_on "pngpaste"` is removed
- `depends_on :macos` is present
- `desc` says "images" not "screenshots"
- Two `inreplace` calls: one for Swift source, one for bash script
- `swiftc` call includes `-framework AppKit`
- Both `clipssh` and `clipssh-paste` are installed to bin
- Test block checks both binaries with version matching

---

### Task 3: Run Homebrew lint checks

- [ ] **Step 1: Run brew style check**

```bash
cd /vm-clipssh/.homebrew-tap && brew style Formula/clipssh.rb
```

Expected: No style violations.

Note: This may not work outside of a proper Homebrew tap installation. If it fails, visually verify the Ruby follows Homebrew formula conventions (2-space indent, standard DSL usage, no trailing whitespace).

- [ ] **Step 2: Commit**

```bash
cd /vm-clipssh/.homebrew-tap
git add Formula/clipssh.rb
git commit -m "feat: add clipssh-paste Swift compilation, remove pngpaste dependency"
```

---

### Task 4: Push changes

- [ ] **Step 1: Push to remote**

```bash
cd /vm-clipssh/.homebrew-tap && git push origin main
```

**Important:** Confirm with the user before pushing. This modifies the shared homebrew-tap repository.

---

### Deployment Notes (Post-Plan)

After this formula update is pushed:

1. Push the clipssh source changes to main (if not already done)
2. Tag and push the new version: `git tag v1.2.0 && git push origin v1.2.0`
3. The `bump-homebrew.yml` workflow in the clipssh repo will auto-update the formula's `url` and `sha256`
4. Users can then `brew upgrade clipssh` to get the new version

The formula logic change (this plan) must be in place **before** the version tag is pushed.
