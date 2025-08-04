// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KartvizitPage extends StatefulWidget {
  static const routeName = '/kartvizit';
  @override
  _KartvizitPageState createState() => _KartvizitPageState();
}

class _KartvizitPageState extends State<KartvizitPage> {
  bool   _loading   = true;
  String? _error;
  String? _vcardText;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _buildDummyVCard();
  }

  Future<void> _buildDummyVCard() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    final prefs   = await SharedPreferences.getInstance();
    final userId   = prefs.getString('user_id')   ?? '';
    final userName = prefs.getString('user_name') ?? '';

    if (userId.isEmpty || userName.isEmpty) {
      setState(() {
        _error   = 'Kullanıcı bilgisi bulunamadı.';
        _loading = false;
      });
      return;
    }

    final sb = StringBuffer()
      ..writeln('BEGIN:VCARD\r')
      ..writeln('VERSION:3.0\r')
      ..writeln('N:;$userName\r')
      ..writeln('FN:$userName\r')
      ..writeln('ORG:Makro2000 Yapı ve İnşaat\r')
      ..writeln('TITLE:Yazılım Mühendisi\r')
      ..writeln('TEL;TYPE=WORK,VOICE:05500000000\r')
      ..writeln('TEL;TYPE=CELL,VOICE:05500000000\r')
      ..writeln('EMAIL:dummy@example.com\r')
      ..writeln('ADR:;;Istanbul\r')
      ..writeln('URL:www.makro2000.com\r')
      ..writeln('BDAY:1990-01-01\r')
      ..writeln('END:VCARD');

    setState(() {
      _vcardText = sb.toString();
      _fotoUrl   = ''; 
      _loading   = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F4A),
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: Image.asset('assets/logo.png', height: 32),
      ),
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _buildDummyVCard,
                          child: const Text('Tekrar Dene'),
                        )
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Kartvizitim',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        QrImageView(
                          data: _vcardText!,
                          version: QrVersions.auto,
                          size: 200,
                          gapless: false,
                        ),
                        
                        if (_fotoUrl != null && _fotoUrl!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              image: DecorationImage(
                                image: NetworkImage(_fotoUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}
