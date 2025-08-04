import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'dashboard_page.dart';
import 'izin_talebi_page.dart';
import 'destek_talebi_page.dart';
import 'kartvizit_page.dart';

void main() {
  runApp(const MakroApp());
}

class MakroApp extends StatelessWidget {
  const MakroApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makro ERP Mobil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1F4A),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      ),

      // Instead of initialRoute, use home with a FutureBuilder
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final prefs = snapshot.data!;
          final savedUserId = prefs.getString('user_id');

          if (savedUserId != null && savedUserId.isNotEmpty) {
            return DashboardPage();
          }

          return LoginPage();
        },
      ),

      routes: {
        LoginPage.routeName: (_) => LoginPage(),
        DashboardPage.routeName: (_) => DashboardPage(),
        IzinTalebiPage.routeName: (_) => IzinTalebiPage(),
        DestekTalebiPage.routeName: (_) => DestekTalebiPage(),
        KartvizitPage.routeName: (_) => KartvizitPage(),
      },
    );
  }
}
