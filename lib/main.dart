import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'korra_app.dart';
import 'logic/core/net/net_cubit.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await Supabase.initialize(
    url: 'https://ltytmqjpektcgwajfzfm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0eXRtcWpwZWt0Y2d3YWpmemZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3NzAxNDgsImV4cCI6MjA3MjM0NjE0OH0.ABKFE8k0pPxgieXYd5sKUkeymtjLImS0pDbwN-6TQlc',
    debug: true,
  );

  runApp(
     BlocProvider(
      create: (_) => NetCubit()..start(),
      child: const KorraApp(),
    ),
  );
}

