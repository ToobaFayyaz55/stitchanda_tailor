import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stichanda_tailor/firebase_options.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/ride_cubit.dart';
import 'package:stichanda_tailor/data/repository/auth_repo.dart' as auth_repo;
import 'package:stichanda_tailor/data/repository/order_repo.dart' as order_repo;
import 'package:stichanda_tailor/data/repository/ride_repo.dart' as ride_repo;
import 'package:stichanda_tailor/view/gate/session_gate.dart';
// Chat module imports
import 'package:stichanda_tailor/modules/chat/cubit/chat_cubit.dart';
import 'package:stichanda_tailor/modules/chat/repository/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore: avoid_print
    print('Warning: .env not found or failed to load: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: 'https://rzkrwgexdqksrudynxvp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6a3J3Z2V4ZHFrc3J1ZHlueHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTUxNjAsImV4cCI6MjA3NzI5MTE2MH0.bQytv6utSf9ArstDr6nu1K5L66XuFj5vTBYiWSR-xRw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(authRepo: auth_repo.AuthRepo()),
        ),
        BlocProvider(
          create: (context) => OrderCubit(orderRepo: order_repo.OrderRepo()),
        ),
        BlocProvider(
          create: (context) => RideCubit(rideRepo: ride_repo.RideRepo()),
        ),
        // Chat cubit available app-wide
        BlocProvider(
          create: (context) => ChatCubit(ChatRepository()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stichanda Tailor',
        theme: buildAppTheme(),
        home: const SessionGate(),
      ),
    );
  }
}
