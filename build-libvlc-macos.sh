#!/bin/bash
#===============================================================================
# LibVLC macOS Native Build Script
#
# 功能: 为 macOS x86_64 + arm64 (Universal Binary) 构建 libvlc.dylib
# 依赖: macOS, Xcode, Git
# 产出: libvlc.dylib (Universal Binary), modules/
#===============================================================================

set -e

#------------------------------ 配置区域 --------------------------------
VLC_REPO="https://code.videolan.org/videolan/vlc.git"

# VLC 源码 commit (必须是 3.0.x 分支)
VLC_COMMIT="${VLC_COMMIT:-2d8e0f8cf5935dca3917ce015299eb91480d8167}"

# 与 VLC commit 匹配的 contribs SHA
CONTRIB_SHA="${CONTRIB_SHA:-4ca2c80e9a79293ceac7d640ab7963c3b000c370}"

# macOS 部署目标 (D-01: Minimum macOS 13 Ventura)
MACOSX_DEPLOYMENT_TARGET=13
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
OUTPUT_DIR="${WORK_DIR}/output-macos"

echo "============================================================================"
echo "  LibVLC macOS Build Script (Universal Binary)"
echo "============================================================================"
echo "VLC Commit:  ${VLC_COMMIT}"
echo "Contrib SHA: ${CONTRIB_SHA}"
echo "macOS Target: ${MACOSX_DEPLOYMENT_TARGET}"
echo "Architectures: x86_64, arm64"
echo "Output:      ${OUTPUT_DIR}"
echo "============================================================================"
echo ""

#-------------------------------------------------------------------------------
# 步骤 1: 检查环境
#-------------------------------------------------------------------------------
log_info "[1/5] Checking environment..."

if [[ "$OSTYPE" != "darwin"* ]]; then
    log_warn "Not running on macOS. Native macOS build requires macOS environment."
    log_warn "For CI/CD, use GitHub Actions with macos-latest runner."
fi

if ! command -v xcodebuild &> /dev/null; then
    log_error "Xcode not found. Please install Xcode from App Store."
    exit 1
fi

if ! command -v git &> /dev/null; then
    log_error "Git not found."
    exit 1
fi

if ! command -v xcrun &> /dev/null; then
    log_error "xcrun not found. This is a macOS-only tool."
    exit 1
fi

log_info "Environment check passed"

#-------------------------------------------------------------------------------
# 步骤 2: 克隆 VLC 源码并 checkout
#-------------------------------------------------------------------------------
log_info "[2/5] Preparing VLC source..."

VLC_DIR="${WORK_DIR}/vlc-build"
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

#-------------------------------------------------------------------------------
# 步骤 3: 构建 x86_64
#-------------------------------------------------------------------------------
log_info "[3/5] Building VLC for x86_64..."

rm -rf build
mkdir build
cd build

export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}"
export VLC_FORCE_KERNELVERSION=18
export VLC_PREBUILT_CONTRIBS_URL="https://artifacts.videolan.org/vlc-3.0/macos-x86_64/vlc-contrib-x86_64-apple-darwin18-${CONTRIB_SHA}.tar.bz2"

log_info "VLC_FORCE_KERNELVERSION=${VLC_FORCE_KERNELVERSION}"
log_info "VLC_PREBUILT_CONTRIBS_URL=${VLC_PREBUILT_CONTRIBS_URL}"

../extras/package/macosx/build.sh -a x86_64 || {
    log_error "Build for x86_64 failed"
    exit 1
}

log_info "Build for x86_64 complete"

# 提取 x86_64 产物
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/x86_64"
cp -r lib "${OUTPUT_DIR}/x86_64/"
cp -r modules "${OUTPUT_DIR}/x86_64/" 2>/dev/null || true
cp -r bin "${OUTPUT_DIR}/x86_64/" 2>/dev/null || true

cd ..

#-------------------------------------------------------------------------------
# 步骤 4: 构建 arm64
#-------------------------------------------------------------------------------
log_info "[4/5] Building VLC for arm64..."

rm -rf build
mkdir build
cd build

export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}"
export VLC_FORCE_KERNELVERSION=19
export VLC_PREBUILT_CONTRIBS_URL="https://artifacts.videolan.org/vlc-3.0/macos-arm64/vlc-contrib-aarch64-apple-darwin19-${CONTRIB_SHA}.tar.bz2"

log_info "VLC_FORCE_KERNELVERSION=${VLC_FORCE_KERNELVERSION}"
log_info "VLC_PREBUILT_CONTRIBS_URL=${VLC_PREBUILT_CONTRIBS_URL}"

../extras/package/macosx/build.sh -a aarch64 || {
    log_error "Build for arm64 failed"
    exit 1
}

log_info "Build for arm64 complete"

# 提取 arm64 产物
mkdir -p "${OUTPUT_DIR}/arm64"
cp -r lib "${OUTPUT_DIR}/arm64/"
cp -r modules "${OUTPUT_DIR}/arm64/" 2>/dev/null || true
cp -r bin "${OUTPUT_DIR}/arm64/" 2>/dev/null || true

cd ..

#-------------------------------------------------------------------------------
# 步骤 5: 合并为 Universal Binary
#-------------------------------------------------------------------------------
log_info "[5/5] Creating Universal Binary..."

# 找到两个架构的 libvlc.dylib
X86_64_LIB=$(find "${OUTPUT_DIR}/x86_64" -name "libvlc.dylib" | head -1)
ARM64_LIB=$(find "${OUTPUT_DIR}/arm64" -name "libvlc.dylib" | head -1)

if [ -z "${X86_64_LIB}" ] || [ -z "${ARM64_LIB}" ]; then
    log_error "libvlc.dylib not found for one or both architectures"
    log_error "x86_64: ${X86_64_LIB}"
    log_error "arm64: ${ARM64_LIB}"
    exit 1
fi

log_info "x86_64 libvlc.dylib: ${X86_64_LIB}"
log_info "arm64 libvlc.dylib: ${ARM64_LIB}"

# 合并为 Universal Binary
lipo -create -output "${OUTPUT_DIR}/libvlc.dylib" "${X86_64_LIB}" "${ARM64_LIB}"

log_info "Universal Binary created: ${OUTPUT_DIR}/libvlc.dylib"
lipo -info "${OUTPUT_DIR}/libvlc.dylib"

# 清理中间目录
rm -rf "${OUTPUT_DIR}/x86_64" "${OUTPUT_DIR}/arm64"

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
if [ -f "${OUTPUT_DIR}/libvlc.dylib" ]; then
    echo "  libvlc.dylib   ($(du -h "${OUTPUT_DIR}/libvlc.dylib" | cut -f1)) - Universal Binary"
fi
if [ -d "${OUTPUT_DIR}/modules" ]; then
    MODULE_COUNT=$(ls "${OUTPUT_DIR}/modules"/*.dylib 2>/dev/null | wc -l | tr -d ' ')
    echo "  modules/       (${MODULE_COUNT} modules)"
fi
echo ""
echo "Binary architectures:"
lipo -info "${OUTPUT_DIR}/libvlc.dylib"
echo ""
echo "============================================================================"
echo "  Next Steps"
echo "============================================================================"
echo ""
echo "1. Copy libvlc.dylib and modules/ to your macOS application"
echo ""
echo "2. Link your application with:"
echo "   clang -o myapp myapp.c -lvlc -L./output-macos -I./include"
echo ""
