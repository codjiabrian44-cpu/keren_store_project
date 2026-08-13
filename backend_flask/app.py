import os
import uuid
import json
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_socketio import SocketIO, emit, join_room, leave_room
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from models import db, User, Product, Order, Message
from datetime import timedelta

# Chargement des variables d'environnement depuis le fichier .env (s'il existe)
load_dotenv()

app = Flask(__name__)

# Configurations de sécurité et de base de données via variables d'environnement
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'keren_store_secret_key_a_changer')
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'cle_secrete_jwt_pour_keren_store_2026')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('SQLALCHEMY_DATABASE_URI', 'sqlite:///keren_store.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=30)

# 1. Configuration des uploads
app.config['UPLOAD_FOLDER'] = os.path.join('static', 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 5 * 1024 * 1024  # 5 Mo max
EXTENSIONS_AUTORISEES = {'png', 'jpg', 'jpeg', 'webp'}

def extension_autorisee(nom_fichier):
    return '.' in nom_fichier and nom_fichier.rsplit('.', 1)[1].lower() in EXTENSIONS_AUTORISEES

# Initialisations
CORS(app)
db.init_app(app)
jwt = JWTManager(app)
socketio = SocketIO(app, cors_allowed_origins="*")

with app.app_context():
    # Création du dossier d'upload s'il n'existe pas
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    db.create_all()

# --- ROUTES AUTHENTIFICATION ---
@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data or not data.get('email') or not data.get('mot_de_passe'):
        return jsonify({"erreur": "Email et mot de passe requis"}), 400
        
    utilisateur = User.query.filter_by(email=data['email']).first()
    if not utilisateur or not check_password_hash(utilisateur.mot_de_passe, data['mot_de_passe']):
        return jsonify({"erreur": "Identifiants incorrects"}), 401
        
    access_token = create_access_token(identity=str(utilisateur.id))
    
    return jsonify({
        "message": f"Bienvenue {utilisateur.nom}",
        "access_token": access_token,
        "utilisateur": {
            "id": utilisateur.id,
            "nom": utilisateur.nom,
            "role": utilisateur.role,
            "etoiles": utilisateur.etoiles
        }
    }), 200

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data or not data.get('nom') or not data.get('email') or not data.get('mot_de_passe'):
        return jsonify({"erreur": "Données incomplètes"}), 400
        
    if User.query.filter_by(email=data['email']).first():
        return jsonify({"erreur": "Cet email est déjà utilisé"}), 409
        
    nouveau_client = User(
        nom=data['nom'],
        email=data['email'],
        mot_de_passe=generate_password_hash(data['mot_de_passe']),
        role='client',
        etoiles=2
    )
    db.session.add(nouveau_client)
    db.session.commit()
    
    return jsonify({"message": "Compte client créé avec succès"}), 201


# --- ROUTES PRODUITS ---
@app.route('/api/products', methods=['GET'])
def get_products():
    produits = Product.query.all()
    return jsonify([produit.to_dict() for produit in produits]), 200

# 3. Récupérer un produit spécifique
@app.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    produit = db.session.get(Product, product_id)
    if not produit:
        return jsonify({"erreur": "Produit introuvable"}), 404
    return jsonify(produit.to_dict()), 200

# 2. Créer un produit (Multipart Form Data)
@app.route('/api/products', methods=['POST'])
@jwt_required()
def add_product():
    user_id = get_jwt_identity()
    current_user = db.session.get(User, int(user_id))
    
    if not current_user or current_user.role != 'admin':
        return jsonify({"erreur": "Accès refusé. Action réservée aux administrateurs."}), 403
        
    champs_requis = ['nom', 'marque', 'categorie', 'prix', 'ram_go', 'stockage_go', 'type_stockage', 'processeur']
    
    # Vérification des champs texte obligatoires
    for champ in champs_requis:
        if not request.form.get(champ):
            return jsonify({"erreur": f"Le champ '{champ}' est obligatoire."}), 400
            
    # Vérification et conversion des entiers
    try:
        prix = int(request.form.get('prix'))
        ram_go = int(request.form.get('ram_go'))
        stockage_go = int(request.form.get('stockage_go'))
    except ValueError:
        return jsonify({"erreur": "Les champs 'prix', 'ram_go' et 'stockage_go' doivent être des nombres entiers valides."}), 400

    # Gestion de l'image
    image_url = None
    if 'image' in request.files:
        file = request.files['image']
        if file and file.filename != '':
            if not extension_autorisee(file.filename):
                return jsonify({"erreur": "Extension de fichier non autorisée. Utilisez png, jpg, jpeg ou webp."}), 400
                
            extension = file.filename.rsplit('.', 1)[1].lower()
            nouveau_nom = f"{uuid.uuid4().hex}.{extension}"
            chemin_sauvegarde = os.path.join(app.config['UPLOAD_FOLDER'], nouveau_nom)
            file.save(chemin_sauvegarde)
            
            # Stockage du chemin public
            image_url = f"/static/uploads/{nouveau_nom}"

    # Parsing du dictionnaire JSON (si fourni)
    autres_specs = {}
    autres_specs_str = request.form.get('autres_specs')
    if autres_specs_str:
        try:
            autres_specs = json.loads(autres_specs_str)
        except json.JSONDecodeError:
            pass

    nouveau_produit = Product(
        nom=request.form.get('nom'),
        marque=request.form.get('marque'),
        categorie=request.form.get('categorie'),
        prix=prix,
        description=request.form.get('description', 'Aucune description'),
        ram_go=ram_go,
        stockage_go=stockage_go,
        type_stockage=request.form.get('type_stockage'),
        processeur=request.form.get('processeur'),
        autres_specs=autres_specs,
        image_url=image_url
    )
    db.session.add(nouveau_produit)
    db.session.commit()
    return jsonify({"message": "Ordinateur ajouté avec succès au catalogue Keren Store !"}), 201

# 4. Modifier un produit
@app.route('/api/products/<int:product_id>', methods=['PUT'])
@jwt_required()
def update_product(product_id):
    user_id = get_jwt_identity()
    current_user = db.session.get(User, int(user_id))
    
    if not current_user or current_user.role != 'admin':
        return jsonify({"erreur": "Accès refusé. Action réservée aux administrateurs."}), 403

    produit = db.session.get(Product, product_id)
    if not produit:
        return jsonify({"erreur": "Produit introuvable"}), 404

    champs_requis = ['nom', 'marque', 'categorie', 'prix', 'ram_go', 'stockage_go', 'type_stockage', 'processeur']
    for champ in champs_requis:
        if not request.form.get(champ):
            return jsonify({"erreur": f"Le champ '{champ}' est obligatoire pour la mise à jour."}), 400

    try:
        produit.prix = int(request.form.get('prix'))
        produit.ram_go = int(request.form.get('ram_go'))
        produit.stockage_go = int(request.form.get('stockage_go'))
    except ValueError:
        return jsonify({"erreur": "Les champs 'prix', 'ram_go' et 'stockage_go' doivent être des nombres entiers valides."}), 400

    produit.nom = request.form.get('nom')
    produit.marque = request.form.get('marque')
    produit.categorie = request.form.get('categorie')
    produit.description = request.form.get('description', produit.description)
    produit.type_stockage = request.form.get('type_stockage')
    produit.processeur = request.form.get('processeur')
    
    autres_specs_str = request.form.get('autres_specs')
    if autres_specs_str:
        try:
            produit.autres_specs = json.loads(autres_specs_str)
        except json.JSONDecodeError:
            pass

    if 'image' in request.files:
        file = request.files['image']
        if file and file.filename != '':
            if not extension_autorisee(file.filename):
                return jsonify({"erreur": "Extension de fichier non autorisée. Utilisez png, jpg, jpeg ou webp."}), 400
                
            # Suppression de l'ancienne image si elle existe
            if produit.image_url:
                ancien_nom = produit.image_url.split('/')[-1]
                chemin_ancien = os.path.join(app.config['UPLOAD_FOLDER'], ancien_nom)
                if os.path.exists(chemin_ancien):
                    try:
                        os.remove(chemin_ancien)
                    except OSError:
                        pass

            extension = file.filename.rsplit('.', 1)[1].lower()
            nouveau_nom = f"{uuid.uuid4().hex}.{extension}"
            chemin_sauvegarde = os.path.join(app.config['UPLOAD_FOLDER'], nouveau_nom)
            file.save(chemin_sauvegarde)
            
            produit.image_url = f"/static/uploads/{nouveau_nom}"

    db.session.commit()
    return jsonify({"message": "Produit mis à jour avec succès !"}), 200

# 5. Supprimer un produit
@app.route('/api/products/<int:product_id>', methods=['DELETE'])
@jwt_required()
def delete_product(product_id):
    user_id = get_jwt_identity()
    current_user = db.session.get(User, int(user_id))
    
    if not current_user or current_user.role != 'admin':
        return jsonify({"erreur": "Accès refusé. Action réservée aux administrateurs."}), 403

    produit = db.session.get(Product, product_id)
    if not produit:
        return jsonify({"erreur": "Produit introuvable"}), 404

    # Suppression du fichier image associé
    if produit.image_url:
        nom_fichier = produit.image_url.split('/')[-1]
        chemin_fichier = os.path.join(app.config['UPLOAD_FOLDER'], nom_fichier)
        if os.path.exists(chemin_fichier):
            try:
                os.remove(chemin_fichier)
            except OSError:
                pass

    db.session.delete(produit)
    db.session.commit()
    return jsonify({"message": "Produit et image associés supprimés avec succès."}), 200


# --- ROUTES COMMANDES & MESSAGERIE ---
@app.route('/api/orders', methods=['GET', 'POST'])
@jwt_required()
def handle_orders():
    user_id = int(get_jwt_identity())
    
    # 1. LECTURE DES COMMANDES (Pour la boîte de réception dans Flutter)
    if request.method == 'GET':
        commandes = Order.query.filter(
            (Order.client_id == user_id) | (Order.vendeur_id == user_id)
        ).all()
        
        liste_commandes = []
        for cmd in commandes:
            liste_commandes.append({
                "id": cmd.id,
                "statut": cmd.statut
            })
            
        return jsonify({"orders": liste_commandes}), 200

    # 2. CRÉATION D'UNE COMMANDE (Lors du clic sur Commander)
    elif request.method == 'POST':
        data = request.get_json()
        produit_id = data.get('produit_id')
        vendeur_id = data.get('vendeur_id')
        
        produit = db.session.get(Product, produit_id)
        if not produit:
            return jsonify({"erreur": "Ce produit n'existe pas ou n'est plus disponible."}), 404
            
        nouvelle_commande = Order(client_id=user_id, vendeur_id=vendeur_id, produit_id=produit.id, statut='En attente')
        db.session.add(nouvelle_commande)
        db.session.flush() 
        
        texte_auto = f"🛒 NOUVELLE COMMANDE : {produit.nom} au prix de {produit.prix} FCFA. En attente de confirmation du vendeur pour les modalités de livraison."
        premier_message = Message(order_id=nouvelle_commande.id, expediteur_id=user_id, contenu=texte_auto)
        db.session.add(premier_message)
        db.session.commit()
        
        return jsonify({"message": "Commande validée ! Redirection vers la messagerie en cours...", "order_id": nouvelle_commande.id}), 201

@app.route('/api/orders/<int:order_id>/messages', methods=['GET'])
@jwt_required()
def get_order_messages(order_id):
    user_id = int(get_jwt_identity())
    current_user = db.session.get(User, user_id)
    commande = db.session.get(Order, order_id)
    
    if not commande:
        return jsonify({"erreur": "Commande introuvable"}), 404
    if current_user.role != 'admin' and commande.client_id != user_id:
        return jsonify({"erreur": "Accès refusé. Ce chat est privé."}), 403
        
    messages = Message.query.filter_by(order_id=order_id).order_by(Message.timestamp.asc()).all()
    historique = []
    for msg in messages:
        expediteur = db.session.get(User, msg.expediteur_id)
        historique.append({
            "id": msg.id,
            "expediteur_id": msg.expediteur_id,
            "expediteur_nom": expediteur.nom if expediteur else "Inconnu",
            "contenu": msg.contenu,
            "lu": msg.lu,
            "date": msg.timestamp.strftime("%Y-%m-%d %H:%M:%S")
        })
        
    return jsonify({"commande_id": commande.id, "produit_id": commande.produit_id, "statut": commande.statut, "messages": historique}), 200

@app.route('/api/orders/<int:order_id>/messages', methods=['POST'])
@jwt_required()
def send_message(order_id):
    user_id = int(get_jwt_identity())
    current_user = db.session.get(User, user_id)
    commande = db.session.get(Order, order_id)
    
    if not commande:
        return jsonify({"erreur": "Commande introuvable"}), 404
    if current_user.role != 'admin' and commande.client_id != user_id:
        return jsonify({"erreur": "Accès refusé. Ce chat est privé."}), 403
        
    data = request.get_json()
    contenu = data.get('contenu')
    if not contenu:
        return jsonify({"erreur": "Le message ne peut pas être vide"}), 400
        
    nouveau_message = Message(order_id=order_id, expediteur_id=user_id, contenu=contenu)
    db.session.add(nouveau_message)
    
    if current_user.role == 'admin' and commande.statut == 'En attente':
        commande.statut = 'En cours de traitement'
        
    db.session.commit()
    
    message_data = {
        "id": nouveau_message.id,
        "expediteur_id": user_id,
        "contenu": nouveau_message.contenu,
        "date": nouveau_message.timestamp.strftime("%Y-%m-%d %H:%M:%S")
    }
    
    nom_du_salon = f"commande_{order_id}"
    socketio.emit('nouveau_message', message_data, room=nom_du_salon)
    
    return jsonify({"message": "Message envoyé avec succès", "statut_commande": commande.statut}), 201

@app.route('/', methods=['GET'])
def home():
    return jsonify({"message": "API Keren Store connectée", "status": "En ligne"})

# --- ÉVÉNEMENTS WEBSOCKETS (TEMPS RÉEL) ---
@socketio.on('rejoindre_chat')
def on_join(data):
    order_id = data.get('order_id')
    if order_id:
        nom_du_salon = f"commande_{order_id}"
        join_room(nom_du_salon)
        print(f"📱 Un utilisateur a rejoint le chat en direct de la commande {order_id}")

@socketio.on('quitter_chat')
def on_leave(data):
    order_id = data.get('order_id')
    if order_id:
        nom_du_salon = f"commande_{order_id}"
        leave_room(nom_du_salon)
        print(f"📱 Un utilisateur a quitté le chat de la commande {order_id}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)