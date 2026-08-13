import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static const String baseUrl = 'http://127.0.0.1:5000/api/orders';

  // Fonction pour créer une commande
  static Future<Map<String, dynamic>> createOrder(int produitId) async {
    try {
      // 1. On récupère le token de session du client connecté
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {"success": false, "erreur": "Vous devez être connecté pour commander."};
      }

      // 2. On envoie la requête POST à ton API Flask
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Le passeport de sécurité
        },
        body: jsonEncode({
          'produit_id': produitId,
          'vendeur_id': 1 // 1 = L'ID de l'admin (Brian) défini dans ton seed.py
        }),
      );

      // 3. On analyse la réponse de Flask
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
 // Fonction pour récupérer l'historique des commandes de l'utilisateur
  static Future<List<dynamic>> getUserOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        print("❌ Aucun token trouvé, impossible de charger les commandes.");
        return [];
      }

      print("🔍 Requête vers Flask : GET $baseUrl");

      final response = await http.get(
        Uri.parse(baseUrl), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("📡 Code HTTP (Commandes) : ${response.statusCode}");
      print("📦 Réponse Flask (Commandes) : ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['orders'] ?? []);
      } else {
        print("⚠️ Flask a refusé de donner les commandes !");
      }
    } catch (e) {
      print('❌ Erreur de réseau ou de code: $e');
    }
    return [];
  }
}