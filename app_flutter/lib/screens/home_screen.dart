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
import 'product_detail_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  List<dynamic> _produits = [];
  bool _isLoading = true; 
  
  String _role = "client";

  final TextEditingController _rechercheController = TextEditingController();
  String _termeRecherche = "";

  @override
  void initState() {
    super.initState();
    _chargerInfos(); 
    _chargerProduits(); 
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerInfos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('user_role') ?? "client";
    });
  }

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

  String _sansAccents(String texte) {
    var avec = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    var sans = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < avec.length; i++) {
      texte = texte.replaceAll(avec[i], sans[i]);
    }
    return texte;
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
      
      floatingActionButton: (_selectedIndex == 0 && _role == 'admin') 
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                );
                
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
          : null, 

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

  Widget _buildCatalogue(ColorScheme colorScheme) {
    final String rechercheClean = _sansAccents(_termeRecherche.toLowerCase().trim());
    
    final List<dynamic> produitsFiltres = _produits.where((produit) {
      if (rechercheClean.isEmpty) return true;
      final String nom = _sansAccents((produit['nom'] ?? '').toLowerCase());
      final String marque = _sansAccents((produit['marque'] ?? '').toLowerCase());
      return nom.contains(rechercheClean) || marque.contains(rechercheClean);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Découvrez nos\nmeilleurs équipements",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 20),
          
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _rechercheController,
              onChanged: (valeur) => setState(() => _termeRecherche = valeur),
              decoration: InputDecoration(
                hintText: "Rechercher un produit...",
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _termeRecherche.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _rechercheController.clear();
                          setState(() => _termeRecherche = "");
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Liste horizontale des catégories
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip("Grille Complète", Icons.grid_view_rounded, colorScheme, isAll: true),
                _buildCategoryChip("Portables", Icons.laptop_windows_rounded, colorScheme),
                _buildCategoryChip("Desktop", Icons.desktop_windows_rounded, colorScheme),
                _buildCategoryChip("Gaming", Icons.sports_esports_rounded, colorScheme),
                _buildCategoryChip("Accessoires", Icons.mouse_rounded, colorScheme),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : _produits.isEmpty 
                ? const Center(child: Text("Aucun produit disponible dans le catalogue."))
                : produitsFiltres.isEmpty 
                    ? Center(child: Text("Aucun produit ne correspond à '$_termeRecherche'", style: const TextStyle(fontSize: 16, color: Colors.grey)))
                    : GridView.builder(
                        itemCount: produitsFiltres.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.70, 
                        ),
                        itemBuilder: (context, index) {
                          return _buildProductCard(produitsFiltres[index], colorScheme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Widget utilitaire pour les boutons de catégories
  Widget _buildCategoryChip(String titre, IconData icone, ColorScheme colorScheme, {bool isAll = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ActionChip(
        backgroundColor: isAll ? colorScheme.primary : colorScheme.surface,
        avatar: Icon(icone, size: 18, color: isAll ? Colors.white : colorScheme.primary),
        label: Text(
          titre,
          style: TextStyle(
            color: isAll ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isAll ? Colors.transparent : colorScheme.primary.withOpacity(0.2)),
        ),
        onPressed: () {
          if (isAll) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryProductsScreen(categorie: titre)));
          }
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> produit, ColorScheme colorScheme) {
    // Gestion de l'URL : on s'assure d'avoir le chemin complet vers Flask
    String? imageUrl = produit["image_url"];
    if (imageUrl != null && imageUrl.startsWith('/')) {
      imageUrl = 'https://keren-store-api.onrender.com$imageUrl';
    }

    return GestureDetector(
      onTap: () async {
        
        final bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: produit['id']),
          ),
        );
        
        // Si la page de détails renvoie true (produit supprimé), on recharge le catalogue
        if (result == true) {
          setState(() {
            _isLoading = true;
          });
          _chargerProduits();
        }
      },
      child: Container(
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
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _getIconFromString(produit["icone"] ?? 'devices_other_rounded'),
                              size: 60,
                              color: colorScheme.primary,
                            );
                          },
                        ),
                      )
                    : Icon(
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
                    produit["prix_affiche"] ?? produit["prix"]?.toString() ?? "0 FCFA",
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
      ),
    );
  }
}