import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final String initialStatus;

  const OrderTrackingScreen({
    super.key, 
    required this.orderId, 
    required this.initialStatus,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final List<String> _etapes = [
    "Commande passée",
    "Confirmée par vendeur",
    "En préparation",
    "Expédiée",
    "Livrée"
  ];

  late String _currentStatus;
  bool _isAdmin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _checkRole();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = (prefs.getString('user_role') == 'admin');
    });
  }

  int _getCurrentStepIndex() {
    int index = _etapes.indexOf(_currentStatus);
    return index >= 0 ? index : 0;
  }

  Future<void> _passerEtapeSuivante() async {
    int currentIndex = _getCurrentStepIndex();
    if (currentIndex >= _etapes.length - 1) return;

    String nextStatus = _etapes[currentIndex + 1];

    setState(() => _isLoading = true);

    final result = await OrderService.updateOrderStatus(widget.orderId, nextStatus);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _currentStatus = result['statut'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Statut mis à jour : $_currentStatus"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : ${result['erreur']}"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    int currentStep = _getCurrentStepIndex();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Suivi de Commande", 
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Commande #${widget.orderId}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Statut actuel : $_currentStatus",
                style: TextStyle(fontSize: 16, color: colorScheme.secondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),
              
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Stepper(
                    physics: const BouncingScrollPhysics(),
                    currentStep: currentStep,
                    controlsBuilder: (context, details) {
                      // Seul l'admin voit le bouton d'action, et seulement s'il reste des étapes
                      if (_isAdmin && currentStep < _etapes.length - 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _passerEtapeSuivante,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Passer à l'étape suivante", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // Vide pour le client
                    },
                    steps: List.generate(_etapes.length, (index) {
                      bool isCompleted = index <= currentStep;
                      bool isActive = index == currentStep;
                      
                      return Step(
                        title: Text(
                          _etapes[index],
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted ? colorScheme.primary : Colors.grey,
                          ),
                        ),
                        content: const SizedBox.shrink(), // Pas de contenu supplémentaire requis
                        state: isCompleted 
                          ? (isActive ? StepState.editing : StepState.complete) 
                          : StepState.indexed,
                        isActive: isCompleted,
                      );
                    }),
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