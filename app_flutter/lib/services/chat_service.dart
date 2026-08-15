import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = 'https://keren-store-api.onrender.com/api/orders';

  // 1. Récupérer l'historique de la conversation
 static Future<List<dynamic>> getMessages(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$orderId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // --- AJOUT DES PRINTS DE DÉBOGAGE ---
      print("🔍 Requête vers Flask : GET /api/orders/$orderId/messages");
      print("📡 Code de réponse Flask : ${response.statusCode}");
      print("📦 Contenu de la réponse : ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['messages'];
      }
    } catch (e) {
      print("Erreur de chargement des messages: $e");
    }
    return [];
  }

  // 2. Envoyer un nouveau message
  static Future<bool> sendMessage(int orderId, String contenu) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$orderId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'contenu': contenu}),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print("Erreur d'envoi: $e");
      return false;
    }
  }
}