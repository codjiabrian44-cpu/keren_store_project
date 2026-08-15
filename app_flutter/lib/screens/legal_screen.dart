import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            "Mentions Légales",
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: colorScheme.primary),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "CGU"),
              Tab(text: "Confidentialité"),
              Tab(text: "Livraison"),
              Tab(text: "Retours"),
              Tab(text: "Données & RGPD"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLegalTab(context, "Conditions Générales d'Utilisation", _cguData),
            _buildLegalTab(context, "Politique de Confidentialité", _privacyData),
            _buildLegalTab(context, "Politique de Livraison", _deliveryData),
            _buildLegalTab(context, "Retours et Remboursements", _refundData),
            _buildLegalTab(context, "Protection des Données", _dataProtectionData),
          ],
        ),
      ),
    );
  }

  // Widget générique pour construire un onglet avec une liste de sections
  Widget _buildLegalTab(BuildContext context, String mainTitle, List<Map<String, String>> sections) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mainTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 20),
          ...sections.map((section) => Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section['titre']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      section['texte']!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "Dernière mise à jour : Août 2026",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- DONNÉES DES TEXTES LÉGAUX ---

  final List<Map<String, String>> _cguData = const [
    {
      "titre": "Bienvenue sur Keren Store",
      "texte": "Keren Store est une plateforme numérique béninoise mettant en relation des vendeurs d'ordinateurs et des acheteurs. En utilisant l'application, vous acceptez ces conditions simples."
    },
    {
      "titre": "Commandes et Paiements",
      "texte": "Keren Store n'intègre pas de système de paiement en ligne automatisé. Toutes les transactions se font de gré à gré. Le paiement s'effectue soit à la livraison (en espèces), soit par Mobile Money (MTN MoMo ou Moov Money) selon l'accord trouvé avec le vendeur dans la messagerie intégrée."
    },
    {
      "titre": "Rôle de la plateforme",
      "texte": "Nous agissons comme un facilitateur. Bien que nous fassions de notre mieux pour vérifier les vendeurs, les accords de vente (prix final, lieu de rendez-vous) n'engagent que l'acheteur et le vendeur."
    },
    {
      "titre": "Comportement",
      "texte": "Tout comportement frauduleux, tentative d'arnaque ou manque de respect dans la messagerie entraînera la suppression immédiate du compte."
    },
  ];

  final List<Map<String, String>> _privacyData = const [
    {
      "titre": "Données collectées",
      "texte": "Nous collectons uniquement les informations nécessaires au bon fonctionnement de l'application : votre nom, votre adresse e-mail, vos mots de passe (cryptés) et l'historique de vos commandes et messages."
    },
    {
      "titre": "Utilisation de vos informations",
      "texte": "Vos données servent exclusivement à créer votre compte, afficher votre profil aux vendeurs lors d'une commande, et vous permettre de suivre vos achats dans l'application."
    },
    {
      "titre": "Partage des données",
      "texte": "Vos informations (nom et détails de commande) ne sont partagées qu'avec le vendeur impliqué dans votre transaction. Nous ne vendrons jamais vos données personnelles à des tiers."
    },
  ];

  final List<Map<String, String>> _deliveryData = const [
    {
      "titre": "Modalités de livraison",
      "texte": "Keren Store n'ayant pas de flotte de livreurs en interne, la logistique de livraison est gérée directement par le vendeur de l'équipement."
    },
    {
      "titre": "Organisation",
      "texte": "Une fois la commande passée dans l'application, l'acheteur et le vendeur doivent utiliser le chat intégré pour convenir d'un lieu sécurisé, d'une date et d'une heure de livraison."
    },
    {
      "titre": "Frais de livraison",
      "texte": "Les frais d'expédition (s'il y en a) ne sont pas inclus dans le prix affiché sur l'application. Ils doivent être discutés, fixés et acceptés par les deux parties dans la messagerie avant l'expédition."
    },
  ];

  final List<Map<String, String>> _refundData = const [
    {
      "titre": "Vérification à la réception",
      "texte": "Nous conseillons vivement aux acheteurs d'allumer et de tester minutieusement l'ordinateur au moment de la livraison, avant de remettre l'argent en espèces ou d'effectuer le dépôt Mobile Money."
    },
    {
      "titre": "Conditions de retour",
      "texte": "Les retours doivent être discutés directement avec le vendeur. En général, un retour est justifié si l'appareil présente un défaut matériel majeur non mentionné dans la description, signalé dans un délai très court (ex: 48h)."
    },
    {
      "titre": "Remboursement",
      "texte": "Keren Store ne conservant pas les fonds des transactions, les remboursements doivent être effectués directement par le vendeur à l'acheteur. En cas de litige, notre administration peut intervenir comme médiateur, sans obligation de résultat financier."
    },
  ];

  final List<Map<String, String>> _dataProtectionData = const [
    {
      "titre": "Respect de la législation",
      "texte": "Conformément au Code du Numérique en vigueur en République du Bénin, vous disposez de droits stricts sur la gestion de vos données personnelles au sein de notre plateforme."
    },
    {
      "titre": "Vos droits",
      "texte": "Vous avez le droit d'accéder à vos données, de les rectifier ou de demander la suppression totale et définitive de votre compte ainsi que de votre historique (droit à l'oubli)."
    },
    {
      "titre": "Sécurité",
      "texte": "Vos mots de passe ne sont jamais stockés en clair dans notre base de données. Vos conversations liées aux commandes sont privées et accessibles uniquement à vous, au vendeur, et à l'administration en cas de signalement de fraude ou de litige."
    },
  ];
}