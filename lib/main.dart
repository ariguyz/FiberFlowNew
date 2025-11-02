// lib/main.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/verify_email_screen.dart';
import 'utils/theme_notifier.dart';

/// Toggle Emulator/Production
const bool kUseEmulatorsDefault = false;
bool get _useEmulatorsFromDefine {
  const v = String.fromEnvironment('FIREBASE_EMULATOR', defaultValue: '');
  if (v == '1' || v.toLowerCase() == 'true') return true;
  if (v == '0' || v.toLowerCase() == 'false') return false;
  return kUseEmulatorsDefault;
}

Future<void> _connectEmulatorsIfNeeded() async {
  final useEmu = _useEmulatorsFromDefine;
  if (!useEmu) {
    debugPrint('[Firebase] ✅ Using PRODUCTION');
    return;
  }
  final host = (kIsWeb || Platform.isIOS) ? 'localhost' : '10.0.2.2';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }
  debugPrint('[Firebase] 🚧 Using EMULATORS at $host');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _connectEmulatorsIfNeeded();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const FiberFlow(),
    ),
  );
}

class FiberFlow extends StatelessWidget {
  const FiberFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // ColorSchemes (เข้ากับโทนแอพ)
    final light = ColorScheme.light(
      primary: const Color(0xFF6C63FF),
      secondary: const Color(0xFF8B8BA5),
      surface: const Color(0xFFFFFFFF),
      background: const Color(0xFFF6F2FA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1C1B1F),
      onBackground: const Color(0xFF1C1B1F),
      surfaceContainerHighest: const Color(0xFFF1EEF6),
      outlineVariant: const Color(0xFFDFDCE8),
    );

    final dark = ColorScheme.dark(
      primary: const Color(0xFFB9B4FF),
      secondary: const Color(0xFFB1B1C7),
      surface: const Color(0xFF1F1F25),
      background: const Color(0xFF141418),
      onPrimary: const Color(0xFF0E0E12),
      onSecondary: const Color(0xFF0E0E12),
      onSurface: const Color(0xFFE6E1E6),
      onBackground: const Color(0xFFE6E1E6),
      surfaceContainerHighest: const Color(0xFF26262D),
      outlineVariant: const Color(0xFF3A3A43),
    );

    final themeLight = ThemeData(
      useMaterial3: true,
      colorScheme: light,
      appBarTheme: AppBarTheme(
        backgroundColor: light.background,
        foregroundColor: light.onBackground,
        elevation: 0,
      ),
      cardTheme: widget(
        child: CardTheme(
          color: light.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: light.onSurface.withOpacity(.85),
        textColor: light.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: light.onSurface.withOpacity(.12),
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: light.surface,
        selectedItemColor: light.primary,
        unselectedItemColor: light.onSurface.withOpacity(.6),
      ),
    );

    final themeDark = ThemeData(
      useMaterial3: true,
      colorScheme: dark,
      appBarTheme: AppBarTheme(
        backgroundColor: dark.background,
        foregroundColor: dark.onBackground,
        elevation: 0,
      ),
      cardTheme: widget(
        child: CardTheme(
          color: dark.surfaceContainerHighest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: dark.onSurface.withOpacity(.9),
        textColor: dark.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: dark.onSurface.withOpacity(.12),
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: dark.surface,
        selectedItemColor: dark.primary,
        unselectedItemColor: dark.onSurface.withOpacity(.6),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FiberFlow',
      theme: themeLight,
      darkTheme: themeDark,
      themeMode: themeNotifier.themeMode,
      home: const _Root(),
    );
  }

  widget({required CardTheme child}) {}
}

/// คุมเส้นทางรวม: login → verify → dashboard
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        if (!(user.emailVerified)) return const VerifyEmailScreen();
        return const DashboardScreen();
      },
    );
  }
}
