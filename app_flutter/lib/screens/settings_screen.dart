import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; 
import 'legal_screen.dart'; // <-- NOUVEL IMPORT DE TA VRAIE PAGE LÉGALE

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifPushActive = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Charge l'état de la préférence depuis SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifPushActive = prefs.getBool('notif_push_active') ?? true;
    });
  }

  // Sauvegarde la préférence et met à jour l'état
  Future<void> _toggleNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_push_active', value);
    setState(() {
      _notifPushActive = value;
    });
  }

  // Affiche un SnackBar "Bientôt disponible"
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Bientôt disponible"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Paramètres", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          
          // --- SECTION AFFICHAGE ---
          _buildSectionTitle("Affichage", colorScheme),
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SwitchListTile(
              title: const Text("Mode sombre", style: TextStyle(fontWeight: FontWeight.w600)),
              secondary: Icon(Icons.dark_mode_outlined, color: colorScheme.primary),
              activeColor: colorScheme.primary,
              value: isDark,
              onChanged: (value) {
                // Utilisation de ton ThemeProvider existant
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
              },
            ),
          ),
          const SizedBox(height: 25),

          // --- SECTION NOTIFICATIONS ---
          _buildSectionTitle("Notifications", colorScheme),
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SwitchListTile(
              title: const Text("Notifications push", style: TextStyle(fontWeight: FontWeight.w600)),
              secondary: Icon(Icons.notifications_active_outlined, color: colorScheme.primary),
              activeColor: colorScheme.primary,
              value: _notifPushActive,
              onChanged: _toggleNotif,
            ),
          ),
          const SizedBox(height: 25),

          // --- SECTION LANGUE & SÉCURITÉ ---
          _buildSectionTitle("Général & Sécurité", colorScheme),
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_outlined, color: colorScheme.primary),
                  title: const Text("Langue", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Français", style: TextStyle(color: Colors.grey)),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: _showComingSoon,
                ),
                Divider(height: 1, indent: 50, color: Colors.grey.withOpacity(0.2)),
                ListTile(
                  leading: Icon(Icons.lock_outline, color: colorScheme.primary),
                  title: const Text("Changer le mot de passe", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: _showComingSoon,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // --- SECTION À PROPOS & LÉGAL ---
          _buildSectionTitle("Informations", colorScheme),
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: colorScheme.primary),
                  title: const Text("À propos de Keren Store", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Version 1.0.0\nby Brian & Sara", style: TextStyle(height: 1.5)),
                ),
                Divider(height: 1, indent: 50, color: Colors.grey.withOpacity(0.2)),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
                  title: const Text("Confidentialité & Conditions", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // Maintenant cela navigue vers ta vraie page LegalScreen !
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget utilitaire pour les titres de sections
  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}