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
        # Détermination de l'icône selon la catégorie
        if self.categorie in ["Portables", "UltraBook"]:
            icone = "laptop_windows_rounded"
        elif self.categorie in ["Desktop", "Stations de travail"]:
            icone = "desktop_windows_rounded"
        elif self.categorie == "Gaming":
            icone = "sports_esports_rounded"
        elif self.categorie == "Accessoires":
            icone = "mouse_rounded"
        else:
            icone = "devices_other_rounded"

        return {
            'id': self.id,
            'nom': self.nom,
            'marque': self.marque,
            'categorie': self.categorie,
            'prix': self.prix,
            'prix_affiche': f"{self.prix:,}".replace(",", " ") + " FCFA",
            'description': self.description,
            'image_url': self.image_url if self.image_url else None,
            'en_stock': self.en_stock,
            'ram_go': self.ram_go,
            'stockage_go': self.stockage_go,
            'type_stockage': self.type_stockage,
            'processeur': self.processeur,
            'autres_specs': self.autres_specs,
            'date_ajout': self.date_ajout.isoformat() if self.date_ajout else None,
            'icone': icone
        }

# Table des Commandes
class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.Integer, primary_key=True)
    client_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    vendeur_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    produit_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False)
    quantite = db.Column(db.Integer, default=1, nullable=False)
    # Remplacement de 'En attente' par 'Commande passée'
    statut = db.Column(db.String(50), default='Commande passée') 
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

# Table des Avis (Reviews)
class Review(db.Model):
    __tablename__ = 'reviews'
    
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False)
    client_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False)
    note = db.Column(db.Integer, nullable=False)
    commentaire = db.Column(db.Text, nullable=True)
    date_avis = db.Column(db.DateTime, default=datetime.utcnow)