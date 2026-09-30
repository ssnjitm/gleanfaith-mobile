import 'package:equatable/equatable.dart';

/// A release published by the admin site, as returned by
/// `ApiConstants.appLatestVersion`.
///
/// Parsing is deliberately tolerant: the payload is produced by a hand-written
/// admin backend, so keys drift, and a stricter parser would mean users silently
/// stop receiving updates after a rename. Unknown extra keys are ignored and a
/// missing optional field degrades instead of failing the whole check.
class AppUpdateInfo extends Equatable {
  /// Human-readable version, e.g. `1.2.0`.
  final String version;

  /// The build number. This — not [version] — is what decides whether an update
  /// is newer, because `1.2.0` vs `1.10.0` does not compare correctly as a
  /// string and the admin site may not keep a strictly increasing version
  /// string.
  final int versionCode;

  /// When true the user cannot dismiss the dialog. Decided **per release** by
  /// the admin site, so a routine release never blocks anyone while a genuinely
  /// broken one can be forced.
  final bool forceUpdate;

  /// Markdown-free release notes; rendered as plain text.
  final String releaseNotes;

  /// Direct download URL for the APK. Must be HTTPS — see [AppUpdateInfo.fromResponse].
  final String apkUrl;

  /// Advertised size, used only to show "Download (48 MB)". Zero when unknown.
  final int sizeBytes;

  /// Optional integrity check of the downloaded file.
  final String? sha256;

  const AppUpdateInfo({
    required this.version,
    required this.versionCode,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.apkUrl,
    this.sizeBytes = 0,
    this.sha256,
  });

  /// Parses the endpoint response, or returns `null` when it cannot describe an
  /// installable release.
  ///
  /// Returns `null` — rather than throwing — for a missing/zero `versionCode`
  /// or an unusable `apkUrl`, because a bad row in the admin site must not
  /// break app launch, and an update prompt with no file behind it is worse
  /// than no prompt.
  static AppUpdateInfo? fromResponse(dynamic json) {
    final map = _asMap(json);
    if (map == null) return null;

    final versionCode = _readInt(map, const [
      'versionCode',
      'version_code',
      'buildNumber',
      'build_number',
      'code',
    ]);
    if (versionCode == null || versionCode <= 0) return null;

    final apkUrl = _readString(map, const [
      'apkUrl',
      'apk_url',
      'downloadUrl',
      'download_url',
      'url',
      'file',
      'fileUrl',
      'file_url',
    ]);
    // An AAB cannot be installed on a device and a cleartext URL is blocked by
    // Android's network security config, so reject both up front. Offering an
    // update that cannot possibly succeed is the worst outcome here.
    if (apkUrl == null) return null;
    final uri = Uri.tryParse(apkUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;

    final sha = _readString(map, const [
      'sha256',
      'sha_256',
      'hash',
      'checksum',
    ]);

    return AppUpdateInfo(
      version:
          _readString(map, const ['version', 'versionName', 'version_name']) ??
          versionCode.toString(),
      versionCode: versionCode,
      forceUpdate: _readBool(map, const [
        'forceUpdate',
        'force_update',
        'isForce',
        'is_force',
        'force',
        'mandatory',
        'isMandatory',
        'is_mandatory',
      ]),
      releaseNotes:
          _readString(map, const [
            'releaseNotes',
            'release_notes',
            'notes',
            'description',
            'changelog',
          ]) ??
          '',
      apkUrl: apkUrl,
      sizeBytes: _readInt(map, const ['sizeBytes', 'size_bytes', 'size']) ?? 0,
      sha256: sha == null ? null : (sha.length == 64 ? sha : sha.toLowerCase()),
    );
  }

  /// Size formatted for the download button, e.g. `48.2 MB`.
  String get readableSize {
    if (sizeBytes <= 0) return '';
    final mb = sizeBytes / (1024 * 1024);
    if (mb < 1) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
    version,
    versionCode,
    forceUpdate,
    releaseNotes,
    apkUrl,
    sizeBytes,
    sha256,
  ];
}

/// Unwraps `{ "data": { ... } }`, which this codebase's API always wraps, but
/// also accepts a bare object.
Map<String, dynamic>? _asMap(dynamic json) {
  if (json is Map<String, dynamic>) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    // Some deployments nest a `version` object; use it when it is the payload.
    final version = json['version'];
    if (version is Map<String, dynamic>) return version;
    return json;
  }
  return null;
}

String? _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    // Never stringify a container: a nested object would render as a literal
    // `{version: 1.2.0}` in the release notes.
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return '$value';
  }
  return null;
}

int? _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

bool _readBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value > 0;
    if (value is String) {
      final normalised = value.trim().toLowerCase();
      if (normalised == 'true' || normalised == '1' || normalised == 'yes') {
        return true;
      }
      if (normalised == 'false' || normalised == '0' || normalised == 'no') {
        return false;
      }
    }
  }
  return false;
}
