import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DestekTalebiPage extends StatefulWidget {
  static const routeName = '/destek-talebi';
  @override
  _DestekTalebiPageState createState() => _DestekTalebiPageState();
}

class _DestekTalebiPageState extends State<DestekTalebiPage> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final title = _subjectCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    // 1) Validate non-empty
    if (title.isEmpty || desc.isEmpty) {
      setState(() => _error = 'Lütfen tüm alanları doldurunuz.');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    // 2) Get user_id
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) {
      setState(() {
        _error = 'Lütfen önce giriş yapın.';
        _submitting = false;
      });
      return;
    }

    // 3) Build the URI with percent-encoding
    const apiKey = '27a0971fa75530a36fad475e';
    final uri = Uri.https(
      'muhasebe.makro2000.com.tr',
      '/mobilapi/create_mobil_ticket',
      {
        'user_id': userId,
        'ticketTitle': title,
        'api_key': apiKey,
        'ticketDescription': desc,
      },
    );

    try {
      // 4) Call API
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final status = body['status'] as int? ?? 0;
        final message = body['message'] as String? ?? 'Bilinmeyen hata';

        if (status == 1) {
          // 5a) Success: show snackbar & pop
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          Navigator.pop(context);
          return;
        } else {
          // 5b) Server‐side error
          setState(() => _error = message);
        }
      } else {
        setState(() => _error = 'Sunucu hatası: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Hata oluştu: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F4A),
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: Image.asset('assets/logo.png', height: 32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: const [
                Icon(Icons.headset_mic, size: 24, color: Color(0xFF1A1F4A)),
                SizedBox(width: 8),
                Text(
                  'Yazılım Destek Talebi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Subject field
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                hintText: 'Konu Başlığı',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Description field
            Expanded(
              child: TextField(
                controller: _descCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Açıklama',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

            // Show validation / server errors
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 12),

            // Send button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1F4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Gönder',
                    style: TextStyle(color: Colors.white),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
