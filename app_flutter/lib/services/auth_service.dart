import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // L'application Linux et le serveur Flask sont sur la même machine
  static const String baseUrl = 'https://keren-store-api.onrender.com/api/auth';

  // --- INSCRIPTION ---
  static Future<Map<String, dynamic>> register(String nom, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'email': email,
          'mot_de_passe': password,
          'role': 'client' // Par défaut, un nouvel inscrit est un client
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'erreur': 'Impossible de se connecter au serveur : $e'};
    }
  }

  // --- CONNEXION ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'mot_de_passe': password,
        }),
      );

      final data = jsonDecode(response.body);

      // Sauvegarde du Token JWT et des infos utilisateur si succès
      if (response.statusCode == 200 && data.containsKey('access_token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        await prefs.setInt('user_id', data['utilisateur']['id']);
        await prefs.setString('user_role', data['utilisateur']['role']);
        await prefs.setString('user_nom', data['utilisateur']['nom']);
      }

      return data;
    } catch (e) {
      return {'erreur': 'Impossible de se connecter au serveur : $e'};
    }
  }
}