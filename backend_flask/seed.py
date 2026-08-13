from app import app
from models import db, User, Product
from werkzeug.security import generate_password_hash

def seed_admins():
    with app.app_context():
        print("Vérification des comptes administrateurs...")

        admin_brian = User.query.filter_by(email='codjiabrian44@gmail.com').first()
        admin_sara = User.query.filter_by(email='hsaraounia@gmail.com').first()

        if not admin_brian:
            brian = User(
                nom='Brian',
                email='codjiabrian44@gmail.com',
                mot_de_passe=generate_password_hash('KerenAdmin2026!'),
                role='admin',
                etoiles=5
            )
            db.session.add(brian)
            print("✅ Compte Admin [Brian] préparé.")
        else:
            print("ℹ️ Le compte Admin [Brian] existe déjà.")

        if not admin_sara:
            sara = User(
                nom='Saraounia',
                email='hsaraounia@gmail.com',
                mot_de_passe=generate_password_hash('KerenAdmin2026!'),
                role='admin',
                etoiles=5
            )
            db.session.add(sara)
            print("✅ Compte Admin [Saraounia] préparé.")
        else:
            print("ℹ️ Le compte Admin [Saraounia] existe déjà.")

        db.session.commit()
        print("🚀 Initialisation des administrateurs terminée !")

def seed_products():
    with app.app_context():
        print("Vérification du catalogue de produits...")
        
        if Product.query.count() == 0:
            print("Ajout des produits initiaux...")
            produits_initiaux = [
                Product(
                    nom="Lenovo ThinkPad T14", marque="Lenovo", categorie="PC", prix=450000, 
                    description="Idéal pour les développeurs.", ram_go=16, stockage_go=512, 
                    type_stockage="SSD", processeur="Intel Core i5"
                ),
                Product(
                    nom="MacBook Pro M2", marque="Apple", categorie="PC", prix=850000, 
                    description="Puissance et autonomie.", ram_go=8, stockage_go=256, 
                    type_stockage="SSD", processeur="Apple M2"
                )
            ]
            
            db.session.bulk_save_objects(produits_initiaux)
            db.session.commit()
            print("✅ Les produits ont été ajoutés avec succès !")
        else:
            print("ℹ️ Le catalogue contient déjà des produits.")

if __name__ == '__main__':
    seed_admins()
    seed_products()