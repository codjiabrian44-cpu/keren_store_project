import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  // L'adresse de ton API Flask pour récupérer les produits
  static const String baseUrl = 'http://127.0.0.1:5000/api/products';

  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // On convertit la réponse JSON (texte) en liste Dart utilisable
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
}