# LibVLC Windows Build

为 Windows x86_64 平台交叉编译 VideoLAN 的 libvlc.dll 库。

## 目录结构

```
LibVLC/
├── build-libvlc.sh           # Windows 自动构建脚本
├── build-libvlc-macos.sh     # macOS 自动构建脚本
├── verify-build.sh           # 构建产物验证脚本
├── docs/
│   └── build-libvlc.md   # 完整构建文档
├── output/                    # Windows 构建产物（构建后生成）
│   ├── libvlc.dll        # 主库入口
│   ├── libvlccore.dll   # 核心编解码库
│   └── modules/          # 插件目录
├── output-macos/               # macOS 构建产物（构建后生成）
│   ├── libvlc.dylib     # 主库 (Universal Binary)
│   └── modules/          # 插件目录
├── vlc-build/            # VLC 源码（构建后生成）
└── docker-images/        # VLC Docker 镜像定义（构建后生成）
```

## 快速开始

### 方式 1: 使用自动脚本

```bash
# 设置执行权限
chmod +x build-libvlc.sh verify-build.sh

# 执行构建
./build-libvlc.sh

# 验证构建产物
./verify-build.sh
```

### 方式 2: Docker 镜像方式

```bash
# 1. 构建 Docker 镜像
cd docker-images/vlc-debian-win64-3.0
docker build -t vlc-win64-3.0-local .

# 2. 克隆 VLC 源码
git clone https://code.videolan.org/videolan/vlc.git
cd vlc
git checkout <commit-hash>

# 3. 构建
docker run --rm \
    -v "$(pwd):/vlc" \
    -v "$(pwd)/../output:/output" \
    -e VLC_PREBUILT_CONTRIBS_URL="https://artifacts.videolan.org/..." \
    vlc-win64-3.0-local \
    sh -c "cd /vlc && ./extras/package/win32/build.sh -z -r -p"
```

## macOS 构建

为 macOS x86_64 + arm64 (Universal Binary) 构建 libvlc.dylib。

### 环境要求

| 软件 | 版本 | 说明 |
|------|------|------|
| macOS | 13+ (Ventura) | 原生构建环境 |
| Xcode | Latest | 编译器工具链 |
| Git | Latest | 源码管理 |

### 构建步骤

```bash
# 设置执行权限
chmod +x build-libvlc-macos.sh

# 执行构建 (需要 macOS 环境)
./build-libvlc-macos.sh
```

### 构建产物

| 文件 | 说明 |
|------|------|
| `libvlc.dylib` | libVLC 主库 (Universal Binary, arm64 + x86_64) |
| `modules/*.dylib` | 插件目录 |

### GitHub Actions

macOS 构建通过 GitHub Actions 自动执行。使用 `macos-latest` runner 原生构建。

### 跨平台使用

```bash
# 编译链接
clang -o myapp myapp.c \
    -lvlc -L./output-macos -I./include
```

注意: macOS 版 libvlc.dylib 是 Universal Binary，可同时在 Intel 和 Apple Silicon Mac 上运行。

## 构建产物

| 文件 | 说明 | 大小 |
|------|------|------|
| `libvlc.dll` | libVLC 主库入口点 | ~600 KB |
| `libvlccore.dll` | 核心编解码库 | ~6 MB |
| `modules/*.dll` | 插件（解码器、滤镜、输出等） | ~200+ 个 |

## 使用示例

```c
#include <vlc/vlc.h>

int main(int argc, char* argv[]) {
    libvlc_instance_t *vlc = libvlc_new(argc, argv);
    if (vlc == NULL) return 1;

    libvlc_media_player_t *mp = libvlc_media_player_new(vlc);
    libvlc_media_t *media = libvlc_media_new_location(vlc, "file://video.mp4");
    libvlc_media_player_set_media(mp, media);
    libvlc_media_player_play(mp);

    // ...
    libvlc_media_player_release(mp);
    libvlc_release(vlc);
    return 0;
}
```

## 编译链接

```bash
x86_64-w64-mingw32-gcc -o myplayer.exe myplayer.c \
    -lvlc -L./output \
    -I./include
```

## 踩坑记录

详见 [docs/build-libvlc.md](docs/build-libvlc.md#踩坑记录)

主要问题：
1. SHA512 校验和不匹配 → 使用精确匹配的 contribs
2. FFmpeg API 版本不兼容 → 使用匹配的 Docker 镜像
3. Docker Hub 连接问题 → 配置代理或使用加速器
4. Git 权限问题 → 配置 safe.directory

## 参考链接

- [VLC 官方文档](https://code.videolan.org/videolan/vlc/-/blob/master/doc/BUILD-win32.md)
- [VLC Docker 镜像](https://code.videolan.org/videolan/docker-images)
- [VideoLAN 镜像站](https://artifacts.videolan.org)
