import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart'; 
import 'providers/cart_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), 
        ChangeNotifierProvider(create: (_) => CartProvider()),  
      ],
      child: KerenStoreApp(), 
    ),
  );
}

// --- GESTIONNAIRE D'ÉTAT DU THÈME ---
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; 

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// --- APPLICATION PRINCIPALE ---
class KerenStoreApp extends StatelessWidget {
  // Retrait du const ici pour esquiver le bug du compilateur
  KerenStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Keren Store',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
        primaryColor: Color(0xFF00A8B5),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF00A8B5),
          secondary: Color(0xFF6A1FD1),
          surface: Color(0xFFF5F5F5),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0D0D0D),
        primaryColor: Color(0xFF00D9E3),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF00D9E3),
          secondary: Color(0xFF7B2CFF),
          surface: Color(0xFF1A1A1A),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: Color(0xFFFFFFFF),
          displayColor: Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
      ),

      home: SplashScreen(), 
    );
  }
}