import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/device.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'device_screen.dart';
import 'add_device_screen.dart';
import 'wifi_config_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _fb    = LockerFirebaseService();
  final _auth  = AuthService();
  final _notif = NotificationService();

  Map<String, String> _savedDevices = {};
  final Map<String, StreamSubscription> _subs      = {};
  final Map<String, LockerDevice>       _devices   = {};
  final Map<String, bool>               _prevAlerts = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    _savedDevices = await _fb.getUserDevices();
    _subscribeAll();
    setState(() => _loading = false);
  }

  void _subscribeAll() {
    for (final sub in _subs.values) sub.cancel();
    _subs.clear();

    for (final entry in _savedDevices.entries) {
      final ipKey    = entry.key;
      final nickname = entry.value;
      final ip       = LockerDevice.keyToIp(ipKey);

      _subs[ip] = _fb.deviceStream(ip, nickname).listen((device) {
        final wasAlert = _prevAlerts[ip] ?? false;
        if (device.isAlert && !wasAlert) {
          _notif.playAlarm();
          _notif.showAlert(device.nickname);
        }
        if (!device.isAlert && wasAlert) {
          final anyOther = _devices.values
              .where((d) => d.ip != ip)
              .any((d) => d.isAlert);
          if (!anyOther) _notif.stopAlarm();
        }
        _prevAlerts[ip] = device.isAlert;
        if (mounted) setState(() => _devices[ip] = device);
      });
    }
  }

  Future<void> _removeDevice(String ip, String ipKey) async {
    await _fb.removeDevice(ipKey);
    _subs[ip]?.cancel();
    _subs.remove(ip);
    setState(() {
      _savedDevices.remove(ipKey);
      _devices.remove(ip);
    });
  }

  @override
  void dispose() {
    for (final sub in _subs.values) sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceList  = _devices.values.toList();
    final alertCount  = deviceList.where((d) => d.isAlert).length;
    final onlineCount = deviceList.where((d) => d.isOnline).length;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (alertCount > 0) _buildAlertBanner(alertCount),
            _buildSummary(onlineCount, deviceList.length),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF)))
                  : _savedDevices.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddDeviceScreen()));
          _loadDevices();
        },
        backgroundColor: const Color(0xFF0A84FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Device',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Locker रक्षक',
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.white54),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WifiConfigScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white38),
            onPressed: () async {
              await _notif.stopAlarm();
              await _auth.logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count device${count > 1 ? 's' : ''} triggered alert!',
              style: GoogleFonts.inter(
                  color: const Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: _notif.stopAlarm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('Silence',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(int online, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text('$online/$total online',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          const Spacer(),
          Text(_auth.currentUser?.email ?? '',
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: _savedDevices.entries.map((entry) {
        final ipKey    = entry.key;
        final nickname = entry.value;
        final ip       = LockerDevice.keyToIp(ipKey);
        final device   = _devices[ip] ?? LockerDevice.empty(ip, nickname);
        return _buildCard(device, ipKey);
      }).toList(),
    );
  }

  Widget _buildCard(LockerDevice device, String ipKey) {
    final color = device.isAlert
        ? const Color(0xFFFF3B30)
        : device.isOnline
            ? const Color(0xFF34C759)
            : Colors.grey;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DeviceScreen(device: device)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: device.isAlert
                ? const Color(0xFFFF3B30).withOpacity(0.5)
                : Colors.white12,
            width: device.isAlert ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text(
                  device.isAlert ? '🔴' : device.isOnline ? '🟢' : '⚫',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.nickname,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(device.ip,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        device.isAlert
                            ? '⚠️ Movement!'
                            : device.isOnline
                                ? '✅ Secure'
                                : '⚫ Offline',
                        style: GoogleFonts.inter(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      // Show how many users share this device
                      StreamBuilder<int>(
                        stream: _fb.deviceUserCount(ipKey),
                        builder: (_, snap) {
                          final count = snap.data ?? 0;
                          if (count <= 1) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E5CE6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '👥 $count users',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF5E5CE6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF2C2C2E),
              icon: const Icon(Icons.more_vert, color: Colors.white38),
              onSelected: (v) {
                if (v == 'delete') _removeDevice(device.ip, ipKey);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Remove from my list',
                      style: GoogleFonts.inter(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No devices added yet',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tap + Add Device to get started',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}
