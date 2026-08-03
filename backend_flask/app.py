from flask import Flask, jsonify
from flask_socketio import SocketIO
from flask_cors import CORS

app = Flask(__name__)
app.config['SECRET_KEY'] = 'keren_store_secret_key_a_changer_plus_tard'
CORS(app)

# Initialisation de SocketIO pour la future messagerie en temps réel
socketio = SocketIO(app, cors_allowed_origins="*")

@app.route('/', methods=['GET'])
def home():
    return jsonify({"message": "Bienvenue sur l'API de Keren Store", "status": "En ligne"})

if __name__ == '__main__':
    # On lance le serveur sur le port 5000
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)