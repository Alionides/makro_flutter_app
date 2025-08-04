import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'izin_talebi_page.dart';
import 'destek_talebi_page.dart';
import 'kartvizit_page.dart';

class _HeaderAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderAction(
    this.label,
    this.icon, {
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          shape: CircleBorder(),
          color: Colors.white,
          child: InkWell(
            customBorder: CircleBorder(),
            onTap: onTap, 
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: Color(0xFF1A1F4A), size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

class DashboardPage extends StatefulWidget {
  static const routeName = '/dashboard';
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = '';
  Map<String, int> _counts = {};
  bool _loadingCounts = true;

  final String _apiKey = '27a0971fa75530a36fad475e';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchCounts();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
    });
  }

  Future<void> _fetchCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) {
      setState(() {
        _loadingCounts = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://muhasebe.makro2000.com.tr/mobilapi/'
      'approvalcounts?api_key=$_apiKey&user_id=$userId',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final result = body['result'] as Map<String, dynamic>;

        if (result['status'] == 1) {
          setState(() {
            _counts = {
              'malzeme': result['malzeme_talep_onay'] as int,
              'personel': result['personel_izin_onay'] as int,
              'forma': result['forma_two_onay'] as int,
              'razi': result['razicount'] as int,
              'nakliye1': result['nakliyecount'] as int,
              'nakliye2': result['nakliyescount'] as int,
            };
          });
        }
      }
    } catch (_) {
    } finally {
      setState(() {
        _loadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    final List<Map<String, dynamic>> tiles = [
      {
        'title': 'Malzeme Talep',
        'icon': Icons.inventory_2_outlined,
        'key': 'malzeme',
      },
      {
        'title': 'Personel İzin',
        'icon': Icons.person_outline,
        'key': 'personel',
      },
      {'title': 'Forma 2', 'icon': Icons.description_outlined, 'key': 'forma'},
      {'title': 'Razılaştırma', 'icon': Icons.rule, 'key': 'razi'},
      {
        'title': 'Nakliye Talebi',
        'icon': Icons.local_shipping_outlined,
        'key': 'nakliye1',
      },
      {
        'title': 'Nakliye Satınalma',
        'icon': Icons.shopping_bag_outlined,
        'key': 'nakliye2',
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A1F4A),
            padding: EdgeInsets.only(top: topInset, bottom: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage('assets/logo.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _userName.isEmpty ? '…' : _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.notifications_none,
                        size: 28,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderAction(
                        'İzin Talebi',
                        Icons.insert_drive_file,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            IzinTalebiPage.routeName,
                          );
                        },
                      ),
                      _HeaderAction(
                        'Destek',
                        Icons.headset_mic,
                        onTap: () => Navigator.pushNamed(
                          context,
                          DestekTalebiPage.routeName,
                        ),
                      ),
                      _HeaderAction(
                        'Kartvizit',
                        Icons.account_box,
                        onTap: () => Navigator.pushNamed(
                          context,
                          KartvizitPage.routeName,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loadingCounts
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      itemCount: tiles.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                      itemBuilder: (context, idx) {
                        final tile = tiles[idx];
                        final title = tile['title'] as String;
                        final icon = tile['icon'] as IconData;
                        final key = tile['key'] as String;
                        final count = _counts[key] ?? 0;

                        return _FeatureTile(title, icon, count);
                      },
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.logout, size: 28),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_id');
                  await prefs.remove('user_name');
                  Navigator.pushReplacementNamed(context, LoginPage.routeName);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  const _FeatureTile(this.title, this.icon, this.count);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFF1A1F4A),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, 
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
