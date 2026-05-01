import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/device.dart';
import 'auth_service.dart';

class LockerFirebaseService {
  static final LockerFirebaseService _i = LockerFirebaseService._();
  factory LockerFirebaseService() => _i;
  LockerFirebaseService._();

  final FirebaseDatabase _db   = FirebaseDatabase.instance;
  final AuthService      _auth = AuthService();

  // Firebase structure:
  // /Devices/{ipKey}/... → device data (written by ESP)
  // /Devices/{ipKey}/users/{uid} → nickname (who added this device)
  // /Users/{uid}/devices/{ipKey} → true (user's device list)

  DatabaseReference deviceRef(String ipKey) =>
      _db.ref('Devices/$ipKey');

  DatabaseReference get _myDevicesRef =>
      _db.ref('Users/${_auth.uid}/devices');

  // ── Add device to this user's list ──────────────────────────────────────
  // Stores nickname under the device so all users see their own nickname
  Future<void> addDevice(String ip, String nickname) async {
    final key = LockerDevice.ipToKey(ip);
    final uid = _auth.uid!;

    // Register user under device
    await _db.ref('Devices/$key/users/$uid').set(nickname);

    // Add to user's device list
    await _myDevicesRef.child(key).set(true);
  }

  // ── Remove device from this user's list only ────────────────────────────
  // Other users still see it — only this user loses access
  Future<void> removeDevice(String ipKey) async {
    final uid = _auth.uid!;
    await _db.ref('Devices/$ipKey/users/$uid').remove();
    await _myDevicesRef.child(ipKey).remove();
  }

  // ── Get this user's devices → {ipKey: nickname} ─────────────────────────
  Future<Map<String, String>> getUserDevices() async {
    final uid  = _auth.uid!;
    final snap = await _myDevicesRef.get();
    if (!snap.exists) return {};

    final keys = (snap.value as Map<dynamic, dynamic>).keys
        .map((k) => k.toString())
        .toList();

    final Map<String, String> result = {};
    for (final key in keys) {
      // Get this user's nickname for this device
      final nicknameSnap =
          await _db.ref('Devices/$key/users/$uid').get();
      final nickname =
          nicknameSnap.exists ? nicknameSnap.value.toString() : key;
      result[key] = nickname;
    }
    return result;
  }

  // ── Stream single device live data ───────────────────────────────────────
  Stream<LockerDevice> deviceStream(String ip, String nickname) {
    final key = LockerDevice.ipToKey(ip);
    return deviceRef(key).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return LockerDevice.empty(ip, nickname);
      return LockerDevice.fromFirebase(
          ip: ip, nickname: nickname, data: data);
    });
  }

  // ── Control ON/OFF ───────────────────────────────────────────────────────
  Future<void> setControl(String ipKey, bool isOn) async {
    await deviceRef(ipKey).child('CONTROL').set(isOn ? 'ON' : 'OFF');
  }

  // ── Acknowledge alert ────────────────────────────────────────────────────
  Future<void> acknowledgeAlert(String ipKey) async {
    await deviceRef(ipKey).child('Alert').set('NORMAL');
  }

  // ── WiFi config for ESP ──────────────────────────────────────────────────
  Future<void> setWifiConfig(String ssid, String password) async {
    await _db.ref('config/wifi').set({'ssid': ssid, 'password': password});
  }

  // ── How many users have this device ─────────────────────────────────────
  Stream<int> deviceUserCount(String ipKey) {
    return _db.ref('Devices/$ipKey/users').onValue.map((event) {
      if (!event.snapshot.exists) return 0;
      return (event.snapshot.value as Map).length;
    });
  }
}
