# LibVLC Windows 构建指南

本文档记录了为 Windows 平台交叉编译 VideoLAN libvlc.dll 的完整流程，包括踩坑记录和解决方案。

## 目录

- [环境要求](#环境要求)
- [构建流程](#构建流程)
- [踩坑记录](#踩坑记录)
- [复现脚本](#复现脚本)

---

## 环境要求

### 软件依赖

| 软件 | 版本 | 说明 |
|------|------|------|
| Docker Desktop | Latest | 容器化构建环境 |
| Git | Latest | 源码管理 |

### 网络要求

- 能够访问 Docker Hub (`registry-1.docker.io`)
- 能够访问 VideoLAN 镜像站 (`artifacts.videolan.org`)
- 能够访问 GNU 镜像站 (`ftp.gnu.org`, `gmplib.org`)

---

## 构建流程

### 步骤 1: 克隆 VLC Docker 镜像仓库

```bash
git clone https://code.videolan.org/videolan/docker-images.git
cd docker-images
```

### 步骤 2: 构建 VLC 3.0.x 专用 Docker 镜像

```bash
cd vlc-debian-win64-3.0
docker build -t vlc-win64-3.0-local .
```

**说明：** 此步骤需要 1-2 小时，因为需要从源码编译 gcc 6.4.0。

### 步骤 3: 克隆 VLC 源码

```bash
cd C:/Users/12483/Documents/Code/LibVLC
git clone https://code.videolan.org/videolan/vlc.git vlc2
cd vlc2
git fetch origin <commit-hash>
git checkout <commit-hash>
```

### 步骤 4: 配置 Git 安全目录（Windows 特有）

Docker 容器内需要配置：

```bash
git config --global --add safe.directory /vlc
```

### 步骤 5: 执行构建

```bash
docker run --rm \
  -v "C:/path/to/vlc:/vlc" \
  -v "C:/path/to/output:/output" \
  -e VLC_PREBUILT_CONTRIBS_URL="https://artifacts.videolan.org/vlc-3.0/win64/vlc-contrib-x86_64-w64-mingw32-<CONTRIB_SHA>.tar.bz2" \
  vlc-win64-3.0-local \
  sh -c "git config --global --add safe.directory /vlc && cd /vlc && ./extras/package/win32/build.sh -z -r -p"
```

**参数说明：**
- `-z`: LibVLC only（跳过 Qt GUI）
- `-r`: Release 模式
- `-p`: 使用预编译 contribs

### 步骤 6: 复制构建产物

```bash
docker run --rm \
  -v "C:/path/to/vlc:/vlc" \
  -v "C:/path/to/output:/output" \
  vlc-win64-3.0-local \
  sh -c "cp /vlc/win64/lib/.libs/libvlc.dll /output/ && \
         cp /vlc/win64/src/.libs/libvlccore.dll /output/ && \
         cp -r /vlc/win64/modules /output/"
```

---

## 踩坑记录

### 问题 1: SHA512 校验和失败

**现象：**
```
make: *** [../src/main.mak:726: .sum-aribb24] Error 1
```

**原因：** VLC 源码中的 contribs 校验和与上游第三方库不匹配（上游库已更新）。

**解决方案：** 使用精确匹配 VLC 源码 commit 的 contribs：

```bash
VLC_PREBUILT_CONTRIBS_URL="https://artifacts.videolan.org/vlc-3.0/win64/vlc-contrib-x86_64-w64-mingw32-<MATCHING_CONTRIB_SHA>.tar.bz2"
```

contribs SHA 必须与 VLC 源码 commit 匹配，可在 VLC 官方 CI 配置或发布物中找到。

---

### 问题 2: FFmpeg API 版本不兼容

**现象：**
```
error: 'FF_PROFILE_AV1_MAIN' undeclared
error: 'AV_CODEC_ID_ATRAC9' undeclared
```

**原因：** contribs 中的 FFmpeg 版本与 VLC 源码期望的 API 不匹配。

**解决方案：**
1. 使用与 VLC 源码 commit 精确匹配的 contribs
2. 确保 Docker 镜像版本与 VLC 版本兼容

---

### 问题 3: DXGI/D3D 头文件不兼容

**现象：**
```
error: unknown type name 'DXGI_COLOR_SPACE_TYPE'
```

**原因：** 新版 Docker 镜像的 mingw-w64 头文件与 VLC 3.0.x 源码不兼容。

**解决方案：** 使用 VLC 官方提供的 `vlc-debian-win64-3.0` 专用镜像，而非通用的 `vlc-debian-win64-posix`。

---

### 问题 4: Docker Hub 认证失败

**现象：**
```
failed to fetch anonymous token: Get "https://auth.docker.io/token?..." 
wsarecv: An existing connection was forcibly closed
```

**原因：** Docker Desktop 代理配置不正确或网络问题。

**解决方案：**
1. 在 Docker Desktop 设置中配置代理
2. 或手动拉取基础镜像：`docker pull debian:bullseye-20251117-slim`

---

### 问题 5: Debian 包镜像连接失败

**现象：**
```
E: Failed to fetch http://deb.debian.org/... Unable to connect to deb.debian.org
```

**原因：** Docker 容器内网络无法访问 Debian 镜像站。

**解决方案：**
1. 配置 Docker Desktop 容器内代理
2. 或等待网络恢复后重试

---

### 问题 6: Git dubious ownership

**现象：**
```
fatal: detected dubious ownership in repository
```

**原因：** Windows 文件权限问题。

**解决方案：**
```bash
git config --global --add safe.directory /vlc
```

---

### 问题 7: FAAD 库未找到

**现象：**
```
configure: error: cannot find FAAD library
```

**原因：** 旧版 Docker 镜像缺少必要的音频编解码器依赖。

**解决方案：** 使用新版 `vlc-debian-win64-3.0` 镜像（2025年12月版本）。

---

### 问题 8: NSIS 安装程序创建失败

**现象：**
```
File: "vlc.exe" -> no files found
Error in script "vlc.win32.nsi"
```

**原因：** 使用 `-z`（libvlc only）模式时不需要安装程序，但构建脚本仍尝试创建。

**解决方案：** 忽略此错误。libvlc.dll 已经成功构建，可直接使用 `win64/lib/.libs/libvlc.dll`。

---

## 复现脚本

### 自动构建脚本

```bash
#!/bin/bash
# build-libvlc.sh - LibVLC Windows 交叉编译自动化脚本

set -e

#============ 配置区域 ============
VLC_REPO="https://code.videolan.org/videolan/vlc.git"
DOCKER_IMAGE_REPO="https://code.videolan.org/videolan/docker-images.git"
VLC_COMMIT="2a48cfe344b792161ff47caf26d78f4661587bab"
CONTRIB_SHA="2a48cfe344b792161ff47caf26d78f4661587bab"
CONTRIB_URL="https://artifacts.videolan.org/vlc-3.0/win64/vlc-contrib-x86_64-w64-mingw32-${CONTRIB_SHA}.tar.bz2"
DOCKER_IMAGE_NAME="vlc-win64-3.0-local"
#================================

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
VLC_DIR="${WORK_DIR}/vlc-build"
OUTPUT_DIR="${WORK_DIR}/output"
DOCKER_DIR="${WORK_DIR}/docker-images"

echo "=== LibVLC Windows Build Script ==="
echo "VLC Commit: ${VLC_COMMIT}"
echo "Contrib SHA: ${CONTRIB_SHA}"
echo ""

# 步骤 1: 构建 Docker 镜像
echo "[1/5] Building Docker image..."
if docker image inspect "${DOCKER_IMAGE_NAME}" > /dev/null 2>&1; then
    echo "Docker image already exists, skipping build"
else
    if [ ! -d "${DOCKER_DIR}" ]; then
        echo "Cloning docker-images repo..."
        git clone "${DOCKER_IMAGE_REPO}" "${DOCKER_DIR}"
    fi
    cd "${DOCKER_DIR}/vlc-debian-win64-3.0"
    docker build -t "${DOCKER_IMAGE_NAME}" .
    cd "${WORK_DIR}"
fi

# 步骤 2: 克隆/更新 VLC 源码
echo "[2/5] Cloning VLC source..."
if [ -d "${VLC_DIR}" ]; then
    rm -rf "${VLC_DIR}"
fi
git clone "${VLC_REPO}" "${VLC_DIR}"
cd "${VLC_DIR}"
git fetch origin "${VLC_COMMIT}"
git checkout "${VLC_COMMIT}"

# 步骤 3: 创建输出目录
echo "[3/5] Preparing output directory..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# 步骤 4: 执行构建
echo "[4/5] Building VLC..."
docker run --rm \
    -v "${VLC_DIR}:/vlc" \
    -v "${OUTPUT_DIR}:/output" \
    -e VLC_PREBUILT_CONTRIBS_URL="${CONTRIB_URL}" \
    "${DOCKER_IMAGE_NAME}" \
    sh -c "git config --global --add safe.directory /vlc && \
           cd /vlc && \
           ./extras/package/win32/build.sh -z -r -p"

# 步骤 5: 复制构建产物
echo "[5/5] Copying build artifacts..."
docker run --rm \
    -v "${VLC_DIR}:/vlc" \
    -v "${OUTPUT_DIR}:/output" \
    "${DOCKER_IMAGE_NAME}" \
    sh -c "cp /vlc/win64/lib/.libs/libvlc.dll /output/ && \
           cp /vlc/win64/src/.libs/libvlccore.dll /output/ && \
           cp -r /vlc/win64/modules /output/"

echo ""
echo "=== Build Complete ==="
echo "Output directory: ${OUTPUT_DIR}"
echo ""
echo "Artifacts:"
ls -lh "${OUTPUT_DIR}"/*.dll
```

### 使用方法

```bash
# 设置执行权限
chmod +x build-libvlc.sh

# 运行脚本
./build-libvlc.sh
```

### 验证构建产物

```bash
# 检查 libvlc.dll
ls -lh output/libvlc.dll

# 检查可用插件数量
ls output/modules/*.dll | wc -l

# 检查关键解码器
ls output/modules/*avcodec*.dll
ls output/modules/*faad*.dll
```

---

## 附录

### 关键 VLC Commit 与 Contribs SHA 对照表

| VLC Commit | VLC 版本 | Contribs SHA |
|------------|----------|--------------|
| 2a48cfe344b792161ff47caf26d78f4661587bab | 3.0.x | 2a48cfe344b792161ff47caf26d78f4661587bab |
| 578d28f6c9 | 3.0.23 | 578d28f6c9f2379164516e689418f92ac74a3445 |

### VLC 官方 Docker 镜像

| 镜像 | 用途 |
|------|------|
| `registry.videolan.org/vlc-debian-win64-posix` | 最新版 VLC（推荐） |
| `registry.videolan.org/vlc-debian-win64-3.0` | VLC 3.0.x 专用 |
| `registry.videolan.org/vlc-debian-llvm-msvcrt` | Clang 构建 |

### 镜像标签查询

```bash
# 查询可用标签
curl -s "https://registry.videolan.org/v2/vlc-debian-win64-3.0/tags/list"
```

### 构建产物说明

| 文件/目录 | 说明 |
|----------|------|
| `libvlc.dll` | 主库入口 |
| `libvlccore.dll` | 核心编解码库 |
| `modules/` | 插件目录（包含所有解码器、滤镜等）|

### 在应用程序中使用

```c
#include <vlc/vlc.h>

int main(int argc, char* argv[]) {
    libvlc_instance_t *vlc;
    libvlc_media_player_t *mp;

    // 初始化 libvlc
    vlc = libvlc_new(argc, argv);
    if (vlc == NULL) {
        return 1;
    }

    // 创建媒体播放器
    mp = libvlc_media_player_new(vlc);
    
    // 设置媒体源
    libvlc_media_t *media = libvlc_media_new_location(vlc, "file://video.mp4");
    libvlc_media_player_set_media(mp, media);

    // 播放
    libvlc_media_player_play(mp);

    // 等待播放
    Sleep(10000);

    // 清理
    libvlc_media_player_release(mp);
    libvlc_release(vlc);

    return 0;
}
```

### 编译链接

```bash
# 链接 libvlc
x86_64-w64-mingw32-gcc -o myplayer.exe myplayer.c \
    -lvlc -L./output \
    -I./include
```
