#!/system/bin/sh

MODULE_DIR="/data/adb/modules/tcp_optimiser"
WEBROOT_DIR="$MODULE_DIR/webroot"
LOG_FILE="/data/adb/tcp_optimiser/service.log"

# Create log directory
mkdir -p /data/adb/tcp_optimiser

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

start_web_server() {
    log "Starting web server..."
    
    # Check if Python is available
    if ! command -v python3 >/dev/null 2>&1; then
        log "Python3 not found, trying python..."
        if ! command -v python >/dev/null 2>&1; then
            log "Error: Python not available"
            return 1
        fi
        PYTHON_CMD="python"
    else
        PYTHON_CMD="python3"
    fi
    
    # Create a simple web server
    cat > $MODULE_DIR/simple_server.py << 'EOF'
import http.server
import socketserver
import os
import sys

PORT = 5000
WEBROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'webroot')

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEBROOT, **kwargs)
    
    def log_message(self, format, *args):
        print(f"[WEB] {format % args}")

os.chdir(WEBROOT)

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    print(f"Server running at http://localhost:{PORT}")
    print(f"Serving from: {WEBROOT}")
    httpd.serve_forever()
EOF

    # Start the web server in background
    cd $MODULE_DIR
    nohup $PYTHON_CMD simple_server.py >> $LOG_FILE 2>&1 &
    echo $! > $MODULE_DIR/web_server.pid
    
    log "Web server started with PID: $(cat $MODULE_DIR/web_server.pid)"
}

stop_web_server() {
    if [ -f $MODULE_DIR/web_server.pid ]; then
        log "Stopping web server..."
        kill -9 $(cat $MODULE_DIR/web_server.pid) 2>/dev/null
        rm -f $MODULE_DIR/web_server.pid
        log "Web server stopped"
    fi
}

case "$1" in
    start)
        log "Starting TCP Optimiser service"
        start_web_server
        ;;
    stop)
        log "Stopping TCP Optimiser service"
        stop_web_server
        ;;
    restart)
        log "Restarting TCP Optimiser service"
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
