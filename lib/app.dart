import 'package:flutter/material.dart';
import 'app/routes.dart';

class MemoLinkApp extends StatelessWidget {
  const MemoLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoLink',
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.home,
    );
  }
}