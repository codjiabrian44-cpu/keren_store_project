import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart'; 

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
                      setState(() {
                        _isProcessing = true; 
                      });

                      bool allSuccess = true;
                      String errorMessage = "";
                      
                      // --- LA MODIFICATION EST ICI ---
                      int idDeMaCommande = 0; 

                      for (var productId in cart.items.keys) {
                        final response = await OrderService.createOrder(productId);
                        if (response['success'] != true) {
                          allSuccess = false;
                          errorMessage = response['erreur'];
                          break;
                        } else {
                          // On récupère l'ID exact que Flask vient de créer !
                          idDeMaCommande = response['order_id']; 
                        }
                      }

                      setState(() {
                        _isProcessing = false; 
                      });

                      if (allSuccess) {
                        cart.viderPanier();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              // --- ET ON L'AFFICHE ICI ---
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
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isProcessing 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
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