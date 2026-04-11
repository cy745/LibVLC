# Phase 2: Add macOS libvlc build support - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the LibVLC build pipeline to support macOS platform. Deliver a macOS build script, GitHub Action matrix entry, and README documentation. Phase 1 established Windows build; this phase adds macOS parity.

</domain>

<decisions>
## Implementation Decisions

### macOS version targets
- **D-01:** Minimum macOS version: 13 (Ventura)
- **D-02:** Binary type: Universal binary (arm64 + x86_64) — single binary runs on both Intel and Apple Silicon

### GitHub Action runner
- **D-03:** Use `macos-latest` runner — auto-updates with latest macOS, simpler matrix maintenance

### Build approach
- **D-04:** Native macOS runner — use `runs-on: macos-latest` directly (VideoLAN's Docker registry has NO Darwin cross-compile images — verified 2026-04-11). Build arm64 and x86_64 separately, combine with `lipo` for universal binary.

### GitHub Action structure
- **D-05:** Extend existing `build-libvlc.yml` workflow with matrix strategy — add `os: [windows, macos]` dimension rather than creating separate workflows

### Build script
- **D-06:** Create new wrapper script (e.g., `build-libvlc-macos.sh`) — do not reuse `vlc-build/extras/package/macosx/build.sh` directly; wrapper provides consistent interface with Windows script

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Build system
- `.github/workflows/build-libvlc.yml` — Existing Windows build workflow (to extend with macOS matrix)
- `build-libvlc.sh` — Existing Windows build wrapper (reference for new macOS wrapper)
- `vlc-build/extras/package/macosx/build.sh` — VLC's native macOS build script (source reference, not direct reuse)

### Docker images
- VideoLAN docker-images repository: `registry.videolan.org/vlc-debian-darwin` or similar (verify correct tag for Darwin cross-compile)

[If no external specs: "No external specs — requirements fully captured in decisions above"]

</canonical_refs>

<codebase_context>
## Existing Code Insights

### Reusable Assets
- `build-libvlc.sh` — Windows build wrapper with consistent interface pattern to replicate for macOS
- Phase 1 Docker approach: use Docker cross-compile with pre-built VLC Docker images

### Established Patterns
- SHA-pair validation: VLC commit + contribs SHA must match exactly (same constraint for macOS)
- Artifact upload pattern: upload DLLs/modules as build artifacts (same for macOS .dylib/.a)

### Integration Points
- New macOS build job joins existing `build-libvlc.yml` matrix
- New `build-libvlc-macos.sh` follows same directory structure as `build-libvlc.sh`

</codebase_context>

<specifics>
## Specific Ideas

- Universal binary chosen to simplify distribution — single artifact for Intel + Apple Silicon
- macos-latest runner selected for simplicity — accepts occasional breakage from macOS updates

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-add-macos-build-support*
*Context gathered: 2026-04-11*
