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
        brightness: Brightness.dark,
        
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
          brightness: Brightness.dark,
        ),
        
        scaffoldBackgroundColor: const Color(0xFF111827), 
        
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1F2937),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF374151)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: corDestaque, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
          hintStyle: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
