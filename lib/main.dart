import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/app/app.dart';
import 'package:kudlit_ph/core/config/supabase_config.dart';
import 'package:kudlit_ph/features/translator/data/datasources/flutter_gemma_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  final String hfToken = dotenv.env['HUGGINGFACE_TOKEN'] ?? '';
  await initializeFlutterGemma(huggingFaceToken: hfToken);
  runApp(const ProviderScope(child: KudlitApp()));
}
