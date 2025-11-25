#!/system/bin/sh

echo "=== TCP Optimiser Module Test ==="
echo

MODULE_DIR="/data/adb/modules/tcp_optimiser"

echo "1. Checking module installation..."
if [ -d "$MODULE_DIR" ]; then
    echo "✅ Module installed at: $MODULE_DIR"
    echo "   Files found:"
    find $MODULE_DIR -type f | head -10
else
    echo "❌ Module not installed"
    exit 1
fi

echo
echo "2. Checking web server..."
$MODULE_DIR/service.sh stop
sleep 2
$MODULE_DIR/service.sh start
sleep 3

if curl -s http://localhost:5000 > /dev/null; then
    echo "✅ Web server is running and accessible"
    echo "   Testing web interface..."
    curl -s http://localhost:5000 | grep -o "<title>.*</title>"
else
    echo "❌ Web server not accessible"
    echo "   Check logs: /data/adb/tcp_optimiser/service.log"
    cat /data/adb/tcp_optimiser/service.log
fi

echo
echo "3. Testing CAKE functionality..."
if [ -f "$MODULE_DIR/tcp_optimizer.py" ]; then
    echo "✅ tcp_optimizer.py found"
    # Test basic Python functionality
    python3 $MODULE_DIR/tcp_optimizer.py --help 2>/dev/null && echo "✅ Python script works" || echo "⚠️ Python script may have issues"
else
    echo "❌ tcp_optimizer.py missing"
fi

echo
echo "=== Test complete ==="
