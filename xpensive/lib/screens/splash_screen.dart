import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SplashScreen({super.key, required this.themeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Small delay for splash screen effect
    await Future.delayed(const Duration(milliseconds: 500));

    final firebase = FirebaseService.instance;

    // Check if user is already logged in
    final currentUser = await firebase.getCurrentUser();

    if (mounted) {
      if (currentUser != null) {
        // User is logged in, go to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: currentUser,
              themeProvider: widget.themeProvider,
            ),
          ),
        );
      } else {
        // No user logged in, go to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                LoginScreen(themeProvider: widget.themeProvider),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xpensive',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your expenses smartly',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
