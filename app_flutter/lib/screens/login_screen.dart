import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
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
                  // Icône ou Logo simplifié
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 30),
                  
                  // Titre
                  const Text(
                    "Bon retour",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Connectez-vous pour suivre vos commandes",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Adresse e-mail",
                      prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
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
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Bouton de Connexion
                  ElevatedButton(
                    onPressed: _isLoading 
                      ? null 
                      : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });

                        // Appel à l'API Flask
                        final response = await AuthService.login(
                          _emailController.text,
                          _passwordController.text,
                        );

                        setState(() {
                          _isLoading = false;
                        });

                        // Traitement de la réponse
                        if (response.containsKey('access_token')) {
                          // Succès : Redirection vers l'Accueil en détruisant l'historique de navigation
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) =>  HomeScreen()),
                            (route) => false,
                          );
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
                            "Se connecter",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  // Lien vers l'inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Nouveau sur Keren Store ? "),
                      GestureDetector(
                        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RegisterScreen()),
  );
},
                        child: Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: colorScheme.secondary,
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