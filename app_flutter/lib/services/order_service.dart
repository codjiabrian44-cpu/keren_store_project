import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static const String baseUrl = 'https://keren-store-api.onrender.com/api/orders';

  // Fonction pour créer une commande (ajout du vendeurId nullable)
  static Future<Map<String, dynamic>> createOrder(int produitId, int quantite, int? vendeurId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {"success": false, "erreur": "Vous devez être connecté pour commander."};
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
        body: jsonEncode({
          'produit_id': produitId,
          'vendeur_id': vendeurId, // Sera null si "Peu importe" a été choisi
          'quantite': quantite 
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          "success": true, 
          "order_id": data['order_id'], 
          "message": data['message']
        };
      } else {
        return {
          "success": false, 
          "erreur": data['erreur'] ?? "Erreur serveur"
        };
      }
    } catch (e) {
      print('Erreur API Order: $e');
      return {"success": false, "erreur": "Impossible de joindre le serveur."};
    }
  }
 
  static Future<List<dynamic>> getUserOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        print("❌ Aucun token trouvé, impossible de charger les commandes.");
        return [];
      }

      final response = await http.get(
        Uri.parse(baseUrl), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['orders'] ?? []);
      }
    } catch (e) {
      print('❌ Erreur de réseau ou de code: $e');
    }
    return [];
  }
  // Fonction pour mettre à jour le statut d'une commande (Admin uniquement)
  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String statut) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {"success": false, "erreur": "Non autorisé."};
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/statut'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'statut': statut}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true, 
          "message": data['message'],
          "statut": data['statut']
        };
      } else {
        return {
          "success": false, 
          "erreur": data['erreur'] ?? "Erreur serveur"
        };
      }
    } catch (e) {
      print('Erreur API Update Order: $e');
      return {"success": false, "erreur": "Impossible de joindre le serveur."};
    }
  }
}