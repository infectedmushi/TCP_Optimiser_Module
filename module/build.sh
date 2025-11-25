#!/bin/bash

# build.sh - Build script for TCP Optimiser Module with CAKE

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building TCP Optimiser Module with CAKE Support...${NC}"

# Set executable permissions before building
echo -e "${YELLOW}🔧 Setting file permissions...${NC}"
chmod 755 *.sh
chmod 755 META-INF/com/google/android/update-binary
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

# Create output filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_ZIP="${MODULE_ID}_v${VERSION}_${TIMESTAMP}.zip"

echo -e "${YELLOW}📦 Module: $MODULE_NAME${NC}"
echo -e "${YELLOW}📋 Version: $VERSION (${VERSION_CODE})${NC}"
echo -e "${YELLOW}👨‍💻 Developer: $AUTHOR${NC}"
echo -e "${YELLOW}🕐 Timestamp: $TIMESTAMP${NC}"

# Create temporary build directory
BUILD_DIR="build_${TIMESTAMP}"
mkdir -p "$BUILD_DIR"

echo -e "\n${GREEN}📁 Copying module files...${NC}"

# Copy core module files
cp module.prop "$BUILD_DIR/"
cp customize.sh "$BUILD_DIR/"
cp post-fs-data.sh "$BUILD_DIR/"
cp service.sh "$BUILD_DIR/"
cp system.prop "$BUILD_DIR/"
cp utils.sh "$BUILD_DIR/"
cp tcp_optimizer.py "$BUILD_DIR/"
cp app.py "$BUILD_DIR/"

echo -e "${GREEN}📁 Copying META-INF...${NC}"
cp -r META-INF "$BUILD_DIR/"

echo -e "${GREEN}📁 Copying webroot...${NC}"
cp -r webroot "$BUILD_DIR/"

# Set permissions in build directory
echo -e "${YELLOW}🔧 Setting permissions in build directory...${NC}"
chmod 755 "$BUILD_DIR"/*.sh
chmod 755 "$BUILD_DIR/META-INF/com/google/android/update-binary"
chmod 644 "$BUILD_DIR"/*.py 2>/dev/null || true
chmod 644 "$BUILD_DIR"/webroot/css/*.css
chmod 644 "$BUILD_DIR"/webroot/js/*.js
chmod 644 "$BUILD_DIR"/webroot/pages/*.html
chmod 644 "$BUILD_DIR"/webroot/icons/*.svg
chmod 644 "$BUILD_DIR"/webroot/index.html

# Verify critical files have correct permissions
echo -e "\n${GREEN}🔍 Verifying file permissions...${NC}"
critical_executables=(
    "service.sh"
    "post-fs-data.sh" 
    "customize.sh"
    "utils.sh"
    "META-INF/com/google/android/update-binary"
)

for file in "${critical_executables[@]}"; do
    if [ -f "$BUILD_DIR/$file" ]; then
        perms=$(stat -c "%a" "$BUILD_DIR/$file")
        if [ "$perms" = "755" ]; then
            echo -e "  ✅ $file: $perms"
        else
            echo -e "  ❌ $file: $perms (should be 755)"
            chmod 755 "$BUILD_DIR/$file"
            echo -e "  🔧 Fixed: $file"
        fi
    fi
done

# Verify critical files exist
echo -e "\n${GREEN}🔍 Verifying critical files...${NC}"

critical_files=(
    "module.prop"
    "service.sh"
    "META-INF/com/google/android/update-binary"
    "META-INF/com/google/android/updater-script"
    "webroot/index.html"
    "tcp_optimizer.py"
)

for file in "${critical_files[@]}"; do
    if [ -f "$BUILD_DIR/$file" ]; then
        echo -e "  ✅ $file"
    else
        echo -e "  ❌ $file - MISSING!"
        exit 1
    fi
done

# Verify CAKE integration files
echo -e "\n${GREEN}🔍 Verifying CAKE integration...${NC}"

cake_files=(
    "webroot/pages/cake.html"
    "webroot/js/cake.js"
    "webroot/css/cake.css"
    "tcp_optimizer.py"
)

for file in "${cake_files[@]}"; do
    if [ -f "$BUILD_DIR/$file" ]; then
        echo -e "  ✅ $file"
    else
        echo -e "  ⚠️  $file - CAKE component missing"
    fi
done

# Update module.prop with build info
echo -e "\n${GREEN}📝 Updating module.prop with build info...${NC}"
{
    grep -v "build.date=" "$BUILD_DIR/module.prop" | grep -v "build.timestamp=" | grep -v "features="
    echo "build.date=$(date +'%Y-%m-%d %H:%M:%S')"
    echo "build.timestamp=$TIMESTAMP"
    echo "features=TCP_Optimization+CAKE_QoS+Web_Interface+BBR+CUBIC+Reno"
} > "$BUILD_DIR/module.prop.tmp"
mv "$BUILD_DIR/module.prop.tmp" "$BUILD_DIR/module.prop"

# Create changelog
echo -e "\n${GREEN}📄 Creating changelog...${NC}"
cat > "$BUILD_DIR/CHANGELOG.md" << EOF
# TCP Optimiser Module v${VERSION}

## Build $TIMESTAMP
## Developer: $AUTHOR

### What's New in v${VERSION}:
- 🎉 **MAJOR UPDATE**: Integrated CAKE Queuing Discipline
- 🌐 **New Web Interface**: Dedicated CAKE optimization page
- 🚀 **Enhanced Performance**: Multiple optimization presets
- 📊 **Real-time Monitoring**: Live network status updates

### File Permissions:
All shell scripts are set to 755 (executable)
Web files are set to 644 (readable)

### File Structure:
\`\`\`
\$(find "$BUILD_DIR" -type f | sed 's|'"$BUILD_DIR"/'||' | sort)
\`\`\`

Built: $(date)
Developer: $AUTHOR
EOF

echo -e "\n${GREEN}📦 Creating Magisk module zip...${NC}"

# Create zip file (from inside build directory to maintain structure)
cd "$BUILD_DIR"
zip -r "../$OUTPUT_ZIP" . -x "*.DS_Store" "*.tmp" "*.swp" "*.bak"
cd ..

echo -e "\n${GREEN}🧹 Cleaning up...${NC}"
rm -rf "$BUILD_DIR"

# Verify the final zip
if [ -f "$OUTPUT_ZIP" ]; then
    SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)
    FILE_COUNT=$(unzip -l "$OUTPUT_ZIP" | tail -1 | awk '{print $2}')
    
    echo -e "\n${GREEN}✅ Build successful!${NC}"
    echo -e "${GREEN}📁 Output: $OUTPUT_ZIP${NC}"
    echo -e "${GREEN}📊 Size: $SIZE${NC}"
    echo -e "${GREEN}📄 Files: $FILE_COUNT${NC}"
    
    # Show permissions in zip
    echo -e "\n${YELLOW}🔧 File permissions in zip:${NC}"
    unzip -v "$OUTPUT_ZIP" | grep -E "\.sh$|update-binary" | head -10
    
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 Build completed successfully!${NC}"
