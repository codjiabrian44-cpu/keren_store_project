import 'package:flutter/material.dart';

// 1. Modèle pour représenter un article dans le panier (le produit + sa quantité)
class CartItem {
  final Map<String, dynamic> produit;
  int quantite;

  CartItem({required this.produit, this.quantite = 1});
}

// 2. Le Gestionnaire d'état du Panier
class CartProvider with ChangeNotifier {
  // La liste qui contient tous les articles du panier
  final Map<int, CartItem> _items = {};

  // Récupérer la liste des articles
  Map<int, CartItem> get items => _items;

  // Récupérer le nombre total d'articles (pour afficher un petit badge sur l'icône plus tard)
  int get itemCount {
    int count = 0;
    _items.forEach((key, item) => count += item.quantite);
    return count;
  }

  // Calculer le prix total du panier
  int get totalAmount {
    int total = 0;
    _items.forEach((key, item) {
      // Le backend envoie "450000 FCFA". On extrait juste les chiffres pour le calcul.
      String prixTexte = item.produit['prix'].toString().replaceAll(' FCFA', '').replaceAll(' ', '');
      int prixUnitaire = int.tryParse(prixTexte) ?? 0;
      total += prixUnitaire * item.quantite;
    });
    return total;
  }

  // Ajouter un produit au panier
  void ajouterAuPanier(Map<String, dynamic> produit) {
    int productId = produit['id'];

    if (_items.containsKey(productId)) {
      // Si le produit est déjà dans le panier, on augmente juste la quantité
      _items[productId]!.quantite += 1;
    } else {
      // Sinon, on l'ajoute comme nouvel article
      _items[productId] = CartItem(produit: produit);
    }
    
    // Alerte toute l'application que le panier a changé
    notifyListeners();
  }

  // Retirer complètement un produit
  void retirerDuPanier(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Vider le panier (après une commande)
  void viderPanier() {
    _items.clear();
    notifyListeners();
  }
}