import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/product_service.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _produit;
  bool _isLoading = true;
  Map<String, dynamic>? _avisData; 
  String _role = "client"; // <-- NOUVEAU : Pour stocker le rôle

  @override
  void initState() {
    super.initState();
    _chargerRole();
    _chargerProduit();
  }

  // --- NOUVEAU : Récupération du rôle pour afficher ou non le bouton supprimer ---
  Future<void> _chargerRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _role = prefs.getString('user_role') ?? "client";
      });
    }
  }

  Future<void> _chargerProduit() async {
    final produit = await ProductService.getProductById(widget.productId);
    
    // Récupération des avis
    Map<String, dynamic>? avis;
    try {
      final response = await http.get(Uri.parse('https://keren-store-api.onrender.com/api/products/${widget.productId}/reviews'));
      if (response.statusCode == 200) {
        avis = jsonDecode(response.body);
      }
    } catch (e) {
      print("Erreur chargement avis: $e");
    }

    if (mounted) {
      setState(() {
        _produit = produit;
        _avisData = avis;
        _isLoading = false;
      });
    }
  }

  // --- NOUVEAU : Fonction de suppression avec confirmation ---
  void _confirmerSuppression() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ce produit ?"),
        content: const Text("Cette action est irréversible. Le produit disparaîtra de la boutique."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx); // Ferme la boîte de dialogue
              setState(() => _isLoading = true);
              
              bool success = await ProductService.deleteProduct(widget.productId);
              
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Produit supprimé avec succès"), backgroundColor: Colors.green),
                );
                // On retourne true pour signaler à l'accueil de rafraîchir la liste
                Navigator.pop(context, true); 
              } else {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Erreur lors de la suppression"), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    if (_produit == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: const Center(child: Text("Produit introuvable ou erreur de connexion.")),
      );
    }

    String? imageUrl = _produit!['image_url'];
    if (imageUrl != null && imageUrl.startsWith('/')) {
      imageUrl = 'https://keren-store-api.onrender.com$imageUrl';
    }

    final bool enStock = _produit!['en_stock'] ?? false;
    final Map<String, dynamic> autresSpecs = _produit!['autres_specs'] ?? {};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ZONE IMAGE ---
                Container(
                  width: double.infinity,
                  height: 350,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                height: 250,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  _getIconFromString(_produit!['icone'] ?? ''),
                                  size: 100,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              _getIconFromString(_produit!['icone'] ?? ''),
                              size: 150,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                ),
                
                // --- INFORMATIONS PRINCIPALES ---
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (_produit!['marque'] ?? 'Marque inconnue').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: enStock ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              enStock ? "En stock" : "Rupture de stock",
                              style: TextStyle(
                                color: enStock ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _produit!['nom'] ?? 'Produit',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _produit!['prix_affiche'] ?? "${_produit!['prix']} FCFA",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.secondary,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- CARACTÉRISTIQUES ---
                      const Text(
                        "Caractéristiques techniques",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildSpecRow("Processeur", _produit!['processeur'], Icons.developer_board, colorScheme),
                            const Divider(height: 25),
                            _buildSpecRow("RAM", "${_produit!['ram_go']} Go", Icons.memory, colorScheme),
                            const Divider(height: 25),
                            _buildSpecRow("Stockage", "${_produit!['stockage_go']} Go ${_produit!['type_stockage']}", Icons.storage, colorScheme),
                            
                            if (autresSpecs.isNotEmpty) ...[
                              const Divider(height: 25),
                              ...autresSpecs.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildSpecRow(entry.key, entry.value.toString(), Icons.info_outline, colorScheme),
                              )),
                            ]
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- DESCRIPTION ---
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _produit!['description'] ?? 'Aucune description disponible.',
                        style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // --- NOUVELLE SECTION AVIS ---
                      const Text(
                        "Avis clients",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      
                      if (_avisData != null && _avisData!['total'] > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
                            const SizedBox(width: 5),
                            Text(
                              "${_avisData!['moyenne']} / 5",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Text("(${_avisData!['total']} avis)", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        ...(_avisData!['avis'] as List).map((avis) => Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(avis['client_nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(avis['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: List.generate(5, (index) => Icon(
                                      index < avis['note'] ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    )),
                                  ),
                                  if (avis['commentaire'] != null && avis['commentaire'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(avis['commentaire']),
                                  ]
                                ],
                              ),
                            )),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text(
                              "Aucun avis pour le moment.\nSoyez le premier à partager votre expérience après votre achat !",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- BOUTONS D'ENTÊTE (RETOUR + SUPPRIMER) ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // NOUVEAU : Bouton corbeille visible seulement pour l'admin
                  if (_role == 'admin')
                    CircleAvatar(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: _confirmerSuppression,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // --- BARRE D'ACTIONS EN BAS ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  icon: Icon(Icons.add_shopping_cart_rounded, color: colorScheme.primary),
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).ajouterAuPanier(_produit!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${_produit!['nom']} ajouté au panier !"),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).ajouterAuPanier(_produit!);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text("Finaliser la commande", style: TextStyle(color: colorScheme.primary)),
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            iconTheme: IconThemeData(color: colorScheme.primary),
                            elevation: 0,
                          ),
                          body: const SafeArea(child: CartScreen()),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Commander maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String title, String value, IconData icon, ColorScheme color) {
    return Row(
      children: [
        Icon(icon, color: color.primary.withOpacity(0.7), size: 22),
        const SizedBox(width: 15),
        Text("$title : ", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}