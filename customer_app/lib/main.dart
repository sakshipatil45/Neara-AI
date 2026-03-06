import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/emergency_page.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: 'https://dusgfqvvjtpdnstjwjvv.supabase.co',
    anonKey: 'sb_publishable_DwFD22YKXPAoq1wYbnrY5A_we0Id-cB',
  );

  runApp(
    const ProviderScope(child: CustomerApp()),
  );
}

// ─── MethodChannel for pinned shortcut ───────────────────────────────────────
const _kSosChannel = MethodChannel('com.example.customer_app/sos_shortcut');

/// Call once after the app is fully loaded to place a pinned SOS shortcut on
/// the Android home screen. The OS will show a system dialog asking the user
/// to confirm placement.
Future<void> pinSosShortcut() async {
  try {
    await _kSosChannel.invokeMethod<bool>('pinSosShortcut');
  } catch (_) {
    // Non-critical — ignore on platforms that don't support pinned shortcuts
  }
}

// ─── Global navigator key ─────────────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ─── CustomerApp ──────────────────────────────────────────────────────────────

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  static const QuickActions _quickActions = QuickActions();

  @override
  void initState() {
    super.initState();
    _initQuickActions();
    _checkSosIntent();
  }

  // ── Long-press shortcut handler (quick_actions) ───────────────────────────
  void _initQuickActions() {
    _quickActions.initialize((shortcutType) {
      if (shortcutType == 'sos') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/emergency',
          (route) => false,
        );
      }
    });

    _quickActions.setShortcutItems([
      const ShortcutItem(
        type: 'sos',
        localizedTitle: 'Emergency SOS',
        icon: 'sos_icon',
      ),
    ]);
  }

  // ── Pinned shortcut intent check ─────────────────────────────────────────
  Future<void> _checkSosIntent() async {
    try {
      final openSos = await _kSosChannel.invokeMethod<bool>('checkSosIntent');
      if (openSos == true) {
        // Wait for the navigator to be ready, then route to EmergencyPage
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/emergency',
            (route) => false,
          );
        });
      }
    } catch (_) {
      // Not on Android or channel not ready — silently ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEARA Customer',
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/emergency': (context) => const EmergencyPage(),
      },
    );
  }
}
