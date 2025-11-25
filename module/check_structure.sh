#!/bin/bash

echo "=== Project Structure Check ==="
echo

# Check required directories
echo "1. Checking directories:"
directories=(".github/workflows" "META-INF/com/google/android" "webroot/css" "webroot/js" "webroot/pages" "webroot/icons")
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir/"
    else
        echo "  ❌ $dir/ - MISSING"
    fi
done

echo
echo "2. Checking critical files:"

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
)

for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file - MISSING"
    fi
done

echo
echo "3. Checking web files:"

web_files=(
    "webroot/css/common.css"
    "webroot/css/cake.css"
    "webroot/js/common.js"
    "webroot/js/cake.js"
    "webroot/js/router.js"
    "webroot/pages/home.html"
    "webroot/pages/cake.html"
    "webroot/icons/home.svg"
)

for file in "${web_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file - MISSING"
    fi
done

echo
echo "4. Checking permissions:"
echo "  Scripts:"
ls -la *.sh 2>/dev/null | awk '{print "    " $1 " " $9}'
echo "  META-INF:"
ls -la META-INF/com/google/android/* 2>/dev/null | awk '{print "    " $1 " " $9}'

echo
echo "=== Check complete ==="
