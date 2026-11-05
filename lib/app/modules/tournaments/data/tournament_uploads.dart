import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'tournament_api.dart';
import 'tournament_models.dart';

final _picker = ImagePicker();

/// Gallery pick -> Firebase Storage -> registered `banner` asset.
/// Null when the picker is dismissed.
Future<FileAsset?> pickAndUploadBanner() async {
  final x = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 82,
    maxWidth: 1536,
    maxHeight: 1152,
  );
  if (x == null) return null;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw const TournamentApiException('Sign in to upload a banner.');
  }
  final key =
      'tournament_banners/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final ref = FirebaseStorage.instance.ref(key);
  await ref.putData(
    await x.readAsBytes(),
    SettableMetadata(contentType: x.mimeType ?? 'image/jpeg'),
  );
  final url = await ref.getDownloadURL();
  final asset = await TournamentApi().createFileAsset(
    purpose: 'banner',
    fileUrl: url,
    storageKey: key,
    mimeType: x.mimeType ?? 'image/jpeg',
    sizeBytes: await x.length(),
    metadata: const {'source': 'host_upload'},
  );
  return FileAsset(asset.id, asset.url ?? url);
}

/// Gallery pick -> signed Cloudinary upload -> registered evidence asset.
/// [purpose] is `result_evidence` or `dispute_evidence`.
Future<FileAsset?> pickAndUploadEvidence(
  String tournamentId,
  String purpose,
) async {
  // maxWidth forces re-encoding to JPEG, so iOS HEIC screenshots are accepted.
  final x = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 2000,
  );
  if (x == null) return null;
  final name = x.name.toLowerCase().endsWith('.png')
      ? x.name
      : '${x.name.split('.').first}.jpg';
  return TournamentApi().uploadEvidence(
    tournamentId,
    purpose: purpose,
    filePath: x.path,
    fileName: name,
  );
}
