#!/bin/bash

# build.sh - Build script for TCP Optimiser Module with CAKE

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building TCP Optimiser Module with CAKE Support...${NC}"

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

# Verify critical files
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

### What's New in v2.5:
- 🎉 **MAJOR UPDATE**: Integrated CAKE Queuing Discipline
- 🌐 **New Web Interface**: Dedicated CAKE optimization page
- 🚀 **Enhanced Performance**: Multiple optimization presets
- 📊 **Real-time Monitoring**: Live network status updates
- 🎮 **Gaming Optimization**: Low latency CAKE preset
- 📺 **Streaming Optimization**: Stable bandwidth preset
- 📶 **Wireless Optimization**: WiFi-specific CAKE settings
- 🛰️ **High Latency Support**: Satellite/cellular optimization

### CAKE Features:
- **General**: Balanced settings for everyday use
- **Gaming**: Low latency optimization for online games
- **Streaming**: Stable bandwidth for video streaming
- **Wireless**: Optimized for WiFi networks
- **High Latency**: Better performance on satellite/cellular links

### Supported Algorithms:
- BBR (Recommended for most use cases)
- CUBIC (Traditional Linux algorithm)
- Reno (Basic congestion control)

### File Structure:
\`\`\`
\$(find "$BUILD_DIR" -type f | sed 's|'"$BUILD_DIR"/'||' | sort)
\`\`\`

Built: $(date)
Developer: $AUTHOR
EOF

# Create README file
cat > "$BUILD_DIR/README.md" << EOF
# TCP Optimiser with CAKE v${VERSION}

A Magisk/KernelSU module for TCP optimization with CAKE queuing discipline support.

## Features

- ✅ **CAKE Queuing Discipline** - Advanced traffic shaping
- ✅ **Web Management Interface** - Easy browser-based control
- ✅ **Multiple Congestion Controls** - BBR, CUBIC, Reno
- ✅ **Optimization Presets** - Gaming, Streaming, Wireless, etc.
- ✅ **Real-time Monitoring** - Live network status
- ✅ **KernelSU Integration** - Rootless operation support

## Installation

1. Flash the zip file in Magisk/KernelSU
2. Reboot your device
3. Access web interface at: http://localhost:5000

## Web Interface

After installation, navigate to:
- **Home**: Overall module status
- **Settings**: Configuration options
- **CAKE**: CAKE optimization presets
- **Logs**: Operation logs

## CAKE Presets

- **General**: Balanced everyday use
- **Gaming**: Low latency for games
- **Streaming**: Stable video streaming
- **Wireless**: WiFi optimization
- **High Latency**: Satellite/cellular links

## Developer

**$AUTHOR**

Built: $(date)
Version: ${VERSION} (${VERSION_CODE})
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
    
    # Show module info
    echo -e "\n${YELLOW}📋 Module Information:${NC}"
    echo -e "  Name:     $MODULE_NAME"
    echo -e "  Version:  $VERSION ($VERSION_CODE)"
    echo -e "  Developer: $AUTHOR"
    echo -e "  ID:       $MODULE_ID"
    
    echo -e "\n${YELLOW}🎯 Features Included:${NC}"
    echo -e "  • TCP Congestion Control optimization"
    echo -e "  • CAKE Queuing Discipline support"
    echo -e "  • Web-based management interface"
    echo -e "  • Real-time network status monitoring"
    echo -e "  • Multiple optimization presets"
    echo -e "  • KernelSU integration"
    
    echo -e "\n${YELLOW}🌐 Web Interface:${NC}"
    echo -e "  After installation, access at:"
    echo -e "  http://localhost:5000"
    echo -e "  or"
    echo -e "  http://[device-ip]:5000"
    
    echo -e "\n${GREEN}📥 Installation:${NC}"
    echo -e "  1. Flash $OUTPUT_ZIP in Magisk/KernelSU"
    echo -e "  2. Reboot your device"
    echo -e "  3. Access web interface"
    echo -e "  4. Navigate to 'CAKE' tab for QoS optimization"
    
    echo -e "\n${YELLOW}🔧 CAKE Optimization:${NC}"
    echo -e "  Available in the CAKE tab:"
    echo -e "  • Congestion Control: BBR, CUBIC, Reno"
    echo -e "  • CAKE Presets: General, Gaming, Streaming, Wireless, High Latency"
    echo -e "  • Real-time status monitoring"
    
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# Create quick verification
echo -e "\n${GREEN}🔍 Quick verification...${NC}"
unzip -l "$OUTPUT_ZIP" | grep -E "(cake|CAKE)" | head -5 | while read line; do
    echo -e "  📄 $line"
done

echo -e "\n${GREEN}🎉 Build completed successfully!${NC}"
echo -e "${GREEN}👨‍💻 Developer: $AUTHOR${NC}"
echo -e "${GREEN}🏷️  Version: $VERSION${NC}"
