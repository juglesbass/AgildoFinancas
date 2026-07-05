import 'package:flutter/material.dart';
import 'dart:io'; // Para detectar Linux/Windows
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Ponte de banco para desktop
import 'screens/home_screen.dart';

void main() async {
  // Garante que o Flutter está pronto para inicializar o banco
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o banco de dados via FFI se for desktop
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const AgildoFinancasApp());
}

class AgildoFinancasApp extends StatelessWidget {
  const AgildoFinancasApp({super.key});

  @override
  Widget build(BuildContext context) {
    const corDestaque = Color(0xFF3B82F6);

    return MaterialApp(
      title: 'Agildo Finanças',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // SOLUÇÃO: FadeUpwards é 100% nativo, rápido e o compilador aceita sem reclamar
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: corDestaque,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
