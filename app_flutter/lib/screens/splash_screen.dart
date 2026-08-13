import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../main.dart'; // Permet d'accéder au ThemeProvider pour le bouton
import 'onboarding_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Retour à un délai de 3 secondes
    Timer(const Duration(seconds: 7), () {
      // Navigation vers l'Onboarding en remplaçant la page actuelle
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. On détecte si on est en Dark Mode ou Light Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        // Stack permet de superposer des éléments (ici, le bouton par-dessus l'écran)
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 20),
                
                // 2. Le Logo dynamique (Change selon le thème)
                Center(
                  child: Image.asset(
                    isDark 
                        ? 'assets/images/keren_store_logo_transparent.png' 
                        : 'assets/images/keren_store.png',
                    width: MediaQuery.of(context).size.width * 0.75,
                    fit: BoxFit.contain,
                  ),
                ),
                
                // 3. Le footer (Indicateur + Signature)
                Column(
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary, 
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'by Brian & Sara',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5, 
                        color: Theme.of(context).colorScheme.secondary, 
                      ),
                    ),
                    const SizedBox(height: 30), 
                  ],
                ),
              ],
            ),

            // 4. Le bouton de test de thème (Professionnel et discret)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                color: Theme.of(context).colorScheme.primary,
                iconSize: 28,
                onPressed: () {
                  // Bascule entre Dark et Light
                  themeProvider.toggleTheme(!isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}