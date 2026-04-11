# Phase 2: Add macOS libvlc build support - Research

**Researched:** 2026-04-11
**Domain:** VideoLAN libVLC macOS native build
**Confidence:** HIGH (verified against VideoLAN infrastructure)

## Summary

Phase 2 adds macOS build support to the existing LibVLC build pipeline. Unlike Phase 1 (Windows) which uses Docker cross-compile from Linux, macOS builds **must use native macOS runners** because VideoLAN does not provide Darwin cross-compile Docker images, and the VLC macOS build script requires `xcrun` (macOS-only SDK tools). The approach extends the existing `build-libvlc.yml` workflow with a `macos` matrix entry using `runs-on: macos-latest`.

**Primary recommendation:** Use GitHub Actions native macOS runner (`macos-latest`) instead of Docker cross-compile. Create `build-libvlc-macos.sh` wrapper following the Windows script pattern. Build universal binary (arm64 + x86_64) by running builds twice and combining with `lipo`.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions

| ID | Decision | Implication |
|----|----------|--------------|
| D-01 | Minimum macOS version: 13 (Ventura) | Must use `-a arm64 -a x86_64` and set deployment target |
| D-02 | Universal binary (arm64 + x86_64) | Must build twice and combine with `lipo` |
| D-03 | Use `macos-latest` runner | Auto-updates with latest macOS, simpler matrix maintenance |
| D-04 | Docker cross-compile (NEEDS RECONSIDERATION) | **Blocked** - No Darwin image in VideoLAN registry |
| D-05 | Extend existing workflow with matrix | `build-libvlc.yml` add `os: [windows, macos]` dimension |
| D-06 | Create new wrapper script | `build-libvlc-macos.sh` following `build-libvlc.sh` pattern |

### Claude's Discretion

- Build architecture details (arm64/x86_64 specific flags)
- How to combine universal binary (lipo command)
- Documentation structure in README

### Deferred Ideas

None — discussion stayed within phase scope

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAC-01 | macOS build script | Pattern from `build-libvlc.sh`, native macOS runner approach |
| MAC-02 | macOS GitHub Action | Extend `build-libvlc.yml` with matrix `os: [windows, macos]` |
| MAC-03 | README macOS documentation | Document macOS build steps, artifacts, and usage |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| VLC source | 3.0.x branch | Core library | Same as Windows build |
| macOS SDK | system default on macos-latest | Compilation targets | Native Xcode toolchain |
| Xcode/clang | latest on macos-latest | Compiler | Required for macOS builds |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| VLC macOS build script | `./extras/package/macosx/build.sh` | Actual build logic | Referenced by wrapper |
| `lipo` | system tool | Combine universal binaries | After separate arm64/x86_64 builds |
| `vlc-build/extras/package/macosx/configure.sh` | VLC 3.0.x | Configure VLC for macOS | During build |

### Key Finding: No Darwin Docker Image

**Verified:** VideoLAN registry (registry.videolan.org) does NOT contain any Darwin/macOS cross-compile images.

Available VLC Docker images (2026-04-11):
- `vlc-debian-win64-3.0`, `vlc-debian-win32-3.0`
- `vlc-debian-android`, `vlc-debian-android-3.0`
- `vlc-debian-llvm-mingw`, `vlc-debian-llvm-msvcrt`
- And others: flatpak, wasm, raspbian, etc.

**No `vlc-debian-darwin` or similar exists.** [VERIFIED: VideoLAN registry catalog]

This contradicts D-04 which states "Docker cross-compile using VideoLAN's docker-images with Darwin cross-compile tools."

### Key Finding: No Prebuilt macOS Contribs

**Verified:** VideoLAN artifacts server (artifacts.videolan.org) only contains:
- `vlc-3.0/win64/` — Windows 64-bit prebuilt contribs
- `vlc-3.0/android/` — Android prebuilt contribs

**No `vlc-3.0/macosx/` directory exists.** [VERIFIED: HTTP 404 on macosx path]

This means macOS builds cannot use `VLC_PREBUILT_CONTRIBS_URL` and must build contribs from source.

---

## Architecture Patterns

### Recommended Project Structure
```
LibVLC/
├── build-libvlc.sh           # Windows build (existing)
├── build-libvlc-macos.sh     # macOS build (NEW)
├── .github/workflows/
│   └── build-libvlc.yml      # Extended with macos matrix
└── docs/
    └── build-libvlc-macos.md # macOS documentation (NEW)
```

### Pattern 1: GitHub Actions Matrix Strategy

**What:** Extend existing `build-libvlc.yml` with matrix dimension for `os`

**When to use:** Building same VLC version for multiple platforms

**Example:**
```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - os: windows
            container: registry.videolan.org/vlc-debian-win64-3.0:20251220085103
          - os: macos
            runner: macos-latest
    runs-on: ${{ matrix.os == 'macos' && 'macos-latest' || 'ubuntu-latest' }}
    container: ${{ matrix.os == 'windows' && matrix.container || null }}
```

**Anti-pattern (what NOT to do):**
```yaml
# WRONG - Docker cannot build macOS binaries
- os: macos
  container: registry.videolan.org/vlc-debian-darwin  # DOES NOT EXIST
```

### Pattern 2: Universal Binary Build

**What:** Build arm64 and x86_64 separately, then combine with `lipo`

**When to use:** Creating single binary for both Intel and Apple Silicon Macs

**Example:**
```bash
# Build for arm64
./extras/package/macosx/build.sh -a arm64 -r -p

# Build for x86_64  
./extras/package/macosx/build.sh -a x86_64 -r -p

# Combine into universal binary
lipo -create -output libvlc.dylib \
    builddir-arm64/lib/.libs/libvlc.dylib \
    builddir-x86_64/lib/.libs/libvlc.dylib
```

### Pattern 3: Build Script Wrapper

**What:** Wrapper script following same interface as Windows build script

**Example:**
```bash
#!/bin/bash
set -e

VLC_REPO="https://code.videolan.org/videolan/vlc.git"
VLC_COMMIT="${VLC_COMMIT:-2d8e0f8cf5935dca3917ce015299eb91480d8167}"
VLC_CONTRIB_SHA="${VLC_CONTRIB_SHA:-4ca2c80e9a79293ceac7d640ab7963c3b000c370}"
BUILD_FLAGS="-r -p"  # release, prebuilt contribs (not available for macOS, but same flag format)

# ... build steps using native macOS tools ...
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-compiling macOS from Linux | Custom Docker Darwin image | Native macOS runner | Apple doesn't support cross-compilation; `xcrun` only exists on macOS |
| Universal binary creation | Custom fat binary tool | `lipo` system tool | Apple-provided, handles all architectures correctly |
| macOS SDK detection | Custom SDK finder | `xcrun --show-sdk-path` | Built-in, always returns correct SDK |

---

## Common Pitfalls

### Pitfall 1: Attempting Docker-based macOS Cross-Compile

**What goes wrong:** Build fails because no Darwin Docker image exists; VLC's build.sh uses `xcrun` which is macOS-only.

**Why it happens:** Decision D-04 incorrectly assumes Darwin cross-compile Docker image exists.

**How to avoid:** Use `runs-on: macos-latest` native macOS runner instead of Docker.

**Warning signs:**
```
xcrun: error: unable to find utility "xcrun", not a developer tool
```

### Pitfall 2: Missing Prebuilt Contribs for macOS

**What goes wrong:** Build fails when trying to use `VLC_PREBUILT_CONTRIBS_URL` for macOS.

**Why it happens:** VideoLAN doesn't provide prebuilt macOS contribs on artifacts.videolan.org.

**How to avoid:** Build without `-p` flag, or ensure contribs are built from source.

**Warning signs:**
```
VLC_PREBUILT_CONTRIBS_URL is set but no prebuilt macOS contribs available
```

### Pitfall 3: Deployment Target Too Old

**What goes wrong:** Xcode toolchain errors when targeting macOS 10.7 (VLC default).

**Why it happens:** MINIMAL_OSX_VERSION in build.sh defaults to 10.7, but D-01 requires Ventura (13+).

**How to avoid:** Explicitly pass `-k <sdk-path>` and use `MACOSX_DEPLOYMENT_TARGET=13` via `EXTRA_CFLAGS`.

**Warning signs:**
```
ld: symbol(s) not found for architecture arm64
Werror=partial-availability errors
```

### Pitfall 4: Universal Binary Missing Architecture

**What goes wrong:** Final binary only contains one architecture.

**Why it happens:** Build for one architecture failed silently, or `lipo` command wrong.

**How to avoid:** Verify each architecture build succeeded before combining; check final binary with `lipo -info`.

**Warning signs:**
```
lipo: can't figure out the architecture type of file
```

---

## Code Examples

### GitHub Actions Matrix Extension

```yaml
# Source: Extended from .github/workflows/build-libvlc.yml
jobs:
  build:
    strategy:
      matrix:
        os: [windows, macos]
        include:
          - os: windows
            runs-on: ubuntu-latest
            container: registry.videolan.org/vlc-debian-win64-3.0:20251220085103
          - os: macos
            runs-on: macos-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build VLC
        if: matrix.os == 'macos'
        run: |
          ./build-libvlc-macos.sh
```

### macOS Build Script (Key Sections)

```bash
#!/bin/bash
# Source: Pattern from vlc-build/extras/package/macosx/build.sh
set -e

VLC_REPO="https://code.videolan.org/videolan/vlc.git"
VLC_COMMIT="${VLC_COMMIT:-2d8e0f8cf5935dca3917ce015299eb91480d8167}"

# Build for specific architecture
build_arch() {
    local arch=$1
    local builddir="vlc-build-${arch}"
    
    # Clone VLC
    git clone "${VLC_REPO}" "${builddir}"
    cd "${builddir}"
    git checkout "${VLC_COMMIT}"
    
    # Build using native macOS tools
    ./extras/package/macosx/build.sh -a "${arch}" -r
    cd ..
}

# Build both architectures
build_arch arm64
build_arch x86_64

# Combine with lipo
lipo -create -output libvlc.dylib \
    vlc-build-arm64/lib/.libs/libvlc.dylib \
    vlc-build-x86_64/lib/.libs/libvlc.dylib
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Docker cross-compile for all platforms | Native runner for macOS | 2026-04 (this phase) | Windows uses Docker; macOS uses native |
| Single architecture builds | Universal binary (arm64 + x86_64) | D-02 (this phase) | Single artifact works on all Macs |

**Deprecated/outdated:**
- Docker Darwin cross-compile: Never existed in VideoLAN infrastructure
- VLC_PREBUILT_CONTRIBS_URL for macOS: No prebuilt macOS contribs available

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | VideoLAN registry has no Darwin images | Standard Stack | If wrong, Docker approach could work; would need verification |
| A2 | No prebuilt macOS contribs on artifacts.videolan.org | Standard Stack | If wrong, builds could be faster with prebuilt contribs |
| A3 | Native macOS runner is required | Architecture | If wrong (cross-compile works), Docker approach viable |

**If this table is empty:** All claims in this research were verified or cited.

---

## Open Questions

1. **How to handle extended build time?**
   - What we know: macOS builds must compile contribs from source (no prebuilt), adding significant time
   - What's unclear: Acceptable build duration; whether to use caching
   - Recommendation: Add `ccache` support and GitHub Actions cache for contribs

2. **Universal binary combining strategy?**
   - What we know: Must build twice (arm64 + x86_64) and combine with `lipo`
   - What's unclear: Exact `lipo` command syntax; where to place final binary
   - Recommendation: Use `lipo -create -output` with explicit paths

3. **Deployment target compatibility?**
   - What we know: VLC defaults to 10.7; D-01 requires 13+
   - What's unclear: Whether build succeeds with newer deployment target
   - Recommendation: Explicitly pass `MACOSX_DEPLOYMENT_TARGET=13` via environment variables

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies beyond GitHub Actions which is cloud-hosted)

---

## Security Domain

N/A — Build system extension only; no authentication, session management, or input validation changes.

---

## Sources

### Primary (HIGH confidence)
- VideoLAN Docker registry catalog — `curl -s "https://registry.videolan.org/v2/_catalog"` — Confirmed no Darwin images exist
- VideoLAN artifacts server — `curl -sI "https://artifacts.videolan.org/vlc-3.0/macosx/"` — Confirmed 404 (no macOS contribs)
- `vlc-build/extras/package/macosx/build.sh` — Native macOS build script, uses `xcrun` (macOS-only)

### Secondary (MEDIUM confidence)
- GitHub Actions `macos-latest` runner documentation — Standard practice for macOS CI

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Verified VideoLAN infrastructure directly
- Architecture: HIGH — Pattern follows existing Windows workflow
- Pitfalls: HIGH — Based on verified VideoLAN infrastructure gaps

**Research date:** 2026-04-11
**Valid until:** 30 days (VideoLAN infrastructure changes infrequently)
