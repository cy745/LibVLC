#!/bin/bash
#===============================================================================
# LibVLC Windows 交叉编译自动化脚本
#
# 功能: 为 Windows x86_64 平台构建 libvlc.dll
# 依赖: Docker Desktop, Git
# 产出: libvlc.dll, libvlccore.dll, modules/
#===============================================================================

set -e

#------------------------------ 配置区域 --------------------------------
VLC_REPO="https://code.videolan.org/videolan/vlc.git"
DOCKER_IMAGE_REPO="https://code.videolan.org/videolan/docker-images.git"

# VLC 源码 commit (必须是 3.0.x 分支)
# 推荐使用 3.0.x HEAD 或已知稳定的 commit
VLC_COMMIT="${VLC_COMMIT:-2d8e0f8cf5935dca3917ce015299eb91480d8167}"

# 与 VLC commit 匹配的 contribs SHA
# 重要: contribs SHA 是更新 FFmpeg 等依赖的 commit SHA，不是 VLC 主库 commit
# 获取方式: https://code.videolan.org/videolan/vlc/-/commits/3.0.x (查找 contrib 相关提交)
# 或查看 artifacts.videolan.org/vlc-3.0/win64/ 获取最新的 contribs 包
CONTRIB_SHA="${CONTRIB_SHA:-4ca2c80e9a79293ceac7d640ab7963c3b000c370}"
CONTRIB_URL="https://artifacts.videolan.org/vlc-3.0/win64/vlc-contrib-x86_64-w64-mingw32-${CONTRIB_SHA}.tar.bz2"

# Docker 镜像名称
DOCKER_IMAGE_NAME="vlc-win64-3.0-local"

# 构建选项
BUILD_FLAGS="-z -r -p"  # -z: libvlc only, -r: release, -p: prebuilt contribs
#------------------------------ 配置区域 --------------------------------

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${SCRIPT_DIR}"
VLC_DIR="${WORK_DIR}/vlc-build"
OUTPUT_DIR="${WORK_DIR}/output"
DOCKER_DIR="${WORK_DIR}/docker-images"

# Windows Docker Desktop 路径处理
# Docker Desktop 会自动处理路径转换，直接使用 Unix 风格路径
# 注意: 不要在这里用 cygpath -w，MSYS 会错误地添加 ;C 后缀
if [ -d /c ] || [ -d /mnt/c ]; then
    VLC_DIR_WIN="${VLC_DIR}"
    OUTPUT_DIR_WIN="${OUTPUT_DIR}"
else
    VLC_DIR_WIN="${VLC_DIR}"
    OUTPUT_DIR_WIN="${OUTPUT_DIR}"
fi

echo "============================================================================"
echo "  LibVLC Windows Build Script"
echo "============================================================================"
echo "VLC Commit:  ${VLC_COMMIT}"
echo "Contrib SHA: ${CONTRIB_SHA}"
echo "VLC Dir:     ${VLC_DIR}"
echo "VLC Dir (Win): ${VLC_DIR_WIN}"
echo "Output:      ${OUTPUT_DIR}"
echo "Output (Win): ${OUTPUT_DIR_WIN}"
echo "============================================================================"
echo ""

#-------------------------------------------------------------------------------
# 步骤 1: 检查环境
#-------------------------------------------------------------------------------
log_info "[1/5] Checking environment..."

# 检查 Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker not found. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# 检查 Git
if ! command -v git &> /dev/null; then
    log_error "Git not found."
    exit 1
fi

log_info "Environment check passed"

#-------------------------------------------------------------------------------
# 步骤 2: 构建/检查 Docker 镜像
#-------------------------------------------------------------------------------
log_info "[2/5] Preparing Docker image..."

if docker image inspect "${DOCKER_IMAGE_NAME}" &> /dev/null; then
    log_info "Docker image '${DOCKER_IMAGE_NAME}' already exists, skipping build"
else
    log_info "Building Docker image '${DOCKER_IMAGE_NAME}'..."

    # 克隆 docker-images 仓库
    if [ ! -d "${DOCKER_DIR}" ]; then
        log_info "Cloning docker-images repository..."
        git clone "${DOCKER_IMAGE_REPO}" "${DOCKER_DIR}"
    fi

    # 构建镜像
    cd "${DOCKER_DIR}/vlc-debian-win64-3.0"
    DOCKER_BUILDKIT=0 docker build -t "${DOCKER_IMAGE_NAME}" .

    cd "${WORK_DIR}"
    log_info "Docker image build complete"
fi

#-------------------------------------------------------------------------------
# 步骤 3: 克隆 VLC 源码
#-------------------------------------------------------------------------------
log_info "[3/5] Cloning VLC source..."

# 清理旧目录
if [ -d "${VLC_DIR}" ]; then
    log_info "Removing old VLC directory..."
    rm -rf "${VLC_DIR}"
fi

log_info "Cloning VLC from ${VLC_REPO}..."
git clone "${VLC_REPO}" "${VLC_DIR}"

cd "${VLC_DIR}"
log_info "Checking out commit ${VLC_COMMIT}..."
git fetch origin "${VLC_COMMIT}"
git checkout "${VLC_COMMIT}"

VLC_VERSION=$(git describe --tags 2>/dev/null || echo "unknown")
log_info "VLC version: ${VLC_VERSION}"

cd "${WORK_DIR}"

#-------------------------------------------------------------------------------
# 步骤 4: 准备输出目录
#-------------------------------------------------------------------------------
log_info "[4/5] Preparing output directory..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

#-------------------------------------------------------------------------------
# 步骤 5: 执行构建
#-------------------------------------------------------------------------------
log_info "[5/5] Building VLC..."
log_info "Using contribs: ${CONTRIB_URL}"

docker run --rm \
    -v "${VLC_DIR_WIN}:/vlc" \
    -v "${OUTPUT_DIR_WIN}:/output" \
    -e VLC_PREBUILT_CONTRIBS_URL="${CONTRIB_URL}" \
    "${DOCKER_IMAGE_NAME}" \
    sh -c "git config --global --add safe.directory /vlc && \
           cd /vlc && \
           ./extras/package/win32/build.sh ${BUILD_FLAGS} || true"

#-------------------------------------------------------------------------------
# 步骤 6: 复制构建产物
#-------------------------------------------------------------------------------
log_info "Copying build artifacts..."

docker run --rm \
    -v "${VLC_DIR_WIN}:/vlc" \
    -v "${OUTPUT_DIR_WIN}:/output" \
    "${DOCKER_IMAGE_NAME}" \
    sh -c "cp /vlc/win64/lib/.libs/libvlc.dll /output/ && \
           cp /vlc/win64/src/.libs/libvlccore.dll /output/ && \
           mkdir -p /output/modules && \
           find /vlc/win64/modules -name '*.dll' -exec cp {} /output/modules/ \;"

#-------------------------------------------------------------------------------
# 完成
#-------------------------------------------------------------------------------
echo ""
echo "============================================================================"
echo -e "${GREEN}Build Complete!${NC}"
echo "============================================================================"
echo ""
echo "Output directory: ${OUTPUT_DIR}"
echo ""
echo "Artifacts:"
echo "  libvlc.dll      ($(du -h "${OUTPUT_DIR}/libvlc.dll" | cut -f1))"
echo "  libvlccore.dll  ($(du -h "${OUTPUT_DIR}/libvlccore.dll" | cut -f1))"
echo "  modules/        ($(du -sh "${OUTPUT_DIR}/modules" | cut -f1))"
echo ""

# 列出关键 DLL
if [ -d "${OUTPUT_DIR}/modules" ]; then
    MODULE_COUNT=$(ls "${OUTPUT_DIR}/modules"/*.dll 2>/dev/null | wc -l)
    echo "Plugin count: ${MODULE_COUNT}"

    # 检查关键解码器
    echo ""
    echo "Key codecs:"
    ls "${OUTPUT_DIR}/modules/"*avcodec*.dll 2>/dev/null | head -3 | xargs -I{} basename {}
    ls "${OUTPUT_DIR}/modules/"*faad*.dll 2>/dev/null | head -2 | xargs -I{} basename {}
fi

echo ""
echo "============================================================================"
echo "  Next Steps"
echo "============================================================================"
echo ""
echo "1. Copy the output files to your Windows application directory"
echo ""
echo "2. Include the modules/ directory alongside libvlc.dll"
echo ""
echo "3. Link your application with:"
echo "   - libvlc.dll"
echo "   - libvlccore.dll"
echo ""
echo "4. Example compilation:"
echo "   x86_64-w64-mingw32-gcc -o myapp.exe myapp.c \\"
echo "       -lvlc -L./output -I./include"
echo ""
