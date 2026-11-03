import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/register/register_screen.dart';

void main() {
  runApp(const ExpenseSnapApp());
}

class ExpenseSnapApp extends StatelessWidget {
  const ExpenseSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenseSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RegisterScreen(),
    );
  }
}
