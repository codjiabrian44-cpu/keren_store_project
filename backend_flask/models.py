from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

# Table des Utilisateurs
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    nom = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    mot_de_passe = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='client') # 'client' ou 'admin'
    etoiles = db.Column(db.Integer, default=2) 
    date_creation = db.Column(db.DateTime, default=datetime.utcnow)

# Table des Produits (L'unique table professionnelle)
class Product(db.Model):
    __tablename__ = 'products'
    
    id = db.Column(db.Integer, primary_key=True)
    nom = db.Column(db.String(200), nullable=False)
    marque = db.Column(db.String(50), nullable=False) # Ex: HP, Dell, Lenovo
    categorie = db.Column(db.String(50), nullable=False) # Gaming, UltraBook, etc.
    prix = db.Column(db.Integer, nullable=False)
    description = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.String(255), nullable=True)
    en_stock = db.Column(db.Boolean, default=True)
    
    # --- Colonnes strictes ---
    ram_go = db.Column(db.Integer, nullable=False)
    stockage_go = db.Column(db.Integer, nullable=False)
    type_stockage = db.Column(db.String(20), nullable=False)
    processeur = db.Column(db.String(100), nullable=False)
    
    # --- Champ JSON ---
    autres_specs = db.Column(db.JSON, nullable=True)
    date_ajout = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'nom': self.nom,
            'prix': f"{self.prix} FCFA",
            'icone': "laptop_windows_rounded" if self.categorie == "PC" else "devices_other_rounded"
        }

# Table des Commandes
class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.Integer, primary_key=True)
    client_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    vendeur_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    produit_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False)
    statut = db.Column(db.String(50), default='En attente') 
    date_commande = db.Column(db.DateTime, default=datetime.utcnow)

# Table des Messages
class Message(db.Model):
    __tablename__ = 'messages'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False) 
    expediteur_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    contenu = db.Column(db.Text, nullable=False)
    lu = db.Column(db.Boolean, default=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)