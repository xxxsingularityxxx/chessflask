from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

game_data = {
    'status': 'active',
    'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    'message': 'ยินดีต้อนรับสู่ระบบหลังบ้าน Chess API เชื่อมต่อสำเร็จ!',
}

@app.route('/api/game', methods=['GET'])
def get_game_state():
    return jsonify(game_data)

if __name__ == '__main__':
    app.run(debug=True, port=5000)