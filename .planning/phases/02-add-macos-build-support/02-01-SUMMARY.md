---
phase: "02"
plan: "01"
subsystem: "build"
tags:
  - "macos"
  - "build"
  - "libvlc"
  - "universal-binary"
dependency_graph:
  requires: []
  provides:
    - "build-libvlc-macos.sh"
  affects:
    - ".github/workflows/build-libvlc.yml"
tech_stack:
  added:
    - "lipo (macOS fat binary tool)"
    - "xcrun (macOS SDK manager)"
    - "MACOSX_DEPLOYMENT_TARGET=13"
  patterns:
    - "Native macOS runner approach (no Docker cross-compile)"
    - "Universal binary via lipo -create"
    - "Build twice (arm64 + x86_64) then combine"
key_files:
  created:
    - "build-libvlc-macos.sh"
decisions:
  - "D-01: Minimum macOS version 13 (Ventura)"
  - "D-02: Universal binary (arm64 + x86_64)"
  - "D-04: Native macOS runner (no Darwin Docker image available)"
  - "D-06: New wrapper script following build-libvlc.sh pattern"
metrics:
  duration: ""
  completed: "2026-04-11"
---

# Phase 02 Plan 01: macOS Build Script Summary

## One-liner

Native macOS build automation script producing universal binary libvlc.dylib via lipo.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create build-libvlc-macos.sh script | efc86fc | build-libvlc-macos.sh |

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

| Criterion | Result |
|-----------|--------|
| Script exists and is executable | PASS |
| Contains VLC_REPO= | PASS (1 occurrence) |
| Contains MACOSX_DEPLOYMENT_TARGET=13 | PASS (1 occurrence) |
| Contains lipo -create | PASS (1 occurrence) |
| Contains arm64.*x86_64 pattern | PASS (2 occurrences) |

## Key Implementation Details

- **Build approach**: Native macOS runner (macos-latest) - VideoLAN has no Darwin Docker images
- **Universal binary**: Builds arm64 and x86_64 separately, combines via `lipo -create`
- **Contribs**: No prebuilt macOS contribs on artifacts.videolan.org - builds from source
- **Deployment target**: MACOSX_DEPLOYMENT_TARGET=13 (Ventura minimum per D-01)
- **Output location**: ./output-macos/libvlc.dylib (Universal Binary)

## Threat Flags

None - build script only pulls from official VideoLAN repository.

## Auth Gates

None.

## Known Stubs

None.
