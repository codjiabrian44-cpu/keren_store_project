import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/product_service.dart';
import '../providers/cart_provider.dart';

import 'cart_screen.dart'; 
import 'chat_screen.dart';
import 'conversations_screen.dart';
import 'profile_screen.dart';
import 'add_product_screen.dart'; 

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  List<dynamic> _produits = [];
  bool _isLoading = true; 
  
  // NOUVEAU : La variable _role est bien déclarée ici
  String _role = "client";

  @override
  void initState() {
    super.initState();
    _chargerInfos(); // Appelle d'abord le rôle
    _chargerProduits(); // Puis charge les produits
  }

  // NOUVEAU : Fonction pour récupérer le rôle depuis SharedPreferences
  Future<void> _chargerInfos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('user_role') ?? "client";
    });
  }

  // EXISTANT : (C'est la fonction que le compilateur ne trouvait plus)
  Future<void> _chargerProduits() async {
    final produits = await ProductService.getProducts();
    setState(() {
      _produits = produits;
      _isLoading = false; 
    });
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'laptop_windows_rounded': return Icons.laptop_windows_rounded;
      case 'laptop_mac_rounded': return Icons.laptop_mac_rounded;
      case 'keyboard_alt_outlined': return Icons.keyboard_alt_outlined;
      case 'mouse_rounded': return Icons.mouse_rounded;
      case 'monitor_rounded': return Icons.monitor_rounded;
      case 'headphones_rounded': return Icons.headphones_rounded;
      default: return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Keren Store",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      
      body: SafeArea(
        child: _selectedIndex == 0 
            ? _buildCatalogue(colorScheme)
            : _selectedIndex == 1
                ? ConversationsScreen() 
            : _selectedIndex == 2 
                ? CartScreen() 
                : const ProfileScreen(), 
      ),
      
      // --- LE BOUTON FLOTTANT (Visible uniquement pour les admins sur l'accueil) ---
      floatingActionButton: (_selectedIndex == 0 && _role == 'admin') 
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Navigation vers la page d'ajout
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                );
                
                // Si la page renvoie 'true' (produit ajouté), on rafraîchit la liste
                if (result == true) {
                  setState(() {
                    _isLoading = true;
                  });
                  _chargerProduits();
                }
              },
              backgroundColor: colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Ajouter", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            )
          : null, // S'il n'est pas admin ou pas sur l'accueil, on n'affiche rien

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: "Panier"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }

  // --- LE CATALOGUE ---
  Widget _buildCatalogue(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Découvrez nos\nmeilleurs équipements",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher un produit...",
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : _produits.isEmpty 
                ? const Center(child: Text("Aucun produit disponible."))
                : GridView.builder(
                    itemCount: _produits.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.70, 
                    ),
                    itemBuilder: (context, index) {
                      final produit = _produits[index];
                      return _buildProductCard(produit, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- LA CARTE PRODUIT ---
  Widget _buildProductCard(Map<String, dynamic> produit, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Icon(
                _getIconFromString(produit["icone"] ?? 'devices_other_rounded'), 
                size: 60,
                color: colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit["nom"] ?? "Produit inconnu",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  produit["prix"] ?? "0 FCFA",
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false).ajouterAuPanier(produit);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating, 
                          margin: const EdgeInsets.all(15), 
                          content: Text("${produit['nom']} ajouté au panier !"),
                          backgroundColor: colorScheme.primary,
                          duration: const Duration(seconds: 2), 
                          action: SnackBarAction(
                            label: 'ANNULER',
                            textColor: Colors.black,
                            onPressed: () {
                              Provider.of<CartProvider>(context, listen: false).retirerDuPanier(produit['id']);
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text("Ajouter", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}