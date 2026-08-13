import 'package:flutter/material.dart';
import 'login_screen.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Données de nos 3 pages de présentation
  final List<Map<String, dynamic>> onboardingData = [
    {
      "titre": "Bienvenue sur Keren Store",
      "description": "Découvrez notre catalogue de produits technologiques de haute qualité, sélectionnés pour vous.",
      "icone": Icons.devices_other_rounded,
    },
    {
      "titre": "Échangez avec nous",
      "description": "Fini les commandes sans suivi. Chaque achat ouvre un chat direct pour organiser votre livraison en temps réel.",
      "icone": Icons.chat_bubble_outline_rounded,
    },
    {
      "titre": "Rapide et Sécurisé",
      "description": "Validez votre panier, choisissez votre mode de paiement et recevez votre commande en toute sérénité.",
      "icone": Icons.local_shipping_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Le bouton "Passer" en haut à droite
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
               onPressed: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
},
                child: Text(
                  "Passer",
                  style: TextStyle(color: colorScheme.secondary),
                ),
              ),
            ),
            
            // Le contenu défilant (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  icone: onboardingData[index]["icone"],
                  titre: onboardingData[index]["titre"],
                  description: onboardingData[index]["description"],
                ),
              ),
            ),
            
            // Les points de navigation et le bouton Suivant
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Génération des petits points
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index, context),
                    ),
                  ),
                  
                  // Bouton Suivant / Commencer
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
} else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(_currentPage == onboardingData.length - 1 ? "Commencer" : "Suivant"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour créer les petits points de pagination
  AnimatedContainer buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Widget pour le contenu visuel d'une page
class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.icone,
    required this.titre,
    required this.description,
  });

  final IconData icone;
  final String titre, description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icone,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 40),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}