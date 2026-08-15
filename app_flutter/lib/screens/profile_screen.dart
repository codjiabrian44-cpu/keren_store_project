import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nom = "Chargement...";
  String _role = "";

  @override
  void initState() {
    super.initState();
    _chargerInfos();
  }

  Future<void> _chargerInfos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nom = prefs.getString('user_nom') ?? "Utilisateur inconnu";
      _role = prefs.getString('user_role') ?? "client";
    });
  }

  Future<void> _seDeconnecter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // On supprime le token et les infos

    if (mounted) {
      // On redirige vers l'écran de connexion (qui doit être ta route '/')
      // Cela efface aussi l'historique de navigation
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Ajout du Scaffold et de l'AppBar pour les paramètres
    return Scaffold(
      backgroundColor: Colors.transparent, // Pour s'intégrer au Scaffold parent si nécessaire
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Mon Profil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colorScheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                child: Icon(
                  _role == 'admin' ? Icons.admin_panel_settings : Icons.person, 
                  size: 50, 
                  color: colorScheme.primary
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _nom,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _role == 'admin' ? Colors.redAccent.withOpacity(0.2) : colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _role.toUpperCase(),
                  style: TextStyle(
                    color: _role == 'admin' ? Colors.redAccent : colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _seDeconnecter,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Se déconnecter", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}