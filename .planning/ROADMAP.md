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
- [ ] TBD (run /gsd-plan-phase 2 to break down)

**Status:** Not planned yet

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WIN-01: GitHub Action Windows build | Phase 1 | ✓ Complete |
| MAC-01: macOS build script | Phase 2 | ○ Pending |
| MAC-02: macOS GitHub Action | Phase 2 | ○ Pending |
| MAC-03: README macOS documentation | Phase 2 | ○ Pending |

**Coverage:** 4 requirements, 4 mapped
