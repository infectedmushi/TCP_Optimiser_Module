#!/system/bin/sh

echo "=== TCP Optimiser Installation Check ==="
echo

MODULE_DIR="/data/adb/modules/tcp_optimiser"

echo "1. Checking if module directory exists:"
if [ -d "$MODULE_DIR" ]; then
    echo "✅ Module directory exists: $MODULE_DIR"
    echo "   Contents:"
    ls -la $MODULE_DIR
else
    echo "❌ Module directory NOT found: $MODULE_DIR"
    echo "   Available modules:"
    ls -la /data/adb/modules/
    exit 1
fi

echo
echo "2. Checking critical files:"
files=("module.prop" "service.sh" "tcp_optimizer.py" "webroot/index.html")
for file in "${files[@]}"; do
    if [ -f "$MODULE_DIR/$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MISSING!"
    fi
done

echo
echo "3. Checking webroot structure:"
if [ -d "$MODULE_DIR/webroot" ]; then
    echo "✅ webroot directory exists"
    echo "   Webroot contents:"
    ls -la $MODULE_DIR/webroot/
else
    echo "❌ webroot directory missing"
fi

echo
echo "4. Checking permissions:"
ls -la $MODULE_DIR/*.sh
ls -la $MODULE_DIR/META-INF/com/google/android/update-binary 2>/dev/null

echo
echo "5. Checking if service is running:"
if ps | grep -v grep | grep "simple_server.py" > /dev/null; then
    echo "✅ Web server is running"
    echo "   Testing connection..."
    if curl -s http://localhost:5000 > /dev/null; then
        echo "✅ Web interface is accessible"
    else
        echo "❌ Web interface not accessible"
    fi
else
    echo "❌ Web server is not running"
    echo "   Starting service..."
    $MODULE_DIR/service.sh start
    sleep 3
    if ps | grep -v grep | grep "simple_server.py" > /dev/null; then
        echo "✅ Web server started successfully"
    else
        echo "❌ Failed to start web server"
    fi
fi

echo
echo "=== Check complete ==="
