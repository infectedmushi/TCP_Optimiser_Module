#!/bin/bash

# build.sh - Build script for TCP Optimiser Module with CAKE

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building TCP Optimiser Module with CAKE Support...${NC}"

# Set executable permissions
echo -e "${YELLOW}🔧 Setting file permissions...${NC}"
chmod 755 *.sh
chmod 755 META-INF/com/google/android/update-binary
chmod 755 META-INF/com/google/android/updater-script
echo -e "${GREEN}✅ Permissions set${NC}"

# Read version from module.prop
if [ -f "module.prop" ]; then
    VERSION=$(grep "version=" module.prop | cut -d'=' -f2)
    VERSION_CODE=$(grep "versionCode=" module.prop | cut -d'=' -f2)
    MODULE_ID=$(grep "id=" module.prop | cut -d'=' -f2)
    MODULE_NAME=$(grep "name=" module.prop | cut -d'=' -f2)
    AUTHOR=$(grep "author=" module.prop | cut -d'=' -f2)
else
    echo -e "${RED}❌ module.prop not found!${NC}"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_ZIP="${MODULE_ID}_v${VERSION}_${TIMESTAMP}.zip"

echo -e "${YELLOW}📦 Module: $MODULE_NAME${NC}"
echo -e "${YELLOW}📋 Version: $VERSION (${VERSION_CODE})${NC}"
echo -e "${YELLOW}👨‍💻 Developer: $AUTHOR${NC}"
echo -e "${YELLOW}🕐 Timestamp: $TIMESTAMP${NC}"

BUILD_DIR="build_${TIMESTAMP}"
mkdir -p "$BUILD_DIR"

echo -e "\n${GREEN}📁 Copying ALL module files...${NC}"

# Copy EVERYTHING except build artifacts
find . -type f -not -path "./build_*" -not -path "./*.zip" -not -name "*.tmp" -not -name "*.swp" -not -name "*.bak" | while read file; do
    # Create directory structure in build dir
    dir=$(dirname "$file")
    mkdir -p "$BUILD_DIR/$dir"
    # Copy file
    cp "$file" "$BUILD_DIR/$file" 2>/dev/null && echo "  ✅ $file" || echo "  ⚠️  Could not copy $file"
done

# Set permissions in build directory
echo -e "\n${YELLOW}🔧 Setting permissions in build directory...${NC}"
chmod 755 "$BUILD_DIR"/*.sh 2>/dev/null || true
chmod 755 "$BUILD_DIR/META-INF/com/google/android/update-binary" 2>/dev/null || true
chmod 755 "$BUILD_DIR/META-INF/com/google/android/updater-script" 2>/dev/null || true
chmod 644 "$BUILD_DIR"/*.py 2>/dev/null || true
chmod 644 "$BUILD_DIR"/*.prop 2>/dev/null || true

# Verify ALL critical files exist
echo -e "\n${GREEN}🔍 Verifying ALL critical files...${NC}"

critical_files=(
    "module.prop"
    "service.sh"
    "post-fs-data.sh"
    "customize.sh"
    "system.prop"
    "utils.sh"
    "tcp_optimizer.py"
    "META-INF/com/google/android/update-binary"
    "META-INF/com/google/android/updater-script"
    "webroot/index.html"
    "webroot/css/common.css"
    "webroot/js/common.js"
    "webroot/pages/home.html"
    "webroot/pages/cake.html"
    "webroot/icons/home.svg"
)

missing_files=0
for file in "${critical_files[@]}"; do
    if [ -f "$BUILD_DIR/$file" ]; then
        echo -e "  ✅ $file"
    else
        echo -e "  ❌ $file - MISSING!"
        missing_files=1
    fi
done

if [ $missing_files -eq 1 ]; then
    echo -e "${RED}❌ Critical files are missing! Build aborted.${NC}"
    exit 1
fi

# Show all files in build directory
echo -e "\n${GREEN}📋 All files in build directory:${NC}"
find "$BUILD_DIR" -type f | sed 's|'"$BUILD_DIR"/'||' | sort

echo -e "\n${GREEN}📦 Creating Magisk module zip...${NC}"

cd "$BUILD_DIR"
zip -r "../$OUTPUT_ZIP" . -x "*.DS_Store" "*.tmp" "*.swp" "*.bak"
cd ..

echo -e "\n${GREEN}🧹 Cleaning up...${NC}"
rm -rf "$BUILD_DIR"

if [ -f "$OUTPUT_ZIP" ]; then
    SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)
    FILE_COUNT=$(unzip -l "$OUTPUT_ZIP" | tail -1 | awk '{print $2}')
    
    echo -e "\n${GREEN}✅ Build successful!${NC}"
    echo -e "${GREEN}📁 Output: $OUTPUT_ZIP${NC}"
    echo -e "${GREEN}📊 Size: $SIZE${NC}"
    echo -e "${GREEN}📄 Files: $FILE_COUNT${NC}"
    
    # Show zip contents
    echo -e "\n${YELLOW}📋 Zip contents:${NC}"
    unzip -l "$OUTPUT_ZIP" | head -30
    
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 Build completed successfully!${NC}"