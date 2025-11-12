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
import 'package:stichanda_tailor/view/screens/login_screen.dart';
// Chat module imports
import 'package:stichanda_tailor/modules/chat/cubit/chat_cubit.dart';
import 'package:stichanda_tailor/modules/chat/repository/chat_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
        home: const LoginScreen(),
      ),
    );
  }
}
