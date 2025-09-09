// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/vpn_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VpnProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Reaver VPN',
        theme: ThemeData( // Light Theme
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blueAccent, // This will generate the color scheme
        ),
        darkTheme: ThemeData( // Dark Theme
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blueAccent,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system, // Or ThemeMode.light / ThemeMode.dark
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}