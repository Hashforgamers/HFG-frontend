import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../chat/services/chat_service.dart';

import 'community_api.dart';

class DisputeChatAuth {
  DisputeChatAuth({CommunityApi? api}) : _api = api ?? CommunityApi();

  final CommunityApi _api;
  static const _appName = 'community-dispute-chat';
  static DisputeChatSession? _cachedSession;

  Future<DisputeChatSession> authenticate() async {
    final app = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    final credentials = await _api.firebaseChatCredentials();
    final expectedUid = credentials.firebaseUid.trim();
    final currentUid = auth.currentUser?.uid.trim() ?? '';

    if (expectedUid.isNotEmpty && currentUid == expectedUid) {
      return _session(app, auth);
    }

    final token = credentials.customToken.trim();
    if (token.isEmpty) {
      throw StateError(
        expectedUid.isEmpty
            ? 'Firebase chat token is unavailable.'
            : 'Firebase chat session does not match this account.',
      );
    }

    final result = await auth.signInWithCustomToken(token);
    final signedInUid = result.user?.uid.trim() ?? '';
    if (expectedUid.isNotEmpty && signedInUid != expectedUid) {
      throw StateError('Firebase chat identity mismatch.');
    }
    return _session(app, auth);
  }

  Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_appName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _appName,
        options: Firebase.app().options,
      );
    }
  }

  DisputeChatSession _session(FirebaseApp app, FirebaseAuth auth) {
    final cached = _cachedSession;
    if (cached != null &&
        cached.auth.currentUser?.uid == auth.currentUser?.uid) {
      return cached;
    }
    final service = ChatService(
      auth: auth,
      firestore: FirebaseFirestore.instanceFor(app: app),
      roomsCollection: 'communityDisputeRooms',
    );
    return _cachedSession = DisputeChatSession(
      auth: auth,
      chatService: service,
    );
  }
}

class DisputeChatSession {
  const DisputeChatSession({required this.auth, required this.chatService});

  final FirebaseAuth auth;
  final ChatService chatService;
}
