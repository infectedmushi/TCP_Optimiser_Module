#!/system/bin/sh

echo "Testing web server..."

# Check if web server is running
if curl -s http://localhost:5000 > /dev/null; then
    echo "✅ Web server is running"
    curl -s http://localhost:5000 | head -5
else
    echo "❌ Web server is not running"
    echo "Starting web server..."
    /data/adb/modules/tcp_optimiser/service.sh start
    sleep 3
    if curl -s http://localhost:5000 > /dev/null; then
        echo "✅ Web server started successfully"
    else
        echo "❌ Failed to start web server"
    fi
fi
