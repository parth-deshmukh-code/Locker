import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});
  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _ipCtrl       = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _fb           = LockerFirebaseService();
  bool _saving        = false;
  String? _error;

  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }

  Future<void> _add() async {
    final ip       = _ipCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();

    if (!_isValidIP(ip)) {
      setState(() => _error = 'Please enter a valid IP address (e.g. 192.168.1.10)');
      return;
    }
    if (nickname.isEmpty) {
      setState(() => _error = 'Please give this device a name');
      return;
    }

    setState(() { _saving = true; _error = null; });
    await _fb.addDevice(ip, nickname);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: Text('Add New Device',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Find the IP address printed on the sticker on your device and enter it below.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // IP field
            Text('IP Address (from sticker)',
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ipCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: '192.168.1.10',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                prefixIcon: const Icon(Icons.router_outlined, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            // Nickname field
            Text('Device Nickname',
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameCtrl,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Bedroom Locker, Office Cabinet',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                prefixIcon: const Icon(Icons.label_outline, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: GoogleFonts.inter(color: const Color(0xFFFF3B30), fontSize: 13)),
            ],

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _add,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Add Device',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
