import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCliente {
  static SupabaseClient get cliente => Supabase.instance.client;
}