import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'state/order_state.dart';
import 'screens/login_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BaiApp());
}
 
class BaiApp extends StatelessWidget {  
  const BaiApp({super.key});
  @override
  Widget build(BuildContext context) { 
    return ChangeNotifierProvider(
      create: (_) => OrderState(),
      child: MaterialApp(
        title: 'B.A.I.',
        debugShowCheckedModeBanner: false,
        theme: baiTheme(),
        home: const LoginScreen(),
      ),
    );
  }
}