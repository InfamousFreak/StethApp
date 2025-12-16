import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stethapp/login_page.dart';
import 'package:stethapp/home_page.dart';
import 'package:stethapp/language_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageProvider _languageProvider = LanguageProvider();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: _languageProvider.currentLocale,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'StethApp',
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('fr', ''), // French
            Locale('de', ''), // German
            Locale('es', ''), // Spanish
            Locale('hi', ''), // Hindi
          ],
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Show loading while checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF121212),
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                );
              }
              
              // If user is logged in, go to home page
              if (snapshot.hasData && snapshot.data != null) {
                return HomePage(languageProvider: _languageProvider);
              }
              
              // Otherwise, show login page
              return LoginPage(languageProvider: _languageProvider);
            },
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
