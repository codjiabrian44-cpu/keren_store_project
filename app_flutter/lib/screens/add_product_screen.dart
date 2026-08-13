import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  File? _imageFile;

  // Contrôleurs de texte
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _marqueCtrl = TextEditingController();
  final TextEditingController _prixCtrl = TextEditingController();
  final TextEditingController _ramCtrl = TextEditingController();
  final TextEditingController _stockageCtrl = TextEditingController();
  final TextEditingController _processeurCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  // Valeurs par défaut des menus déroulants
  String _categorie = "Portables";
  String _typeStockage = "SSD";

  final List<String> _categories = [
    "Portables", "Desktop", "Gaming", "UltraBook", "Stations de travail", "Accessoires"
  ];
  final List<String> _typesStockage = ["SSD", "HDD", "eMMC"];

  @override
  void dispose() {
    _nomCtrl.dispose();
    _marqueCtrl.dispose();
    _prixCtrl.dispose();
    _ramCtrl.dispose();
    _stockageCtrl.dispose();
    _processeurCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await AdminProductService.ajouterProduit(
        nom: _nomCtrl.text.trim(),
        marque: _marqueCtrl.text.trim(),
        categorie: _categorie,
        prix: int.parse(_prixCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        ramGo: int.parse(_ramCtrl.text.trim()),
        stockageGo: int.parse(_stockageCtrl.text.trim()),
        typeStockage: _typeStockage,
        processeur: _processeurCtrl.text.trim(),
        imageFile: _imageFile,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Produit ajouté avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true indique qu'il faut rafraîchir la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['erreur'] ?? "Erreur lors de l'ajout"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget utilitaire pour générer les champs textes avec le même style que register_screen
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: maxLines > 1 ? null : Icon(icon, color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        validator: isRequired 
            ? (value) {
                if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
                if (keyboardType == TextInputType.number && int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ajouter un produit", 
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0), // Même padding que RegisterScreen
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- SÉLECTEUR D'IMAGE ---
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.5), 
                        width: 2, 
                        style: BorderStyle.solid
                      ),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, size: 50, color: colorScheme.primary),
                              const SizedBox(height: 10),
                              Text(
                                "Choisir une photo",
                                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "(Optionnel)",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- CHAMPS DU FORMULAIRE ---
                _buildTextField(controller: _nomCtrl, label: "Nom du produit", icon: Icons.devices),
                _buildTextField(controller: _marqueCtrl, label: "Marque (ex: HP, Dell)", icon: Icons.branding_watermark),
                _buildTextField(controller: _prixCtrl, label: "Prix (FCFA)", icon: Icons.attach_money, keyboardType: TextInputType.number),
                
                // Dropdown Catégorie
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: DropdownButtonFormField<String>(
                    value: _categorie,
                    decoration: InputDecoration(
                      labelText: "Catégorie",
                      prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setState(() => _categorie = val!),
                  ),
                ),

                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _ramCtrl, label: "RAM (Go)", icon: Icons.memory, keyboardType: TextInputType.number)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTextField(controller: _stockageCtrl, label: "Stockage (Go)", icon: Icons.storage, keyboardType: TextInputType.number)),
                  ],
                ),

                // Dropdown Type de stockage
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: DropdownButtonFormField<String>(
                    value: _typeStockage,
                    decoration: InputDecoration(
                      labelText: "Type de stockage",
                      prefixIcon: Icon(Icons.save_outlined, color: colorScheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    items: _typesStockage.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) => setState(() => _typeStockage = val!),
                  ),
                ),

                _buildTextField(controller: _processeurCtrl, label: "Processeur", icon: Icons.developer_board),
                _buildTextField(controller: _descCtrl, label: "Description (Optionnelle)", icon: Icons.description, maxLines: 3, isRequired: false),

                const SizedBox(height: 10),

                // --- BOUTON DE SOUMISSION ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text(
                          "Ajouter au catalogue",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}