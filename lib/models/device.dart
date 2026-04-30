class LockerDevice {
  final String ip;
  final String ipKey;
  final String nickname;
  final double accelX;
  final double accelY;
  final double accelZ;
  final bool isAlert;
  final bool isOn;
  final bool isOnline;

  LockerDevice({
    required this.ip,
    required this.ipKey,
    required this.nickname,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.isAlert,
    required this.isOn,
    required this.isOnline,
  });

  static String ipToKey(String ip) => 'IP_' + ip.replaceAll('.', '_');
  static String keyToIp(String key) =>
      key.replaceFirst('IP_', '').replaceAll('_', '.');

  factory LockerDevice.fromFirebase({
    required String ip,
    required String nickname,
    required Map<dynamic, dynamic> data,
  }) {
    final lastSeen = data['lastSeen'] as int? ?? 0;
    final isOnline = lastSeen > 0 &&
        DateTime.now().millisecondsSinceEpoch - lastSeen < 15000;

    return LockerDevice(
      ip:       ip,
      ipKey:    ipToKey(ip),
      nickname: nickname,
      accelX:   (data['AccelX'] as num?)?.toDouble() ?? 0.0,
      accelY:   (data['AccelY'] as num?)?.toDouble() ?? 0.0,
      accelZ:   (data['AccelZ'] as num?)?.toDouble() ?? 0.0,
      isAlert:  data['Alert']?.toString() == 'ALERT',
      isOn:     data['CONTROL']?.toString() != 'OFF',
      isOnline: isOnline,
    );
  }

  factory LockerDevice.empty(String ip, String nickname) => LockerDevice(
        ip: ip, ipKey: ipToKey(ip), nickname: nickname,
        accelX: 0, accelY: 0, accelZ: 0,
        isAlert: false, isOn: true, isOnline: false,
      );
}
