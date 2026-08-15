import os
import uuid
import json
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_socketio import SocketIO, emit, join_room, leave_room
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from models import db, User, Product, Order, Message, Review
from datetime import timedelta

# Chargement des variables d'environnement depuis le fichier .env (s'il existe)
load_dotenv()

app = Flask(__name__)

# Configurations de sécurité et de base de données via variables d'environnement
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'keren_store_secret_key_a_changer')
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'cle_secrete_jwt_pour_keren_store_2026')
database_url = os.environ.get('DATABASE_URL')

if database_url:
    if database_url.startswith('postgres://'):
        database_url = database_url.replace('postgres://', 'postgresql://', 1)
    app.config['SQLALCHEMY_DATABASE_URI'] = database_url
else:
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///keren_store.db'
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
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    db.create_all()
    
def recalculer_etoiles(user_id):
    utilisateur = db.session.get(User, user_id)
    if not utilisateur:
        return
        
    # 1. Compter le nombre de commandes livrées
    nombre_achats = Order.query.filter_by(client_id=user_id, statut='Livrée').count()
    
    # 2. Appliquer la grille d'étoiles
    if nombre_achats >= 6:
        nouvelles_etoiles = 5
    elif nombre_achats >= 3:
        nouvelles_etoiles = 4
    elif nombre_achats >= 1:
        nouvelles_etoiles = 3
    else:
        nouvelles_etoiles = 2
        
    # 3. Mettre à jour et commit seulement s'il y a un changement
    if utilisateur.etoiles != nouvelles_etoiles:
        utilisateur.etoiles = nouvelles_etoiles
        db.session.commit()

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
    categorie = request.args.get('categorie')
    
    if categorie:
        produits = Product.query.filter_by(categorie=categorie).all()
    else:
        produits = Product.query.all()
        
    return jsonify([produit.to_dict() for produit in produits]), 200

@app.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    produit = db.session.get(Product, product_id)
    if not produit:
        return jsonify({"erreur": "Produit introuvable"}), 404
    return jsonify(produit.to_dict()), 200

@app.route('/api/products', methods=['POST'])
@jwt_required()
def add_product():
    user_id = get_jwt_identity()
    current_user = db.session.get(User, int(user_id))
    
    if not current_user or current_user.role != 'admin':
        return jsonify({"erreur": "Accès refusé. Action réservée aux administrateurs."}), 403
        
    champs_requis = ['nom', 'marque', 'categorie', 'prix', 'ram_go', 'stockage_go', 'type_stockage', 'processeur']
    
    for champ in champs_requis:
        if not request.form.get(champ):
            return jsonify({"erreur": f"Le champ '{champ}' est obligatoire."}), 400
            
    try:
        prix = int(request.form.get('prix'))
        ram_go = int(request.form.get('ram_go'))
        stockage_go = int(request.form.get('stockage_go'))
    except ValueError:
        return jsonify({"erreur": "Les champs 'prix', 'ram_go' et 'stockage_go' doivent être des nombres entiers valides."}), 400

    image_url = None
    if 'image' in request.files:
        file = request.files['image']
        if file and file.filename != '':
            if not extension_autorisee(file.filename):
                return jsonify({"erreur": "Extension de fichier non autorisée."}), 400
                
            extension = file.filename.rsplit('.', 1)[1].lower()
            nouveau_nom = f"{uuid.uuid4().hex}.{extension}"
            chemin_sauvegarde = os.path.join(app.config['UPLOAD_FOLDER'], nouveau_nom)
            file.save(chemin_sauvegarde)
            
            image_url = f"/static/uploads/{nouveau_nom}"

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
    return jsonify({"message": "Ordinateur ajouté avec succès !"}), 201

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
            return jsonify({"erreur": f"Le champ '{champ}' est obligatoire."}), 400

    try:
        produit.prix = int(request.form.get('prix'))
        produit.ram_go = int(request.form.get('ram_go'))
        produit.stockage_go = int(request.form.get('stockage_go'))
    except ValueError:
        return jsonify({"erreur": "Les champs doivent être des nombres."}), 400

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
                return jsonify({"erreur": "Extension non autorisée."}), 400
                
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
    return jsonify({"message": "Produit supprimé avec succès."}), 200

@app.route('/api/admins', methods=['GET'])
@jwt_required()
def get_admins():
    admins = User.query.filter_by(role='admin').all()
    result = [{"id": admin.id, "nom": admin.nom} for admin in admins]
    return jsonify(result), 200

# --- ROUTES AVIS (REVIEWS) ---
@app.route('/api/products/<int:product_id>/reviews', methods=['POST'])
@jwt_required()
def add_review(product_id):
    user_id = int(get_jwt_identity())
    data = request.get_json()

    sous_requete_avis = db.session.query(Review.order_id).filter_by(client_id=user_id, product_id=product_id)
    
    commande_valide = Order.query.filter_by(
        client_id=user_id,
        produit_id=product_id,
        statut='Livrée'
    ).filter(
        ~Order.id.in_(sous_requete_avis)
    ).first()

    if not commande_valide:
        a_deja_commande = Order.query.filter_by(client_id=user_id, produit_id=product_id, statut='Livrée').first()
        if a_deja_commande:
            return jsonify({"erreur": "Vous avez déjà laissé un avis pour tous vos achats de ce produit."}), 409
        return jsonify({"erreur": "Vous devez avoir reçu ce produit (statut 'Livrée') pour laisser un avis."}), 403

    note = data.get('note')
    if not isinstance(note, int) or not (1 <= note <= 5):
        return jsonify({"erreur": "La note doit être un nombre entier entre 1 et 5."}), 400

    nouvel_avis = Review(
        product_id=product_id,
        client_id=user_id,
        order_id=commande_valide.id,
        note=note,
        commentaire=data.get('commentaire', '')
    )
    db.session.add(nouvel_avis)
    db.session.commit()

    return jsonify({"message": "Avis ajouté avec succès !"}), 201

@app.route('/api/products/<int:product_id>/reviews', methods=['GET'])
def get_reviews(product_id):
    avis_list = Review.query.filter_by(product_id=product_id).order_by(Review.date_avis.desc()).all()

    if not avis_list:
        return jsonify({"moyenne": 0.0, "total": 0, "avis": []}), 200

    total = len(avis_list)
    somme_notes = sum(a.note for a in avis_list)
    moyenne = round(somme_notes / total, 1)

    resultat_avis = []
    for avis in avis_list:
        client = db.session.get(User, avis.client_id)
        resultat_avis.append({
            "id": avis.id,
            "client_nom": client.nom if client else "Utilisateur",
            "note": avis.note,
            "commentaire": avis.commentaire,
            "date": avis.date_avis.strftime("%d/%m/%Y")
        })

    return jsonify({
        "moyenne": moyenne,
        "total": total,
        "avis": resultat_avis
    }), 200
 
# --- ROUTES COMMANDES & MESSAGERIE ---
@app.route('/api/orders/<int:order_id>/statut', methods=['PATCH'])
@jwt_required()
def update_order_status(order_id):
    user_id = int(get_jwt_identity())
    current_user = db.session.get(User, user_id)
    
    if not current_user or current_user.role != 'admin':
        return jsonify({"erreur": "Accès refusé. Action réservée aux administrateurs."}), 403
        
    commande = db.session.get(Order, order_id)
    if not commande:
        return jsonify({"erreur": "Commande introuvable"}), 404
        
    data = request.get_json()
    if not data or 'statut' not in data:
        return jsonify({"erreur": "Le champ 'statut' est requis"}), 400
        
    nouveau_statut = data.get('statut')
    
    etapes_statut = [
        "Commande passée", 
        "Confirmée par vendeur", 
        "En préparation", 
        "Expédiée", 
        "Livrée"
    ]
    
    if nouveau_statut not in etapes_statut:
        return jsonify({"erreur": f"Statut invalide."}), 400
        
    statut_actuel = commande.statut
    try:
        index_actuel = etapes_statut.index(statut_actuel)
    except ValueError:
        index_actuel = -1 
        
    index_nouveau = etapes_statut.index(nouveau_statut)
    
    if index_nouveau <= index_actuel:
        return jsonify({"erreur": f"Impossible de revenir en arrière (actuel: {statut_actuel})."}), 400
        
    commande.statut = nouveau_statut
    db.session.commit()
    
    if nouveau_statut == "Livrée":
        recalculer_etoiles(commande.client_id)
        
    texte_auto = f"📦 Statut mis à jour : {nouveau_statut}"
    nouveau_message = Message(order_id=commande.id, expediteur_id=user_id, contenu=texte_auto)
    db.session.add(nouveau_message)
    db.session.commit()
    
    message_data = {
        "id": nouveau_message.id,
        "expediteur_id": user_id,
        "contenu": nouveau_message.contenu,
        "date": nouveau_message.timestamp.strftime("%Y-%m-%d %H:%M:%S")
    }
    
    nom_du_salon = f"commande_{order_id}"
    socketio.emit('nouveau_message', message_data, room=nom_du_salon)
    
    return jsonify({
        "message": "Statut mis à jour", 
        "statut": commande.statut
    }), 200

@app.route('/api/orders', methods=['GET', 'POST'])
@jwt_required()
def handle_orders():
    user_id = int(get_jwt_identity())
    current_user = db.session.get(User, user_id)
    
    # 1. LECTURE DES COMMANDES (Pour la boîte de réception)
    if request.method == 'GET':
        if current_user and current_user.role == 'admin':
            # Un admin voit ses commandes (s'il achète), celles qui lui sont assignées, 
            # ET celles non assignées (vendeur_id == None)
            commandes = Order.query.filter(
                (Order.client_id == user_id) | 
                (Order.vendeur_id == user_id) | 
                (Order.vendeur_id.is_(None))
            ).all()
        else:
            # Un client ne voit que ses propres commandes
            commandes = Order.query.filter(
                (Order.client_id == user_id)
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
        
        # --- VALIDATION DU PRODUIT ---
        produit_id_brut = data.get('produit_id')
        if produit_id_brut is None:
            return jsonify({"erreur": "L'ID du produit est requis."}), 400
        try:
            produit_id = int(produit_id_brut)
        except (ValueError, TypeError):
            return jsonify({"erreur": "L'ID du produit doit être un entier valide."}), 400

        # --- VALIDATION DU VENDEUR ---
        vendeur_id_brut = data.get('vendeur_id')
        vendeur_id = None
        
        if vendeur_id_brut is not None:
            try:
                vendeur_id = int(vendeur_id_brut)
                vendeur = db.session.get(User, vendeur_id)
                if not vendeur or vendeur.role != 'admin':
                    return jsonify({"erreur": "Vendeur invalide."}), 400
            except (ValueError, TypeError):
                return jsonify({"erreur": "Vendeur invalide."}), 400
        
        # --- VALIDATION DE LA QUANTITÉ ---
        try:
            quantite = int(data.get('quantite', 1))
            if quantite < 1:
                raise ValueError()
        except (ValueError, TypeError):
            return jsonify({"erreur": "La quantité doit être un entier supérieur ou égal à 1."}), 400
        
        # --- VÉRIFICATION DE L'EXISTENCE DU PRODUIT ---
        produit = db.session.get(Product, produit_id)
        if not produit:
            return jsonify({"erreur": "Produit introuvable."}), 404
            
        # --- CRÉATION DE LA COMMANDE ---
        nouvelle_commande = Order(
            client_id=user_id, 
            vendeur_id=vendeur_id,  # Sera soit un ID admin valide, soit None
            produit_id=produit.id,
            quantite=quantite,
            statut='Commande passée'
        )
        db.session.add(nouvelle_commande)
        db.session.flush() 
        
        # Calcul du total et formatage des montants
        total = produit.prix * quantite
        prix_unitaire_str = f"{produit.prix:,}".replace(",", " ")
        total_str = f"{total:,}".replace(",", " ")
        
        texte_auto = f"🛒 NOUVELLE COMMANDE : {produit.nom} x{quantite} au prix unitaire de {prix_unitaire_str} FCFA (total : {total_str} FCFA). En attente de confirmation."
        
        premier_message = Message(order_id=nouvelle_commande.id, expediteur_id=user_id, contenu=texte_auto)
        db.session.add(premier_message)
        db.session.commit()
        
        return jsonify({"message": "Commande validée !", "order_id": nouvelle_commande.id}), 201
@app.route('/api/orders/<int:order_id>/messages', methods=['GET'])
@jwt_required()
def get_order_messages(order_id):
    user_id = int(get_jwt_identity())
    current_user = db.session.get(User, user_id)
    commande = db.session.get(Order, order_id)
    
    if not commande:
        return jsonify({"erreur": "Commande introuvable"}), 404
        
    # --- NOUVELLE LOGIQUE D'ACCÈS ---
    est_client = (commande.client_id == user_id)
    est_vendeur_assigne = (commande.vendeur_id == user_id)
    est_admin_global = (commande.vendeur_id is None and current_user.role == 'admin')
    
    if not (est_client or est_vendeur_assigne or est_admin_global):
        return jsonify({"erreur": "Accès refusé. Ce chat est privé."}), 403
    # --------------------------------
        
    messages = Message.query.filter_by(order_id=order_id).order_by(Message.timestamp.asc()).all()
    historique = []
    messages_modifies = False
    
    for msg in messages:
        if msg.expediteur_id != user_id and not msg.lu:
            msg.lu = True
            messages_modifies = True
            
        expediteur = db.session.get(User, msg.expediteur_id)
        historique.append({
            "id": msg.id,
            "expediteur_id": msg.expediteur_id,
            "expediteur_nom": expediteur.nom if expediteur else "Inconnu",
            "contenu": msg.contenu,
            "lu": msg.lu,
            "date": msg.timestamp.strftime("%Y-%m-%d %H:%M:%S")
        })
        
    if messages_modifies:
        db.session.commit()
        
    return jsonify({
        "commande_id": commande.id, 
        "produit_id": commande.produit_id, 
        "statut": commande.statut, 
        "messages": historique
    }), 200

@app.route('/api/orders/unread-count', methods=['GET'])
@jwt_required()
def get_unread_count():
    user_id = int(get_jwt_identity())
    
    commandes = Order.query.filter(
        (Order.client_id == user_id) | (Order.vendeur_id == user_id)
    ).all()
    
    order_ids = [cmd.id for cmd in commandes]
    
    if not order_ids:
        return jsonify({"total": 0, "par_commande": {}}), 200
        
    messages_non_lus = Message.query.filter(
        Message.order_id.in_(order_ids),
        Message.expediteur_id != user_id,
        Message.lu == False
    ).all()
    
    total = len(messages_non_lus)
    par_commande = {}
    
    for msg in messages_non_lus:
        str_order_id = str(msg.order_id)
        if str_order_id in par_commande:
            par_commande[str_order_id] += 1
        else:
            par_commande[str_order_id] = 1
            
    return jsonify({
        "total": total,
        "par_commande": par_commande
    }), 200

@app.route('/api/orders/<int:order_id>/messages', methods=['POST'])
@jwt_required()
def send_message(order_id):
    user_id = int(get_jwt_identity())
    current_user = db.session.get(User, user_id)
    commande = db.session.get(Order, order_id)
    
    if not commande:
        return jsonify({"erreur": "Commande introuvable"}), 404
        
    # --- NOUVELLE LOGIQUE D'ACCÈS ---
    est_client = (commande.client_id == user_id)
    est_vendeur_assigne = (commande.vendeur_id == user_id)
    est_admin_global = (commande.vendeur_id is None and current_user.role == 'admin')
    
    if not (est_client or est_vendeur_assigne or est_admin_global):
        return jsonify({"erreur": "Accès refusé. Ce chat est privé."}), 403
    # --------------------------------
        
    data = request.get_json()
    contenu = data.get('contenu')
    if not contenu:
        return jsonify({"erreur": "Le message ne peut pas être vide"}), 400
        
    nouveau_message = Message(order_id=order_id, expediteur_id=user_id, contenu=contenu)
    db.session.add(nouveau_message)
    
    # Note : Assure-toi que cette ligne correspond bien à ton nouveau statut "Commande passée" 
    # si tu l'avais modifié dans un prompt précédent, par exemple : 
    # if current_user.role == 'admin' and commande.statut == 'Commande passée':
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