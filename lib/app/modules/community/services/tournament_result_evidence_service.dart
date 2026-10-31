import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/tournament_operations.dart';

class TournamentEvidenceAnalysis {
  const TournamentEvidenceAnalysis({
    required this.rawText,
    required this.detectedTeamA,
    required this.detectedTeamB,
    required this.detectedTeamAScore,
    required this.detectedTeamBScore,
    required this.detectedWinnerTeamId,
    required this.scoringMode,
    required this.confidence,
  });

  final String rawText;
  final String? detectedTeamA;
  final String? detectedTeamB;
  final int? detectedTeamAScore;
  final int? detectedTeamBScore;
  final String? detectedWinnerTeamId;
  final String scoringMode;
  final double confidence;
}

class TournamentResultEvidenceService {
  TournamentResultEvidenceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<TournamentEvidenceAnalysis> analyze(
    String imagePath,
    CommunityMatch match,
    {
    String? game,
  }
  ) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return _extract(result, match, game: game);
    } finally {
      await recognizer.close();
    }
  }

  Future<String> store({
    required String tournamentId,
    required CommunityMatch match,
    required String submittedAs,
    required TournamentEvidenceAnalysis analysis,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to save result evidence.');
    final matchRef = _firestore
        .collection('tournament_match_evidence')
        .doc('${tournamentId}_${match.id}');
    final submissionRef = matchRef.collection('submissions').doc();
    await submissionRef.set({
      'submitted_by_uid': uid,
      'submitted_as': submittedAs,
      'raw_ocr_text': analysis.rawText,
      'detected_team_a': analysis.detectedTeamA,
      'detected_team_b': analysis.detectedTeamB,
      'detected_team_a_score': analysis.detectedTeamAScore,
      'detected_team_b_score': analysis.detectedTeamBScore,
      'detected_winner_team_id': analysis.detectedWinnerTeamId,
      'scoring_mode': analysis.scoringMode,
      'confidence': analysis.confidence,
      'created_at': FieldValue.serverTimestamp(),
    });
    await _refreshConsensus(matchRef, match);
    return submissionRef.id;
  }

  Future<void> _refreshConsensus(
    DocumentReference<Map<String, dynamic>> matchRef,
    CommunityMatch match,
  ) async {
    final submissions = await matchRef.collection('submissions').get();
    final votes = <String, int>{};
    for (final item in submissions.docs) {
      final data = item.data();
      final a = data['detected_team_a_score'];
      final b = data['detected_team_b_score'];
      if (a is int && b is int) {
        votes.update('$a:$b', (n) => n + 1, ifAbsent: () => 1);
      }
    }
    String? consensus;
    var best = 0;
    for (final vote in votes.entries) {
      if (vote.value > best) {
        consensus = vote.key;
        best = vote.value;
      }
    }
    final scores = consensus?.split(':');
    await matchRef.set({
      'tournament_id': match.tournamentId,
      'match_id': match.id,
      'team_a_id': match.teamA?.id,
      'team_a_name': match.teamA?.name,
      'team_b_id': match.teamB?.id,
      'team_b_name': match.teamB?.name,
      'submission_count': submissions.size,
      'consensus_team_a_score': scores == null ? null : int.tryParse(scores[0]),
      'consensus_team_b_score': scores == null ? null : int.tryParse(scores[1]),
      'consensus_votes': best,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  TournamentEvidenceAnalysis _extract(
    RecognizedText recognized,
    CommunityMatch match, {
    String? game,
  }) {
    final text = recognized.text;
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = normalized.toLowerCase();
    final teamA = match.teamA?.name;
    final teamB = match.teamB?.name;
    final hasA = teamA != null && lower.contains(teamA.toLowerCase());
    final hasB = teamB != null && lower.contains(teamB.toLowerCase());
    int? scoreA;
    int? scoreB;
    String? winnerTeamId;
    var scoringMode = 'unknown';
    final gameKey = (game ?? '').toLowerCase();
    final battleRoyale = [
      'bgmi',
      'pubg',
      'free fire',
      'fortnite',
      'battle royale',
    ].any(gameKey.contains);

    if (battleRoyale) {
      scoreA = _rankNearTeam(recognized, teamA);
      scoreB = _rankNearTeam(recognized, teamB);
      if (scoreA != null && scoreB != null && scoreA != scoreB) {
        winnerTeamId = scoreA < scoreB ? match.teamA?.id : match.teamB?.id;
        scoringMode = 'finish_rank';
      }
    } else {
      final versus = RegExp(
        r'(?:score|rounds?|final)?\s*#?\b(\d{1,2})\s*[-–]\s*(\d{1,2})\b',
        caseSensitive: false,
      ).allMatches(normalized).where((candidate) {
        final a = int.tryParse(candidate.group(1)!);
        final b = int.tryParse(candidate.group(2)!);
        return a != null && b != null && a <= 50 && b <= 50;
      }).firstOrNull;
      if (versus != null) {
        scoreA = int.tryParse(versus.group(1)!);
        scoreB = int.tryParse(versus.group(2)!);
        if (scoreA != null && scoreB != null && scoreA != scoreB) {
          winnerTeamId = scoreA > scoreB ? match.teamA?.id : match.teamB?.id;
          scoringMode = 'round_score';
        }
      }
    }
    final signals = <bool>[
      hasA,
      hasB,
      scoreA != null && scoreB != null,
      winnerTeamId != null,
    ].where((value) => value).length;
    return TournamentEvidenceAnalysis(
      rawText: normalized,
      detectedTeamA: hasA ? teamA : null,
      detectedTeamB: hasB ? teamB : null,
      detectedTeamAScore: scoreA,
      detectedTeamBScore: scoreB,
      detectedWinnerTeamId: winnerTeamId,
      scoringMode: scoringMode,
      confidence: signals / 4,
    );
  }

  int? _rankNearTeam(RecognizedText recognized, String? teamName) {
    if (teamName == null || teamName.trim().isEmpty) return null;
    final lines = recognized.blocks.expand((block) => block.lines).toList();
    final teamKey = _key(teamName);
    final teamLine = lines.where((line) {
      final lineKey = _key(line.text);
      return lineKey.contains(teamKey) || teamKey.contains(lineKey);
    }).firstOrNull;
    if (teamLine == null) return null;

    final rankHeader = lines.where((line) {
      final key = _key(line.text);
      return key.contains('finishrank') || key == 'rank';
    }).firstOrNull;
    final candidates =
        <
          ({
            TextLine line,
            int rank,
            double verticalDistance,
            double columnDistance,
          })
        >[];
    for (final line in lines) {
      final match = RegExp(
        r'^\s*[#＃]?\s*(\d{1,3})(?:\s|$)',
      ).firstMatch(line.text);
      final rank = match == null ? null : int.tryParse(match.group(1)!);
      if (rank == null || rank > 100) continue;
      final verticalDistance =
          (line.boundingBox.center.dy - teamLine.boundingBox.center.dy).abs();
      final groupedRow = line.text.trim().split(RegExp(r'\s+')).length > 1;
      final detectedRankX = groupedRow
          ? line.boundingBox.left
          : line.boundingBox.center.dx;
      final columnDistance = rankHeader == null
          ? (line.text.contains('#') ? 0.0 : double.infinity)
          : (detectedRankX - rankHeader.boundingBox.center.dx).abs();
      final inRankColumn = columnDistance <= 90;
      final explicitRank = line.text.contains('#') || line.text.contains('＃');
      if (verticalDistance <= 130 && (inRankColumn || explicitRank)) {
        candidates.add((
          line: line,
          rank: rank,
          verticalDistance: verticalDistance,
          columnDistance: columnDistance,
        ));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final aScore = a.verticalDistance + (a.columnDistance * .35);
      final bScore = b.verticalDistance + (b.columnDistance * .35);
      return aScore.compareTo(bScore);
    });
    return candidates.first.rank;
  }

  String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
