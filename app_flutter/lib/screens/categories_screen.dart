import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {"nom": "Portables", "icone": Icons.laptop_windows_rounded},
    {"nom": "Desktop", "icone": Icons.desktop_windows_rounded},
    {"nom": "Gaming", "icone": Icons.sports_esports_rounded},
    {"nom": "UltraBook", "icone": Icons.laptop_mac_rounded},
    {"nom": "Stations de travail", "icone": Icons.computer_rounded},
    {"nom": "Accessoires", "icone": Icons.mouse_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Catégories", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.0, 
          ),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CategoryProductsScreen(categorie: cat['nom'])),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat['icone'], size: 40, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      cat['nom'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


// --- ÉCRAN DES RÉSULTATS FILTRÉS ---
class CategoryProductsScreen extends StatefulWidget {
  final String categorie;
  const CategoryProductsScreen({super.key, required this.categorie});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<dynamic> _produits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerProduitsParCategorie();
  }

  Future<void> _chargerProduitsParCategorie() async {
    // Appel à l'API avec le paramètre de catégorie
    final produits = await ProductService.getProducts(widget.categorie);
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
      case 'sports_esports_rounded': return Icons.sports_esports_rounded;
      case 'desktop_windows_rounded': return Icons.desktop_windows_rounded;
      default: return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categorie, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : _produits.isEmpty
                ? const Center(child: Text("Aucun produit dans cette catégorie.", style: TextStyle(fontSize: 16, color: Colors.grey)))
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
                      return _buildProductCard(produit, colorScheme, context);
                    },
                  ),
        ),
      ),
    );
  }

  // Identique à la carte de home_screen
  Widget _buildProductCard(Map<String, dynamic> produit, ColorScheme colorScheme, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: produit['id'])),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
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
                  Text(produit["nom"] ?? "Inconnu", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(produit["prix_affiche"] ?? "${produit["prix"]} FCFA", style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<CartProvider>(context, listen: false).ajouterAuPanier(produit);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${produit['nom']} ajouté au panier !"),
                            backgroundColor: colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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