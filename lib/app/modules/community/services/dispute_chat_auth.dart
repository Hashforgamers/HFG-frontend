import 'package:firebase_auth/firebase_auth.dart';

import 'community_api.dart';

class DisputeChatAuth {
  DisputeChatAuth({CommunityApi? api, FirebaseAuth? auth})
    : _api = api ?? CommunityApi(),
      _auth = auth ?? FirebaseAuth.instance;

  final CommunityApi _api;
  final FirebaseAuth _auth;

  Future<void> authenticate() async {
    final credentials = await _api.firebaseChatCredentials();
    final expectedUid = credentials.firebaseUid.trim();
    final currentUid = _auth.currentUser?.uid.trim() ?? '';

    if (expectedUid.isNotEmpty && currentUid == expectedUid) return;

    final token = credentials.customToken.trim();
    if (token.isEmpty) {
      throw StateError(
        expectedUid.isEmpty
            ? 'Firebase chat token is unavailable.'
            : 'Firebase chat session does not match this account.',
      );
    }

    final result = await _auth.signInWithCustomToken(token);
    final signedInUid = result.user?.uid.trim() ?? '';
    if (expectedUid.isNotEmpty && signedInUid != expectedUid) {
      throw StateError('Firebase chat identity mismatch.');
    }
  }
}
