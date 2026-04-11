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
# 注意: macOS 没有预编译 contribs，需要从源码构建
CONTRIB_SHA="${CONTRIB_SHA:-4ca2c80e9a79293ceac7d640ab7963c3b000c370}"

# macOS 部署目标 (D-01: Minimum macOS 13 Ventura)
MACOSX_DEPLOYMENT_TARGET=13

# 构建架构 (D-02: Universal Binary)
ARCHS="arm64 x86_64"
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
echo "Architectures: ${ARCHS}"
echo "Output:      ${OUTPUT_DIR}"
echo "============================================================================"
echo ""

#-------------------------------------------------------------------------------
# 步骤 1: 检查环境
#-------------------------------------------------------------------------------
log_info "[1/6] Checking environment..."

# 检查 macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_warn "Not running on macOS. Native macOS build requires macOS environment."
    log_warn "For CI/CD, use GitHub Actions with macos-latest runner."
fi

# 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    log_error "Xcode not found. Please install Xcode from App Store."
    exit 1
fi

# 检查 Git
if ! command -v git &> /dev/null; then
    log_error "Git not found."
    exit 1
fi

# 检查 xcrun (macOS SDK 工具)
if ! command -v xcrun &> /dev/null; then
    log_error "xcrun not found. This is a macOS-only tool."
    exit 1
fi

log_info "Environment check passed"

#-------------------------------------------------------------------------------
# 步骤 2: 清理旧目录并克隆 VLC 源码
#-------------------------------------------------------------------------------
log_info "[2/6] Preparing VLC source..."

for arch in ${ARCHS}; do
    VLC_DIR="${WORK_DIR}/vlc-build-${arch}"
    if [ -d "${VLC_DIR}" ]; then
        log_info "Removing old VLC directory for ${arch}..."
        rm -rf "${VLC_DIR}"
    fi
done

# 只克隆一次，然后在每个架构目录中 checkout
VLC_DIR_BASE="${WORK_DIR}/vlc-build-base"
if [ -d "${VLC_DIR_BASE}" ]; then
    log_info "Using existing VLC source directory..."
else
    log_info "Cloning VLC from ${VLC_REPO}..."
    git clone "${VLC_REPO}" "${VLC_DIR_BASE}"
fi

cd "${VLC_DIR_BASE}"
log_info "Checking out commit ${VLC_COMMIT}..."
git fetch origin "${VLC_COMMIT}"
git checkout "${VLC_COMMIT}"

VLC_VERSION=$(git describe --tags 2>/dev/null || echo "unknown")
log_info "VLC version: ${VLC_VERSION}"

# 为每个架构创建单独的 build 目录
for arch in ${ARCHS}; do
    VLC_DIR="${WORK_DIR}/vlc-build-${arch}"
    if [ ! -d "${VLC_DIR}" ]; then
        log_info "Creating build directory for ${arch}..."
        cp -r "${VLC_DIR_BASE}" "${VLC_DIR}"
    fi
done

#-------------------------------------------------------------------------------
# 步骤 3: 准备输出目录
#-------------------------------------------------------------------------------
log_info "[3/6] Preparing output directory..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

#-------------------------------------------------------------------------------
# 步骤 4: 为每个架构构建 VLC
#-------------------------------------------------------------------------------
log_info "[4/6] Building VLC for each architecture..."

for arch in ${ARCHS}; do
    VLC_DIR="${WORK_DIR}/vlc-build-${arch}"
    log_info "----------------------------------------"
    log_info "Building VLC for ${arch}..."
    log_info "----------------------------------------"

    cd "${VLC_DIR}"

    # 设置环境变量
    export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}"
    export EXTRA_CFLAGS="-arch ${arch}"
    export EXTRA_LDFLAGS="-arch ${arch}"

    # 执行构建
    # -a: 架构
    # -c: 从源码构建 contribs (必须，因为 Darwin24 预编译 contribs 不存在，404)
    # -r: release 模式 (rebuild tools + contribs + vlc)
    ./extras/package/macosx/build.sh -a "${arch}" -c -r || {
        log_error "Build for ${arch} failed"
        exit 1
    }

    log_info "Build for ${arch} complete"
done

#-------------------------------------------------------------------------------
# 步骤 5: 合并为 Universal Binary
#-------------------------------------------------------------------------------
log_info "[5/6] Creating Universal Binary (arm64 + x86_64)..."

cd "${WORK_DIR}"

# 检查每个架构的构建产物
for arch in ${ARCHS}; do
    VLC_DIR="${WORK_DIR}/vlc-build-${arch}"
    if [ -f "${VLC_DIR}/lib/.libs/libvlc.dylib" ]; then
        log_info "Found libvlc.dylib for ${arch}: $(lipo -info "${VLC_DIR}/lib/.libs/libvlc.dylib" 2>&1 || echo 'unknown')"
    else
        log_error "libvlc.dylib not found for ${arch} at ${VLC_DIR}/lib/.libs/libvlc.dylib"
        exit 1
    fi
done

# 使用 lipo 合并
lipo -create -output "${OUTPUT_DIR}/libvlc.dylib" \
    "${WORK_DIR}/vlc-build-arm64/lib/.libs/libvlc.dylib" \
    "${WORK_DIR}/vlc-build-x86_64/lib/.libs/libvlc.dylib"

log_info "Universal Binary created: ${OUTPUT_DIR}/libvlc.dylib"
lipo -info "${OUTPUT_DIR}/libvlc.dylib"

#-------------------------------------------------------------------------------
# 步骤 6: 复制 modules 目录
#-------------------------------------------------------------------------------
log_info "[6/6] Copying modules..."

# 从 x86_64 构建中复制 modules (arm64 构建也有相同的 modules)
if [ -d "${WORK_DIR}/vlc-build-x86_64/modules" ]; then
    cp -r "${WORK_DIR}/vlc-build-x86_64/modules" "${OUTPUT_DIR}/"
    MODULE_COUNT=$(ls "${OUTPUT_DIR}/modules"/*.dylib 2>/dev/null | wc -l | tr -d ' ')
    log_info "Copied ${MODULE_COUNT} modules"
else
    log_warn "modules directory not found"
fi

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
echo "  libvlc.dylib   ($(du -h "${OUTPUT_DIR}/libvlc.dylib" | cut -f1)) - Universal Binary"
echo "  modules/       ($(du -sh "${OUTPUT_DIR}/modules" 2>/dev/null | cut -f1))"
echo ""
echo "Binary architectures:"
lipo -info "${OUTPUT_DIR}/libvlc.dylib"
echo ""

#-------------------------------------------------------------------------------
# 清理临时文件
#-------------------------------------------------------------------------------
log_info "Cleaning up base build directory..."
rm -rf "${VLC_DIR_BASE}" 2>/dev/null || true

echo ""
echo "============================================================================"
echo "  Next Steps"
echo "============================================================================"
echo ""
echo "1. Copy the output files to your macOS application directory"
echo ""
echo "2. Include the modules/ directory alongside libvlc.dylib"
echo ""
echo "3. Link your application with:"
echo "   - libvlc.dylib"
echo "   - libvlccore.dylib (if needed)"
echo ""
echo "4. Example compilation:"
echo "   clang -o myapp myapp.c \"
echo "       -lvlc -L./output-macos -I./include"
echo ""
