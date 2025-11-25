#!/system/bin/sh

MODULE_DIR="/data/adb/modules/tcp_optimiser"
WEBROOT_DIR="$MODULE_DIR/webroot"
LOG_FILE="/data/adb/tcp_optimiser/service.log"

mkdir -p /data/adb/tcp_optimiser

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

start_web_server() {
    log "Starting TCP Optimiser web server..."
    
    # Check if webroot exists
    if [ ! -d "$WEBROOT_DIR" ]; then
        log "ERROR: Webroot directory not found: $WEBROOT_DIR"
        return 1
    fi
    
    # Check if Python is available
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
    else
        log "ERROR: Python not available"
        return 1
    fi
    
    log "Using Python: $PYTHON_CMD"
    
    # Create simple web server script
    cat > $MODULE_DIR/simple_server.py << 'EOF'
import http.server
import socketserver
import os

PORT = 5000
WEBROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'webroot')

print(f"Starting TCP Optimiser web server on port {PORT}")
print(f"Serving from: {WEBROOT}")

if not os.path.exists(WEBROOT):
    print(f"ERROR: Webroot not found: {WEBROOT}")
    exit(1)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEBROOT, **kwargs)
    
    def log_message(self, format, *args):
        print(f"[WEB] {format % args}")

os.chdir(WEBROOT)

try:
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Server ready at http://localhost:{PORT}")
        httpd.serve_forever()
except Exception as e:
    print(f"Server error: {e}")
    exit(1)
EOF

    # Start web server
    cd $MODULE_DIR
    nohup $PYTHON_CMD simple_server.py >> $LOG_FILE 2>&1 &
    echo $! > $MODULE_DIR/web_server.pid
    
    log "Web server started with PID: $(cat $MODULE_DIR/web_server.pid)"
    
    # Wait a bit and check if server is running
    sleep 2
    if curl -s http://localhost:5000 >/dev/null 2>&1; then
        log "Web server confirmed running and accessible"
    else
        log "WARNING: Web server started but may not be accessible"
    fi
}

stop_web_server() {
    if [ -f $MODULE_DIR/web_server.pid ]; then
        PID=$(cat $MODULE_DIR/web_server.pid)
        log "Stopping web server (PID: $PID)"
        kill -9 $PID 2>/dev/null
        rm -f $MODULE_DIR/web_server.pid
        log "Web server stopped"
    fi
    # Clean up any remaining Python processes
    pkill -f "simple_server.py" 2>/dev/null
}

case "$1" in
    start)
        log "=== Starting TCP Optimiser ==="
        start_web_server
        ;;
    stop)
        log "=== Stopping TCP Optimiser ==="
        stop_web_server
        ;;
    restart)
        log "=== Restarting TCP Optimiser ==="
        stop_web_server
        sleep 2
        start_web_server
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac

log "Service operation completed: $1"