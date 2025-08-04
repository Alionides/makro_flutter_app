import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'dashboard_page.dart'; 

class IzinTalebiPage extends StatefulWidget {
  static const routeName = '/izin-talebi';
  @override
  _IzinTalebiPageState createState() => _IzinTalebiPageState();
}

class _IzinTalebiPageState extends State<IzinTalebiPage> {
  final _descCtrl = TextEditingController();
  int _tabIndex = 0;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();

  bool _submitting = false;
  String? _error;

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: _startTime);
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate, 
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _endDate = d);
  }

  Future<void> _pickEndTime() async {
    final initial =
        (_endDate.isAtSameMomentAs(_startDate) || _endDate.isBefore(_startDate))
        ? _startTime
        : _endTime;

    final t = await showTimePicker(context: context, initialTime: initial);

    if (t != null) {
      setState(() {
        if (_endDate == _startDate &&
            (t.hour < _startTime.hour ||
                (t.hour == _startTime.hour && t.minute < _startTime.minute))) {
          _endTime = _startTime;
        } else {
          _endTime = t;
        }
      });
    }
  }

  Future<void> _submitPermit() async {
    final startDateTimeObj = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTimeObj = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTimeObj.isBefore(startDateTimeObj)) {
      setState(() {
        _error = 'Bitiş tarihi başlangıç tarihinden önce olamaz.';
        _submitting = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) {
      setState(() {
        _error = 'Lütfen önce giriş yapın.';
        _submitting = false;
      });
      return;
    }

    final permitType = (_tabIndex + 1).toString();

    String fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    final startDT = '${fmtDate(_startDate)} ${fmtTime(_startTime)}';
    final endDT = '${fmtDate(_endDate)} ${fmtTime(_endTime)}';
    final desc = Uri.encodeComponent(_descCtrl.text.trim());
    if (desc.isEmpty) {
      setState(() {
        _error = 'Lütfen açıklama giriniz.';
      });
      return;
    }

    final apiKey = '27a0971fa75530a36fad475e';
    final url = Uri.parse(
      'https://muhasebe.makro2000.com.tr/mobilapi/'
      'create_permit?api_key=$apiKey'
      '&user_id=$userId'
      '&permit_type=$permitType'
      '&startDateTime=$startDT'
      '&endDateTime=$endDT'
      '&description=$desc',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == 1) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(body['message'] as String)));
          Navigator.pushReplacementNamed(context, DashboardPage.routeName);
          return;
        } else {
          setState(() => _error = body['message'] as String);
        }
      } else {
        setState(() => _error = 'Sunucu hatası: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Bağlantı hatası: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Yeni İzin Talebi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tabs
            Row(
              children: ['Mezuniyet', 'Öz Hesabına', 'Hastalık']
                  .asMap()
                  .entries
                  .map((e) {
                    final idx = e.key;
                    final label = e.value;
                    final sel = idx == _tabIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF1A1F4A) : Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: sel ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Text('Başlangıç Tarihi'),
                Spacer(),
                ElevatedButton(
                  onPressed: _pickStartDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    df.format(_startDate),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: _pickStartTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    _startTime.format(context),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Text('Bitiş Tarihi'),
                Spacer(),
                ElevatedButton(
                  onPressed: _pickEndDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    df.format(_endDate),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: _pickEndTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    _endTime.format(context),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: 'Açıklama',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitPermit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1F4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Gönder',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
