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
# 步骤 3: 下载并预置预编译 contribs（绕过 build.sh 的 make prebuilt bug）
#-------------------------------------------------------------------------------
log_info "[3/6] Downloading and extracting prebuilt contribs..."

for arch in ${ARCHS}; do
    VLC_DIR="${WORK_DIR}/vlc-build-${arch}"
    cd "${VLC_DIR}"

    if [ "${arch}" = "arm64" ]; then
        CONTRIB_TRIPLET="aarch64-apple-darwin19"
        CONTRIB_URL="https://artifacts.videolan.org/vlc-3.0/macos-arm64/vlc-contrib-aarch64-apple-darwin19-${CONTRIB_SHA}.tar.bz2"
    else
        CONTRIB_TRIPLET="x86_64-apple-darwin18"
        CONTRIB_URL="https://artifacts.videolan.org/vlc-3.0/macos-x86_64/vlc-contrib-x86_64-apple-darwin18-${CONTRIB_SHA}.tar.bz2"
    fi

    log_info "Downloading contribs for ${arch} (${CONTRIB_TRIPLET})..."
    log_info "URL: ${CONTRIB_URL}"

    mkdir -p contrib
    cd contrib

    # 下载预编译包
    curl -f -L --retry 3 --output "vlc-contrib-${CONTRIB_TRIPLET}.tar.bz2" -- "${CONTRIB_URL}" || {
        log_error "Failed to download contribs for ${arch}"
        exit 1
    }

    # 删除旧目录（如存在）
    rm -rf "${CONTRIB_TRIPLET}"

    # 解压到正确位置（tarball 里就是正确的 triplet 目录名）
    tar xjf "vlc-contrib-${CONTRIB_TRIPLET}.tar.bz2" || {
        log_error "Failed to extract contribs for ${arch}"
        exit 1
    }

    rm -f "vlc-contrib-${CONTRIB_TRIPLET}.tar.bz2"
    log_info "Contribs for ${arch} ready: ${VLC_DIR}/contrib/${CONTRIB_TRIPLET}"
    cd ../..
done

#-------------------------------------------------------------------------------
# 步骤 4: 准备输出目录
#-------------------------------------------------------------------------------
log_info "[4/6] Preparing output directory..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

#-------------------------------------------------------------------------------
# 步骤 5: 为每个架构构建 VLC
#-------------------------------------------------------------------------------
log_info "[5/6] Building VLC for each architecture..."

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

    # 强制 macOS kernel 版本以匹配 VideoLAN 的预编译包 triplet
    # macOS 15 (uname -r = 24.x) 匹配 darwin19 (arm64) / darwin18 (x86_64)
    if [ "${arch}" = "arm64" ]; then
        export VLC_FORCE_KERNELVERSION=19
        CONTRIB_TRIPLET="aarch64-apple-darwin19"
    else
        export VLC_FORCE_KERNELVERSION=18
        CONTRIB_TRIPLET="x86_64-apple-darwin18"
    fi

    # 不使用 build.sh 的 -r flag，因为预编译 contribs 已就位
    # 直接调用 VLC 的 bootstrap / configure / make
    log_info "Bootstrapping VLC..."

    # 设置编译器工具链
    SDKROOT=$(xcrun --show-sdk-path)
    export AR="`xcrun --find ar`"
    export CC="`xcrun --find clang`"
    export CXX="`xcrun --find clang++`"
    export NM="`xcrun --find nm`"
    export OBJC="`xcrun --find clang`"
    export RANLIB="`xcrun --find ranlib`"
    export STRIP="`xcrun --find strip`"
    export SDKROOT
    export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}"
    export CFLAGS="-g -arch ${arch}"
    export CXXFLAGS="-g -arch ${arch}"
    export OBJCFLAGS="-g -arch ${arch}"
    export LDFLAGS="-arch ${arch}"
    export PATH="${VLC_DIR}/extras/tools/build/bin:$PATH"

    cd "${VLC_DIR}"

    # Bootstrap (generate configure)
    if [ ! -f configure ]; then
        ./bootstrap > /dev/null || {
            log_error "Bootstrap failed for ${arch}"
            exit 1
        }
    fi

    # Configure VLC
    log_info "Configuring VLC for ${arch}..."
    OSX_KERNELVERSION=${VLC_FORCE_KERNELVERSION}
    BUILD_TRIPLET=$([ "${arch}" = "arm64" ] && echo "aarch64" || echo "${arch}")
    HOST_TRIPLET=$([ "${arch}" = "arm64" ] && echo "arm64" || echo "x86_64")

    ./extras/package/macosx/configure.sh \
        --build="${BUILD_TRIPLET}-apple-darwin${OSX_KERNELVERSION}" \
        --host="${HOST_TRIPLET}-apple-darwin${OSX_KERNELVERSION}" \
        --with-macosx-version-min="${MACOSX_DEPLOYMENT_TARGET}" \
        --with-macosx-sdk="${SDKROOT}" > /dev/null 2>&1 || {
        log_error "Configure failed for ${arch}"
        exit 1
    }

    # Build VLC
    log_info "Building VLC for ${arch}..."
    CORE_COUNT=$(getconf NPROCESSORS_ONLN 2>&1)
    JOBS=$((CORE_COUNT + 1))
    make -j${JOBS} || {
        log_error "Make failed for ${arch}"
        exit 1
    }

    log_info "Build for ${arch} complete"

    log_info "Build for ${arch} complete"
done

#-------------------------------------------------------------------------------
# 步骤 6: 合并为 Universal Binary
#-------------------------------------------------------------------------------
log_info "[6/7] Creating Universal Binary (arm64 + x86_64)..."

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
log_info "[7/7] Copying modules..."

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
