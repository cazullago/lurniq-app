import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../core/strings.dart';
import '../models/models.dart';

/// Thrown for expected user-facing failures (duplicate username, …).
class StoreException implements Exception {
  StoreException(this.message);
  final String message;
  @override
  String toString() => message;
}

String newId() => const Uuid().v4();

String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

String fmtTime(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '$h12:${two(d.minute)} $ampm';
}

String fmtDateTime(DateTime d) => '${fmtDate(d)} · ${fmtTime(d)}';

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return S.justNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${S.minutesAgo}';
  if (diff.inHours < 24) return '${diff.inHours}${S.hoursAgo}';
  return '${diff.inDays}${S.daysAgo}';
}

/// Viewer-timezone helpers. Study-group times are stored in UTC; everything
/// is displayed in the viewer's preferred timezone.
int viewerOffsetMinutes(AppUser? user) {
  if (user != null && user.timezoneMode == 'fixed') {
    return user.timezoneOffsetMinutes;
  }
  return DateTime.now().timeZoneOffset.inMinutes;
}

DateTime utcToViewer(DateTime utc, AppUser? user) =>
    utc.toUtc().add(Duration(minutes: viewerOffsetMinutes(user)));

DateTime viewerWallToUtc(DateTime wall, AppUser? user) =>
    wall.subtract(Duration(minutes: viewerOffsetMinutes(user)));

String offsetLabel(int minutes) {
  final sign = minutes < 0 ? '−' : '+';
  final abs = minutes.abs();
  return 'UTC$sign${two(abs ~/ 60)}:${two(abs % 60)}';
}

/// Copies a picked image into the app's private image library and returns the
/// stored path. Images are downscaled at pick time so lists never decode
/// full-resolution bitmaps.
Future<String> savePickedImage(Directory appDir, XFile picked) async {
  final dir = Directory(p.join(appDir.path, 'images'));
  await dir.create(recursive: true);
  final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
  final target = File(p.join(dir.path, '${newId()}$ext'));
  await File(picked.path).copy(target.path);
  return target.path;
}

void deleteImageQuietly(String? path) {
  if (path == null || path.isEmpty) return;
  try {
    File(path).deleteSync();
  } catch (_) {}
}

/// Requests camera/photo permission with a plain-language rationale first,
/// then opens the picker. Returns the saved image path, or null if the user
/// cancelled or denied permission.
Future<String?> pickAndSaveImage(
  BuildContext context,
  Directory appDir, {
  required bool camera,
}) async {
  final permission = camera ? Permission.camera : Permission.photos;
  final title = camera ? S.cameraPermissionTitle : S.photosPermissionTitle;
  final body = camera ? S.cameraPermissionBody : S.photosPermissionBody;

  var status = await permission.status;
  if (!status.isGranted) {
    if (!context.mounted) return null;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(S.ok),
          ),
        ],
      ),
    );
    if (proceed != true) return null;
    status = await permission.request();
  }
  if (!status.isGranted) {
    if (!context.mounted) return null;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(S.permissionDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(S.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(S.openSettings),
          ),
        ],
      ),
    );
    if (open == true) await openAppSettings();
    return null;
  }
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return savePickedImage(appDir, picked);
}

void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(S.copied)),
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = S.delete,
  bool destructive = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(S.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}
