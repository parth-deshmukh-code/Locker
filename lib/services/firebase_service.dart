import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/device.dart';
import 'auth_service.dart';

class LockerFirebaseService {
  static final LockerFirebaseService _i = LockerFirebaseService._();
  factory LockerFirebaseService() => _i;
  LockerFirebaseService._();

  final FirebaseDatabase _db  = FirebaseDatabase.instance;
  final AuthService      _auth = AuthService();

  // Each user's device list stored under their UID
  // /Users/{uid}/devices/{ipKey} = {nickname}
  DatabaseReference get _userDevicesRef =>
      _db.ref('Users/${_auth.uid}/devices');

  // Actual device data written by ESP
  // /Devices/IP_xxx/...
  DatabaseReference deviceRef(String ipKey) =>
      _db.ref('Devices/$ipKey');

  // ── Save device to user's list ──────────────────────────────────────────
  Future<void> addDevice(String ip, String nickname) async {
    final key = LockerDevice.ipToKey(ip);
    await _userDevicesRef.child(key).set(nickname);
  }

  // ── Remove device from user's list ─────────────────────────────────────
  Future<void> removeDevice(String ipKey) async {
    await _userDevicesRef.child(ipKey).remove();
  }

  // ── Get user's saved devices (ipKey → nickname) ─────────────────────────
  Future<Map<String, String>> getUserDevices() async {
    final snap = await _userDevicesRef.get();
    if (!snap.exists) return {};
    final raw = snap.value as Map<dynamic, dynamic>;
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  // ── Stream a single device's live data ─────────────────────────────────
  Stream<LockerDevice> deviceStream(String ip, String nickname) {
    final key = LockerDevice.ipToKey(ip);
    return deviceRef(key).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return LockerDevice.empty(ip, nickname);
      return LockerDevice.fromFirebase(
          ip: ip, nickname: nickname, data: data);
    });
  }

  // ── Control ON/OFF ──────────────────────────────────────────────────────
  Future<void> setControl(String ipKey, bool isOn) async {
    await deviceRef(ipKey).child('CONTROL').set(isOn ? 'ON' : 'OFF');
  }

  // ── Acknowledge alert ───────────────────────────────────────────────────
  Future<void> acknowledgeAlert(String ipKey) async {
    await deviceRef(ipKey).child('Alert').set('NORMAL');
  }

  // ── Set WiFi credentials for device ────────────────────────────────────
  // ESP reads /config/wifi on startup
  Future<void> setWifiConfig(String ssid, String password) async {
    await _db.ref('config/wifi').set({'ssid': ssid, 'password': password});
  }
}
