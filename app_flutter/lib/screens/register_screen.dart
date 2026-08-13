import 'package:flutter/material.dart';
import 'login_screen.dart'; // Pour pouvoir y retourner
import '../services/auth_service.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 80,
                    color: colorScheme.secondary, // On utilise le violet pour différencier
                  ),
                  const SizedBox(height: 30),
                  
                  // Titre
                  const Text(
                    "Créer un compte",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Rejoignez Keren Store dès aujourd'hui",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Champ Nom
                  TextFormField(
                    controller: _nomController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: "Nom complet",
                      prefixIcon: Icon(Icons.person_outline, color: colorScheme.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colorScheme.secondary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Adresse e-mail",
                      prefixIcon: Icon(Icons.email_outlined, color: colorScheme.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colorScheme.secondary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.secondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colorScheme.secondary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Bouton d'Inscription
                  ElevatedButton(
                    onPressed: _isLoading 
                      ? null 
                      : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });

                        // Appel à l'API Flask
                        final response = await AuthService.register(
                          _nomController.text,
                          _emailController.text,
                          _passwordController.text,
                        );

                        setState(() {
                          _isLoading = false;
                        });

                        // Traitement de la réponse
                        if (response.containsKey('message')) {
                          // Succès : Affichage d'un message vert
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['message']),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Retour à la page de connexion
                          Navigator.pop(context);
                        } else if (response.containsKey('erreur')) {
                          // Échec : Affichage d'un message rouge
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['erreur']),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
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
                            "S'inscrire",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  // Lien pour retourner à la connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Déjà un compte ? "),
                      GestureDetector(
                        onTap: () {
                          // Retour à la page précédente (Login)
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Se connecter",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}