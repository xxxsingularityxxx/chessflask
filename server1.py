from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
import json

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# อัปเดต Web App URL ใหม่ตรงนี้ครับ
GDRIVE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbwYvv3zaXRI3VdnHxv1UoX9LfasonZPGzefkmzxQQTg_O1AZ6XreLaYHhsMmrC0wmggzw/exec'

game_data = {
    'status': 'active',
    'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    'message': 'ยินดีต้อนรับสู่ระบบหลังบ้าน Chess API เชื่อมต่อสำเร็จ!',
}

@app.route('/api/game', methods=['GET'])
def get_game_state():
    return jsonify(game_data)

@app.route('/api/game/save-gdrive', methods=['POST'])
def save_to_gdrive():
    try:
        data = request.json or {}
        fen_to_save = data.get('fen', game_data['fen'])

        payload = {
            'game': 'chess',
            'fen': fen_to_save,
            'timestamp': data.get('timestamp')
        }

        # ส่งข้อมูลต่อไปยัง Google Apps Script
        response = requests.post(
            GDRIVE_SCRIPT_URL,
            data=json.dumps(payload),
            headers={'Content-Type': 'text/plain;charset=utf-8'},
            timeout=10
        )

        game_data['fen'] = fen_to_save

        return jsonify({
            'status': 'success',
            'message': 'บันทึกตำแหน่ง FEN ลง Google Drive สำเร็จเรียบร้อย!',
            'fen': fen_to_save,
            'gdrive_response_code': response.status_code
        }), 200

    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'เกิดข้อผิดพลาดขณะส่งไปยัง Google Drive: {str(e)}'
        }), 500

if __name__ == '__main__':
    app.run(debug=True, port=5001)