from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
import json

app = Flask(__name__)

# ตั้งค่า CORS อนุญาตเฉพาะโดเมน GitHub Pages ของคุณ
CORS(app, resources={
    r"/api/*": {
        "origins": [
            "https://xxxsingularityxxx.github.io",
            "http://localhost:*" # ใส่สำรองไว้ทดสอบใน Local
        ]
    }
})

GDRIVE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbwYvv3zaXRI3VdnHxv1UoX9LfasonZPGzefkmzxQQTg_O1AZ6XreLaYHhsMmrC0wmggzw/exec'

@app.route('/api/game', methods=['GET'])
def get_game_state():
    return jsonify({
        'status': 'active', 
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
    })

@app.route('/api/game/save-gdrive', methods=['POST'])
def save_to_gdrive():
    try:
        data = request.json or {}
        payload = {
            'game': 'chess', 
            'fen': data.get('fen'), 
            'timestamp': data.get('timestamp')
        }
        response = requests.post(
            GDRIVE_SCRIPT_URL, 
            data=json.dumps(payload), 
            headers={'Content-Type': 'text/plain;charset=utf-8'}, 
            timeout=10
        )
        return jsonify({'status': 'success', 'message': 'บันทึกสำเร็จ!'}), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5001)