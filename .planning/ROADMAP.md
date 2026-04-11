# Roadmap

## Phase 1: Windows Build Pipeline
**Goal:** Establish stable Windows libvlc.dll build via GitHub Actions

**Requirements:** WIN-01

**Success Criteria:**
- GitHub Action triggers on push and builds successfully
- libvlc.dll and modules are uploaded as artifacts
- Build is reproducible with documented SHA pairs

**Plans:**
- Plan 1: Configure Windows GitHub Action

**Status:** ✓ Complete

---

## Phase 2: Add macOS libvlc build support
**Goal:** Extend build system to support macOS platform

**Requirements:** MAC-01, MAC-02, MAC-03

**Success Criteria:**
- macOS build script created
- GitHub Action matrix includes macOS
- README documents macOS usage

**Plans:**
- [x] 02-01-PLAN.md — Create macOS build script (build-libvlc-macos.sh)
- [x] 02-02-PLAN.md — Extend GitHub Actions with macOS matrix + README update

**Status:** Planned (2 plans, 2 waves)

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WIN-01: GitHub Action Windows build | Phase 1 | ✓ Complete |
| MAC-01: macOS build script | Phase 2 | ○ Planned (02-01) |
| MAC-02: macOS GitHub Action | Phase 2 | ○ Planned (02-02) |
| MAC-03: README macOS documentation | Phase 2 | ○ Planned (02-02) |

**Coverage:** 4 requirements, 4 mapped
