#!/bin/bash
#===============================================================================
# LibVLC macOS Native Build Script
#
# 功能: 为 macOS 构建 libvlc.dylib
# 依赖: macOS, Xcode, Git
# 产出: libvlc.dylib, modules/
#
# 用法:
#   ./build-libvlc-macos.sh --arch arm64    # 只构建 arm64
#   ./build-libvlc-macos.sh --arch x86_64  # 只构建 x86_64
#   ./build-libvlc-macos.sh                 # 构建两个架构并合并为 Universal Binary
#===============================================================================

set -e

#------------------------------ 解析参数 --------------------------------
BUILD_ARCHS=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --arch)
            BUILD_ARCHS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

BUILD_ARCHS="${BUILD_ARCHS:-arm64 x86_64}"

#------------------------------ 配置区域 --------------------------------
VLC_REPO="https://code.videolan.org/videolan/vlc.git"
VLC_COMMIT="${VLC_COMMIT:-2d8e0f8cf5935dca3917ce015299eb91480d8167}"
CONTRIB_SHA="${CONTRIB_SHA:-4ca2c80e9a79293ceac7d640ab7963c3b000c370}"
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${WORK_DIR}/output-macos"

echo "============================================================================"
echo "  LibVLC macOS Build Script"
echo "============================================================================"
echo "VLC Commit:  ${VLC_COMMIT}"
echo "Contrib SHA: ${CONTRIB_SHA}"
echo "macOS Target: ${MACOSX_DEPLOYMENT_TARGET}"
echo "Architectures: ${BUILD_ARCHS}"
echo "Output:      ${OUTPUT_DIR}"
echo "============================================================================"
echo ""

#-------------------------------------------------------------------------------
# 步骤 1: 检查环境
#-------------------------------------------------------------------------------
log_info "[1/5] Checking environment..."

if [[ "$OSTYPE" != "darwin"* ]]; then
    log_warn "Not running on macOS."
fi

if ! command -v xcodebuild &> /dev/null; then
    log_error "Xcode not found."
    exit 1
fi

if ! command -v git &> /dev/null; then
    log_error "Git not found."
    exit 1
fi

if ! command -v xcrun &> /dev/null; then
    log_error "xcrun not found."
    exit 1
fi

log_info "Environment check passed"

#-------------------------------------------------------------------------------
# 步骤 2: 克隆 VLC 源码
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
# 步骤 3: 构建各架构
#-------------------------------------------------------------------------------
log_info "[3/5] Building VLC for each architecture..."

for arch in ${BUILD_ARCHS}; do
    log_info "----------------------------------------"
    log_info "Building VLC for ${arch}..."
    log_info "----------------------------------------"

    rm -rf build
    mkdir build
    cd build

    export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}"

    if [ "${arch}" = "arm64" ]; then
        export VLC_FORCE_KERNELVERSION=19
        export VLC_PREBUILT_CONTRIBS_URL="https://artifacts.videolan.org/vlc-3.0/macos-arm64/vlc-contrib-aarch64-apple-darwin19-${CONTRIB_SHA}.tar.bz2"
        BUILD_ARG="aarch64"
    else
        # x86_64 on macOS 13: runner is darwin18, no need to force kernel version
        unset VLC_FORCE_KERNELVERSION
        export VLC_PREBUILT_CONTRIBS_URL="https://artifacts.videolan.org/vlc-3.0/macos-x86_64/vlc-contrib-x86_64-apple-darwin18-${CONTRIB_SHA}.tar.bz2"
        BUILD_ARG="x86_64"
    fi

    log_info "VLC_FORCE_KERNELVERSION=${VLC_FORCE_KERNELVERSION:-not set}"
    log_info "VLC_PREBUILT_CONTRIBS_URL=${VLC_PREBUILT_CONTRIBS_URL}"

    ../extras/package/macosx/build.sh -a "${BUILD_ARG}" || {
        log_error "Build for ${arch} failed"
        exit 1
    }

    log_info "Build for ${arch} complete"

    # 提取产物到 output-macos/{arch}/
    mkdir -p "${OUTPUT_DIR}/${arch}"
    cp -r lib "${OUTPUT_DIR}/${arch}/" 2>/dev/null || true
    cp -r modules "${OUTPUT_DIR}/${arch}/" 2>/dev/null || true
    cp -r bin "${OUTPUT_DIR}/${arch}/" 2>/dev/null || true

    cd ..
done

#-------------------------------------------------------------------------------
# 步骤 4: 合并为 Universal Binary
#-------------------------------------------------------------------------------

HAS_ARM64=0
HAS_X86_64=0

for arch in ${BUILD_ARCHS}; do
    if [ "${arch}" = "arm64" ]; then
        HAS_ARM64=1
    elif [ "${arch}" = "x86_64" ]; then
        HAS_X86_64=1
    fi
done

if [ ${HAS_ARM64} -eq 1 ] && [ ${HAS_X86_64} -eq 1 ]; then
    log_info "[4/5] Creating Universal Binary..."

    rm -rf "${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}"

    ARM64_LIB=$(find "${WORK_DIR}/output-macos/arm64" -name "libvlc.dylib" 2>/dev/null | head -1)
    X86_64_LIB=$(find "${WORK_DIR}/output-macos/x86_64" -name "libvlc.dylib" 2>/dev/null | head -1)

    if [ -z "${ARM64_LIB}" ] || [ -z "${X86_64_LIB}" ]; then
        log_error "libvlc.dylib not found:"
        log_error "  arm64:  ${ARM64_LIB}"
        log_error "  x86_64: ${X86_64_LIB}"
        exit 1
    fi

    log_info "Merging arm64: ${ARM64_LIB}"
    log_info "Merging x86_64: ${X86_64_LIB}"

    lipo -create -output "${OUTPUT_DIR}/libvlc.dylib" "${ARM64_LIB}" "${X86_64_LIB}"

    log_info "Universal Binary created: ${OUTPUT_DIR}/libvlc.dylib"
    lipo -info "${OUTPUT_DIR}/libvlc.dylib"

    # 复制 modules
    if [ -d "${WORK_DIR}/output-macos/x86_64/modules" ]; then
        cp -r "${WORK_DIR}/output-macos/x86_64/modules" "${OUTPUT_DIR}/"
        MODULE_COUNT=$(ls "${OUTPUT_DIR}/modules"/*.dylib 2>/dev/null | wc -l | tr -d ' ')
        log_info "Copied ${MODULE_COUNT} modules"
    fi
else
    log_info "[4/5] Skipping merge (only one architecture built)"
fi

#-------------------------------------------------------------------------------
# 步骤 5: 完成
#-------------------------------------------------------------------------------
log_info "[5/5] Build complete."

echo ""
echo "============================================================================"
echo -e "${GREEN}Build Complete!${NC}"
echo "============================================================================"
echo ""
echo "Output directory: ${OUTPUT_DIR}"
echo ""
if [ -f "${OUTPUT_DIR}/libvlc.dylib" ]; then
    echo "Artifacts:"
    echo "  libvlc.dylib   ($(du -h "${OUTPUT_DIR}/libvlc.dylib" | cut -f1))"
    lipo -info "${OUTPUT_DIR}/libvlc.dylib"
fi
echo ""
