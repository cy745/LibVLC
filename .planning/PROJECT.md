# LibVLC Windows Build Pipeline

## What This Is

自动化 LibVLC Windows x86_64 交叉编译流水线，验证现有脚本有效性，补全踩坑记录，最终实现 GitHub Action 可构建的 CI/CD 流程。

## Core Value

能够通过 GitHub Action 稳定、可复现地构建 libvlc.dll

## Requirements

### Active

- [ ] 验证 build-libvlc.sh 脚本稳定性
- [ ] 验证 GitHub Action workflow 能够成功构建
- [x] 补全踩坑记录：VLC commit 与 contribs SHA 的获取方法
- [x] 创建 GitHub Action workflow
- [x] 本地构建验证成功：libvlc.dll (604K), libvlccore.dll (6.3M), 362 plugins

### Done

- **2026-04-11**: 创建 GitHub Action workflow (`.github/workflows/build-libvlc.yml`)
- **2026-04-11**: 更新 SHA 配对表，推荐使用 `2d8e0f8cf5935dca3917ce015299eb91480d8167` + `4ca2c80e9a79293ceac7d640ab7963c3b000c370`
- **2026-04-11**: 添加三种获取有效 SHA 的方法（GitLab、artifacts 站、API）

## Context

已有项目资产：
- `build-libvlc.sh` - 自动构建脚本（硬编码了 VLC_COMMIT 和 CONTRIB_SHA）
- `verify-build.sh` - 构建产物验证脚本
- `docs/build-libvlc.md` - 完整构建文档和踩坑记录

已知问题：
- VLC commit 与 contribs SHA 必须精确匹配，否则 SHA512 校验失败
- 当前脚本中的 SHA 对 (`2a48cfe344b792161ff47caf26d78f4661587bab`) 在 artifacts 站存在但未验证是否真正匹配
- 缺少 GitHub Action 流水线

## Constraints

- **构建环境**: Docker + VLC 官方 docker-images
- **目标平台**: Windows x86_64 (mingw-w64)
- **VLC 版本**: 3.0.x (stable branch)
- **网络**: 需要访问 artifacts.videolan.org 和 code.videolan.org

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 使用 VLC 3.0.x 分支 | 3.0.x 是稳定长期支持版本，API 兼容性好 | — Pending |
| 使用预编译 contribs | 避免从源码编译 FFmpeg 等大依赖，缩短构建时间 | — Pending |
| Docker 交叉编译方式 | 避免 Windows 本地构建工具链复杂性 | — Pending |

---

*Last updated: 2026-04-11 after initialization*
