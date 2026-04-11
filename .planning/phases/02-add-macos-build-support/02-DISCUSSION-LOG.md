# Phase 2: Add macOS libvlc build support - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 02-add-macos-build-support
**Areas discussed:** macOS version targets

---

## macOS version targets

| Option | Description | Selected |
|--------|-------------|----------|
| macOS 11 (Big Sur) | Wide compatibility, covers Intel and Apple Silicon | |
| macOS 12 (Monterey) | Modern baseline, recommended for 2024+ | |
| macOS 13 (Ventura) | Latest features, narrower compat | ✓ |

**User's choice:** macOS 13 (Ventura)

---

## Binary type

| Option | Description | Selected |
|--------|-------------|----------|
| Universal binary | Single binary runs on both Intel and Apple Silicon | ✓ |
| Separate binaries | Build Intel and ARM separately, distribute both | |

**User's choice:** Universal binary

---

## GitHub runner

| Option | Description | Selected |
|--------|-------------|----------|
| macos-latest | Automatically gets latest macOS, auto-updates | ✓ |
| macos-13 (Ventura) | Fixed version, more predictable builds | |
| macos-14 (Sonoma) | Latest stable, good Apple Silicon support | |

**User's choice:** macos-latest

---

## Build approach

| Option | Description | Selected |
|--------|-------------|----------|
| Docker cross-compile | Use VideoLAN docker-images with Darwin tools | ✓ |
| Native macOS runner | Build directly on macOS runner | |

**User's choice:** Docker cross-compile

---

## GitHub Action structure

| Option | Description | Selected |
|--------|-------------|----------|
| Extend existing workflow with matrix | Add `os: [windows, macos]` to existing build-libvlc.yml | ✓ |
| Separate workflow | Create new dedicated macOS workflow | |

**User's choice:** Extend existing

---

## Build script

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse VLC's macosx/build.sh | Direct use of VLC's native script | |
| New wrapper script | Create new wrapper (e.g., build-libvlc-macos.sh) | ✓ |

**User's choice:** New wrapper script

---

## Deferred Ideas

No deferred ideas — all questions stayed within phase scope.

