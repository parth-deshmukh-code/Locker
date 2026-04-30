import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class WifiConfigScreen extends StatefulWidget {
  const WifiConfigScreen({super.key});
  @override
  State<WifiConfigScreen> createState() => _WifiConfigScreenState();
}

class _WifiConfigScreenState extends State<WifiConfigScreen> {
  final _ssidCtrl     = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fb           = LockerFirebaseService();
  bool _saving        = false;
  bool _showPass      = false;
  bool _saved         = false;

  Future<void> _save() async {
    if (_ssidCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() { _saving = true; _saved = false; });
    await _fb.setWifiConfig(_ssidCtrl.text.trim(), _passwordCtrl.text.trim());
    setState(() { _saving = false; _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: Text('WiFi Configuration',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('📡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter the WiFi credentials your device should connect to. The device reads this on startup.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text('WiFi Name (SSID)',
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ssidCtrl,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Your WiFi network name',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                prefixIcon: const Icon(Icons.wifi, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            Text('WiFi Password',
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              obscureText: !_showPass,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Your WiFi password',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                suffixIcon: IconButton(
                  icon: Icon(
                      _showPass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38, size: 20),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Save WiFi Config',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            if (_saved) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF34C759).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF34C759), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'WiFi credentials saved! Device will use these on next startup.',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF34C759), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
