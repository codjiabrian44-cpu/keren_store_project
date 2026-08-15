import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../services/admin_service.dart'; // NOUVEL IMPORT

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false; 

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Mon Panier",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        Expanded(
          child: cart.items.isEmpty
              ? const Center(
                  child: Text(
                    "Votre panier est vide.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    int productId = cart.items.keys.elementAt(index);
                    CartItem item = cart.items[productId]!;

                    return Card(
                      color: colorScheme.surface,
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.computer, color: colorScheme.primary),
                        ),
                        title: Text(
                          item.produit['nom'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${item.produit['prix']}  (x${item.quantite})",
                          style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            cart.retirerDuPanier(productId);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total à payer", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(
                    "${cart.totalAmount} FCFA",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: (cart.items.isEmpty || _isProcessing)
                  ? null 
                  : () async {
                      // 1. On charge la liste des admins
                      setState(() { _isProcessing = true; });
                      final admins = await AdminService.getAdmins();
                      setState(() { _isProcessing = false; });

                      if (admins.isEmpty && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Erreur: Impossible de charger les vendeurs disponibles."),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      // 2. On affiche le BottomSheet pour choisir le vendeur
                      if (!mounted) return;
                      int? choixVendeur = await showModalBottomSheet<int>(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                        ),
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    "Choisissez un vendeur", 
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                ),
                                // Rendu dynamique de la liste des admins
                                ...admins.map((admin) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                                    child: Icon(Icons.person, color: colorScheme.primary),
                                  ),
                                  title: Text(admin['nom'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () => Navigator.pop(context, admin['id']), // Renvoie l'ID
                                )),
                                const Divider(),
                                // Option "Peu importe"
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.secondary.withOpacity(0.2),
                                    child: Icon(Icons.group, color: colorScheme.secondary),
                                  ),
                                  title: const Text("Peu importe (envoyer aux deux)", style: TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () => Navigator.pop(context, -1), // -1 sert de drapeau pour "null"
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        }
                      );

                      // Si l'utilisateur ferme le bottom sheet sans choisir
                      if (choixVendeur == null) return;

                      // Conversion du choix : -1 devient null (Peu importe)
                      int? finalVendeurId = (choixVendeur == -1) ? null : choixVendeur;

                      // 3. On procède à la commande
                      setState(() { _isProcessing = true; });

                      bool allSuccess = true;
                      String errorMessage = "";
                      int idDeMaCommande = 0; 

                      for (var productId in cart.items.keys) {
                        final item = cart.items[productId]!; 
                        
                        // Appel mis à jour avec la quantité ET le finalVendeurId
                        final response = await OrderService.createOrder(productId, item.quantite, finalVendeurId);
                        
                        if (response['success'] != true) {
                          allSuccess = false;
                          errorMessage = response['erreur'];
                          break;
                        } else {
                          idDeMaCommande = response['order_id']; 
                        }
                      }

                      setState(() { _isProcessing = false; });

                      if (allSuccess) {
                        cart.viderPanier();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Commande validée ! Ton ID est le #$idDeMaCommande", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              backgroundColor: Colors.green, 
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erreur : $errorMessage"),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isProcessing 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text(
                      "Commander",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              )
            ],
          ),
        )
      ],
    );
  }
}