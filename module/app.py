# app.py
from flask import Flask, request, jsonify
from tcp_optimizer import api_optimize, api_status, api_presets

app = Flask(__name__)

@app.route('/api/tcp-optimizer', methods=['POST'])
def tcp_optimizer_api():
    data = request.get_json()
    action = data.get('action')
    
    if action == 'optimize':
        return jsonify(api_optimize(data))
    elif action == 'status':
        return jsonify(api_status())
    elif action == 'presets':
        return jsonify(api_presets())
    else:
        return jsonify({'success': False, 'error': 'Unknown action'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
