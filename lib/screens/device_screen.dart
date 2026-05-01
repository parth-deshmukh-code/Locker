import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/device.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class DeviceScreen extends StatefulWidget {
  final LockerDevice device;
  const DeviceScreen({super.key, required this.device});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin {
  final _fb    = LockerFirebaseService();
  final _notif = NotificationService();
  late LockerDevice _device;

  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    _pulse  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LockerDevice>(
      stream: _fb.deviceStream(_device.ip, _device.nickname),
      initialData: _device,
      builder: (context, snap) {
        if (snap.hasData) _device = snap.data!;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: AppBar(
            backgroundColor: const Color(0xFF000000),
            title: Text(_device.nickname,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            iconTheme: const IconThemeData(color: Colors.white),
            subtitle: Text(_device.ip,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAlertCard(),
                const SizedBox(height: 16),
                _buildAccelCard(),
                const SizedBox(height: 16),
                _buildControlCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertCard() {
    final isAlert = _device.isAlert;
    final color   = isAlert ? const Color(0xFFFF3B30) : const Color(0xFF34C759);

    return ScaleTransition(
      scale: isAlert ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Text(isAlert ? '🔴' : '🟢', style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              isAlert ? 'ALERT' : 'NORMAL',
              style: GoogleFonts.inter(
                fontSize: 34, fontWeight: FontWeight.w800,
                color: color, letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAlert ? 'Movement detected!' : 'Locker is secure',
              style: GoogleFonts.inter(fontSize: 14, color: color.withOpacity(0.8)),
            ),
            if (isAlert) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await _notif.stopAlarm();
                  await _fb.acknowledgeAlert(_device.ipKey);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text('Acknowledge & Stop Alarm',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Accelerometer',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Text('m/s²',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 20),
          _accelRow('X', _device.accelX, const Color(0xFFFF3B30)),
          const SizedBox(height: 14),
          _accelRow('Y', _device.accelY, const Color(0xFF34C759)),
          const SizedBox(height: 14),
          _accelRow('Z', _device.accelZ, const Color(0xFF0A84FF)),
        ],
      ),
    );
  }

  Widget _accelRow(String axis, double value, Color color) {
    final pct   = (value.abs() / 10.0).clamp(0.0, 1.0);
    final isHigh = value.abs() > 6.88;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(axis,
                    style: GoogleFonts.inter(
                        color: color, fontWeight: FontWeight.w800, fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Text('${value.toStringAsFixed(2)} m/s²',
                  style: GoogleFonts.inter(
                      color: isHigh ? const Color(0xFFFF3B30) : Colors.white,
                      fontWeight: isHigh ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15)),
            ]),
            if (isHigh)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('⚠️ HIGH',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFFF3B30),
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(
                isHigh ? const Color(0xFFFF3B30) : color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildControlCard() {
    final isOn  = _device.isOn;
    final color = isOn ? const Color(0xFF34C759) : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(
                isOn ? Icons.power_settings_new : Icons.power_off_outlined,
                color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device Control',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                    isOn ? 'ON — monitoring active' : 'OFF — device sleeping',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _fb.setControl(_device.ipKey, !isOn),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 64, height: 34,
              decoration: BoxDecoration(
                  color: isOn ? const Color(0xFF34C759) : const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(17)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 28, height: 28,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
