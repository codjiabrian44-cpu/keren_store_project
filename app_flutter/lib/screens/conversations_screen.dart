import 'package:flutter/material.dart';
import '../services/order_service.dart';
import 'chat_screen.dart';
import 'order_tracking_screen.dart'; // NOUVEL IMPORT

class ConversationsScreen extends StatefulWidget {
  ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerCommandes();
  }

  Future<void> _chargerCommandes() async {
    final orders = await OrderService.getUserOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(15),
          width: double.infinity,
          color: colorScheme.surface,
          child: Text(
            "Mes Messages",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : _orders.isEmpty
                  ? Center(child: Text("Vous n'avez aucune conversation en cours."))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final orderId = order['id'] ?? order['order_id'];
                        final status = order['statut'] ?? "En cours";

                        return Card(
                          color: colorScheme.surface,
                          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primary.withOpacity(0.2),
                              child: Icon(Icons.shopping_bag, color: colorScheme.primary),
                            ),
                            title: Text(
                              "Commande #$orderId",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Statut : $status", style: TextStyle(color: Colors.grey)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // --- NOUVEAU BOUTON SUIVI ---
                                IconButton(
                                  icon: Icon(Icons.local_shipping_outlined, color: colorScheme.secondary),
                                  tooltip: "Suivi de commande",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderTrackingScreen(
                                          orderId: orderId, 
                                          initialStatus: status
                                        ),
                                      ),
                                    ).then((_) => _chargerCommandes()); // Rafraîchir au retour
                                  },
                                ),
                                Icon(Icons.chevron_right, color: colorScheme.primary),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(orderId: orderId),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}