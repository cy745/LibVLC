#!/bin/bash
#===============================================================================
# LibVLC 构建产物验证脚本
#===============================================================================

OUTPUT_DIR="${1:-./output}"

echo "============================================================================"
echo "  LibVLC Build Verification"
echo "============================================================================"
echo ""
echo "Checking: ${OUTPUT_DIR}"
echo ""

# 检查必需文件
ERRORS=0

# 1. 检查 libvlc.dll
echo -n "libvlc.dll: "
if [ -f "${OUTPUT_DIR}/libvlc.dll" ]; then
    SIZE=$(du -h "${OUTPUT_DIR}/libvlc.dll" | cut -f1)
    echo "OK (${SIZE})"
else
    echo "MISSING!"
    ERRORS=$((ERRORS + 1))
fi

# 2. 检查 libvlccore.dll
echo -n "libvlccore.dll: "
if [ -f "${OUTPUT_DIR}/libvlccore.dll" ]; then
    SIZE=$(du -h "${OUTPUT_DIR}/libvlccore.dll" | cut -f1)
    echo "OK (${SIZE})"
else
    echo "MISSING!"
    ERRORS=$((ERRORS + 1))
fi

# 3. 检查 modules 目录
echo -n "modules/: "
if [ -d "${OUTPUT_DIR}/modules" ]; then
    COUNT=$(ls "${OUTPUT_DIR}/modules"/*.dll 2>/dev/null | wc -l)
    echo "OK (${COUNT} plugins)"
else
    echo "MISSING!"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# 4. 检查关键解码器
echo "----------------------------------------------------------------------------"
echo "  Key Codecs Check"
echo "----------------------------------------------------------------------------"

CODECS=(
    "*avcodec*"
    "*faad*"
    "*aac*"
    "*mp3*"
    "*h264*"
    "*hevc*"
    "*opus*"
    "*vorbis*"
)

for CODEC in "${CODECS[@]}"; do
    MATCHES=$(ls "${OUTPUT_DIR}/modules/${CODEC}.dll" 2>/dev/null | head -1)
    if [ -n "${MATCHES}" ]; then
        echo "OK: $(basename "${MATCHES}")"
    fi
done

echo ""

# 5. 文件类型验证
echo "----------------------------------------------------------------------------"
echo "  File Type Verification (DLL headers)"
echo "----------------------------------------------------------------------------"

for DLL in "${OUTPUT_DIR}/libvlc.dll" "${OUTPUT_DIR}/libvlccore.dll"; do
    if [ -f "${DLL}" ]; then
        echo -n "$(basename "${DLL}"): "
        # 检查 MZ header (Windows DLL)
        if xxd -l 2 -s 0 "${DLL}" 2>/dev/null | grep -q "MZ"; then
            echo "Valid Windows DLL (PE format)"
        else
            echo "Warning: May not be a valid Windows DLL"
        fi
    fi
done

echo ""

# 6. 总结
echo "----------------------------------------------------------------------------"
if [ ${ERRORS} -eq 0 ]; then
    echo -e "\033[0;32mBuild verification PASSED\033[0m"
else
    echo -e "\033[0;31mBuild verification FAILED (${ERRORS} errors)\033[0m"
    exit 1
fi
