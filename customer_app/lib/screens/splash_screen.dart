import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart' show pendingSosLaunch, clearPendingSos;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Skip the branding delay when opened via the SOS home-screen widget so
    // the voice input screen appears immediately.
    if (!pendingSosLaunch) {
      await Future.delayed(const Duration(seconds: 2));
    }

    final userId = await AuthService().getLoggedUserId();

    if (!mounted) return;

    if (userId != null) {
      if (pendingSosLaunch) {
        // Go directly to the SOS activation screen without touching /home first.
        clearPendingSos();
        Navigator.pushReplacementNamed(context, '/sos-activate');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      clearPendingSos(); // clear stale flag if user is somehow logged out
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              'NEARA',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }
}
