import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateService {
  static final UpdateService _i = UpdateService._();
  factory UpdateService() => _i;
  UpdateService._();

  // ✅ CHANGE THIS to your GitHub repo
  static const String _githubOwner = 'Parth-Deshmukh-2004';
  static const String _githubRepo  = 'Locker-';
  static const String _apiUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final info     = await PackageInfo.fromPlatform();
      final current  = info.version; // e.g. "1.0.2"

      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode != 200) return;

      final data    = jsonDecode(response.body);
      final latest  = (data['tag_name'] as String).replaceAll('v', '');
      final apkUrl  = (data['assets'] as List)
          .firstWhere((a) => a['name'].toString().endsWith('.apk'),
              orElse: () => null)?['browser_download_url'];

      if (apkUrl == null) return;

      if (_isNewer(latest, current)) {
        if (context.mounted) {
          _showUpdateDialog(context, latest, apkUrl);
        }
      }
    } catch (e) {
      // Silently fail — don't bother user if check fails
      debugPrint('Update check failed: $e');
    }
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, String version, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(version: version, apkUrl: apkUrl),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String apkUrl;
  const _UpdateDialog({required this.version, required this.apkUrl});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0;
  bool   _downloading = false;
  String _status = '';

  Future<void> _download() async {
    // Request install permission on Android
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        setState(() => _status = 'Please allow install from unknown sources');
        return;
      }
    }

    setState(() { _downloading = true; _status = 'Downloading...'; });

    try {
      final dir  = await getTemporaryDirectory();
      final path = '${dir.path}/update.apk';

      await Dio().download(
        widget.apkUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );

      setState(() => _status = 'Installing...');
      await OpenFile.open(path);
    } catch (e) {
      setState(() {
        _downloading = false;
        _status = 'Download failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text('Update Available',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${widget.version} is available.\nUpdate now to get the latest features and fixes.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          if (_downloading) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF0A84FF)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? '${(_progress * 100).toStringAsFixed(0)}% — $_status'
                  : _status,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (_status.isNotEmpty && !_downloading) ...[
            const SizedBox(height: 12),
            Text(_status,
                style: GoogleFonts.inter(
                    color: const Color(0xFFFF3B30), fontSize: 13)),
          ],
        ],
      ),
      actions: _downloading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Later',
                    style: GoogleFonts.inter(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: _download,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Update Now',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
    );
  }
}
