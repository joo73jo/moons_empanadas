import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'nucleo/constantes/supabase_constantes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstantes.url,
    anonKey: SupabaseConstantes.anonKey,
  );

  runApp(const App());
}