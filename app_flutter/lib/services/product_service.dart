import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 

class ProductService {
  static const String baseUrl = 'http://127.0.0.1:5000/api/products';

  // --- Récupérer tous les produits (avec filtre optionnel) ---
  static Future<List<dynamic>> getProducts([String? categorie]) async {
    try {
      String url = baseUrl;
      if (categorie != null && categorie.isNotEmpty) {
        url += '?categorie=${Uri.encodeComponent(categorie)}';
      }
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Erreur serveur: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur de connexion API: $e');
      return [];
    }
  }

  // --- Récupérer un produit par ID ---
  static Future<Map<String, dynamic>?> getProductById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Erreur serveur pour le produit $id: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur de connexion API pour le produit $id: $e');
      return null;
    }
  }

  // --- Supprimer un produit (Admin uniquement) ---
  static Future<bool> deleteProduct(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erreur suppression: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erreur réseau suppression: $e');
      return false;
    }
  }
}