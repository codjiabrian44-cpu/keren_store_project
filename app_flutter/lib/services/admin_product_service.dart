import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminProductService {
  static const String baseUrl = 'http://127.0.0.1:5000/api/products';

  // --- AJOUTER UN PRODUIT ---
  static Future<Map<String, dynamic>> ajouterProduit({
    required String nom,
    required String marque,
    required String categorie,
    required int prix,
    required String description,
    required int ramGo,
    required int stockageGo,
    required String typeStockage,
    required String processeur,
    File? imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {'success': false, 'erreur': 'Non autorisé. Token introuvable.'};
      }

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      
      // Ajout du header d'autorisation
      request.headers['Authorization'] = 'Bearer $token';

      // Ajout des champs textes (MultipartRequest.fields n'accepte que des Strings)
      request.fields['nom'] = nom;
      request.fields['marque'] = marque;
      request.fields['categorie'] = categorie;
      request.fields['prix'] = prix.toString();
      request.fields['description'] = description;
      request.fields['ram_go'] = ramGo.toString();
      request.fields['stockage_go'] = stockageGo.toString();
      request.fields['type_stockage'] = typeStockage;
      request.fields['processeur'] = processeur;

      // Ajout du fichier image s'il est fourni
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      // Envoi de la requête et récupération de la réponse
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      var data = jsonDecode(response.body);

      // On ajoute un booléen de succès pour faciliter la gestion côté UI
      if (response.statusCode == 201) {
        data['success'] = true;
      } else {
        data['success'] = false;
      }

      return data;
    } catch (e) {
      return {'success': false, 'erreur': 'Impossible de se connecter au serveur : $e'};
    }
  }

  // --- MODIFIER UN PRODUIT ---
  static Future<Map<String, dynamic>> modifierProduit({
    required int productId,
    required String nom,
    required String marque,
    required String categorie,
    required int prix,
    required String description,
    required int ramGo,
    required int stockageGo,
    required String typeStockage,
    required String processeur,
    File? imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {'success': false, 'erreur': 'Non autorisé. Token introuvable.'};
      }

      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/$productId'));
      
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['nom'] = nom;
      request.fields['marque'] = marque;
      request.fields['categorie'] = categorie;
      request.fields['prix'] = prix.toString();
      request.fields['description'] = description;
      request.fields['ram_go'] = ramGo.toString();
      request.fields['stockage_go'] = stockageGo.toString();
      request.fields['type_stockage'] = typeStockage;
      request.fields['processeur'] = processeur;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        data['success'] = true;
      } else {
        data['success'] = false;
      }

      return data;
    } catch (e) {
      return {'success': false, 'erreur': 'Impossible de se connecter au serveur : $e'};
    }
  }

  // --- SUPPRIMER UN PRODUIT ---
  static Future<bool> supprimerProduit(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Renvoie true si la suppression a réussi (200 OK)
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erreur lors de la suppression: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Impossible de se connecter au serveur pour la suppression : $e');
      return false;
    }
  }
}