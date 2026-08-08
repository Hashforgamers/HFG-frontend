import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/tournament.dart';
import '../models/tournament_schedule.dart';
import '../services/community_api.dart';
import '../services/tournament_analytics.dart';
import '../services/tournament_banner_service.dart';

class CreateTournamentController extends GetxController {
  final CommunityApi _api = CommunityApi();
  final TournamentBannerRepository _bannerRepository =
      PollinationsTournamentBannerRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final SegmentSdkService _analytics = locator<SegmentSdkService>();

  static const popularGames = ['BGMI', 'Free Fire', 'Valorant', 'COD Mobile'];

  final title = TextEditingController();
  final description = TextEditingController();
  final game = TextEditingController();
  final entryFee = TextEditingController(text: '0');
  final maxPlayers = TextEditingController(text: '16');
  final matchDuration = TextEditingController(text: '45');
  final breakDuration = TextEditingController(text: '15');
  final concurrentMatches = TextEditingController(text: '1');
  final gameMode = TextEditingController();
  final platform = TextEditingController();
  final organizationName = TextEditingController();
  final teamSize = TextEditingController(text: '1');
  final substituteLimit = TextEditingController(text: '0');
  final minimumAge = TextEditingController();
  final region = TextEditingController();
  final registrationPolicy = 'automatic'.obs;
  final isPrivate = false.obs;
  final inviteCode = TextEditingController();
  final minEntries = TextEditingController(text: '2');
  final rosterLockAt = Rxn<DateTime>();
  final checkInStartAt = Rxn<DateTime>();
  final checkInEndAt = Rxn<DateTime>();
  final maxMatchesPerTeamPerDay = TextEditingController();
  final resultSubmissionWindow = TextEditingController(text: '15');
  final disputeWindow = TextEditingController(text: '30');
  final evidenceRequired = false.obs;
  final rules = TextEditingController();
  final bannerUrl = TextEditingController();
  final bannerAssetId = TextEditingController();
  final discordLink = TextEditingController();
  final whatsappLink = TextEditingController();
  final firstPrizePercent = TextEditingController(text: '100');
  final secondPrizePercent = TextEditingController(text: '0');
  final thirdPrizePercent = TextEditingController(text: '0');
  final prizePercents = <double>[100, 0, 0].obs;

  final tournamentType = 'single_elimination'.obs;
  final teamMode = 'solo'.obs;
  final visibility = true.obs;
  final registrationStart = Rxn<DateTime>();
  final registrationEnd = Rxn<DateTime>();
  final tournamentStart = Rxn<DateTime>();
  final tournamentEnd = Rxn<DateTime>();
  final estimatedDuration = Duration.zero.obs;
  final scheduleValidationError = RxnString();
  final scheduleLocked = false.obs;
  final scheduleLockChecking = false.obs;
  final submitting = false.obs;
  final loadingDefaults = true.obs;
  final reusedPreviousSetup = false.obs;
  final advancedExpanded = false.obs;
  final formStep = 0.obs;
  final error = RxnString();
  final bannerStatus = TournamentBannerStatus.initial.obs;
  final bannerSource = Rxn<TournamentBannerSource>();
  final bannerGenerationPrompt = RxnString();
  final bannerGenerationSeed = RxnInt();
  final bannerError = RxnString();
  final bannerRequestVersion = 0.obs;
  final bannerInputVersion = 0.obs;
  bool _bannerRequestActive = false;
  bool _updatingSchedule = false;
  Tournament? _editingTournament;

  bool get isEditing => _editingTournament != null;
  String get screenTitle => isEditing ? 'Edit Tournament' : 'Create Tournament';
  bool get canPublish => !isEditing || _editingTournament?.status == 'draft';
  String get saveLabel => isEditing ? 'Save changes' : 'Save draft';

  bool nextFormStep() {
    final message = _validateFormStep(formStep.value);
    error.value = message;
    if (message != null) return false;
    if (formStep.value < 2) formStep.value++;
    return true;
  }

  void previousFormStep() {
    error.value = null;
    if (formStep.value > 0) formStep.value--;
  }

  String? _validateFormStep(int step) {
    if (step == 0) {
      if (title.text.trim().isEmpty) return 'Add a tournament title.';
      if (game.text.trim().isEmpty) return 'Choose a game.';
      final size = int.tryParse(teamSize.text.trim());
      if (size == null || size < 1) return 'Choose a valid team size.';
    } else if (step == 1) {
      final fee = double.tryParse(entryFee.text.trim());
      if (fee == null || fee < 0) return 'Enter a valid entry fee.';
      final capacity = int.tryParse(maxPlayers.text.trim());
      if (capacity == null || capacity < 2) {
        return 'Maximum players must be at least 2.';
      }
      _validateSchedule();
      return scheduleValidationError.value;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Tournament) {
      _editingTournament = Get.arguments as Tournament;
    }
    _applySchedulePreset(nextWeekend: false);
    for (final input in [game, gameMode, teamSize, title]) {
      input.addListener(_markBannerInputsChanged);
    }
    ever<String>(tournamentType, (_) => _markBannerInputsChanged());
    ever<String>(teamMode, (_) => _markBannerInputsChanged());
    for (final input in [
      maxPlayers,
      teamSize,
      matchDuration,
      breakDuration,
      concurrentMatches,
    ]) {
      input.addListener(_recalculateSchedule);
    }
    for (final input in [
      registrationStart,
      registrationEnd,
      rosterLockAt,
      checkInStartAt,
      checkInEndAt,
      tournamentEnd,
    ]) {
      ever<DateTime?>(input, (_) => _validateSchedule());
    }
    _loadSmartDefaults();
    if (_editingTournament != null) {
      unawaited(_resolveScheduleLock());
    }
  }

  int get estimatedTeamCount {
    final players = int.tryParse(maxPlayers.text.trim()) ?? 0;
    final playersPerTeam = int.tryParse(teamSize.text.trim()) ?? 1;
    if (players <= 0 || playersPerTeam <= 0) return 0;
    return (players / playersPerTeam).ceil();
  }

  int? get fixedTeamSize => switch (teamMode.value) {
    'solo' => 1,
    'duo' => 2,
    'squad' => 4,
    _ => null,
  };

  void setTeamMode(String mode) {
    teamMode.value = mode;
    final fixedSize = fixedTeamSize;
    if (fixedSize != null) teamSize.text = fixedSize.toString();
  }

  void setCustomTeamSize(int size) {
    teamSize.text = size.clamp(2, 10).toString();
    teamMode.refresh();
  }

  int get estimatedRounds {
    final teams = estimatedTeamCount;
    if (teams <= 1) return 0;
    return (math.log(teams) / math.ln2).ceil();
  }

  bool get canSaveSchedule =>
      scheduleLocked.value || scheduleValidationError.value == null;

  TournamentSchedule get schedule => TournamentSchedule(
    registrationStartAt: registrationStart.value,
    registrationEndAt: registrationEnd.value,
    rosterLockAt: rosterLockAt.value,
    tournamentStartAt: tournamentStart.value,
    tournamentEndAt: tournamentEnd.value,
    checkInStartAt: checkInStartAt.value,
    checkInEndAt: checkInEndAt.value,
  );

  bool get canGenerateBanner =>
      game.text.trim().isNotEmpty && effectiveGameMode.isNotEmpty;
  String get effectiveGameMode {
    final explicit = gameMode.text.trim();
    if (explicit.isNotEmpty) return explicit;
    const labels = {
      'single_elimination': 'Knockout',
      'double_elimination': 'Knockout',
      'round_robin': 'League',
      'battle_royale': 'Battle Royale',
    };
    return labels[tournamentType.value] ?? '';
  }

  String get bannerTeamLabel {
    final explicit = int.tryParse(teamSize.text.trim());
    if (explicit != null && explicit > 1) return '${explicit}v$explicit';
    const labels = {'solo': 'Solo', 'duo': 'Duo', 'squad': 'Squad'};
    return labels[teamMode.value] ?? 'Team';
  }

  void _markBannerInputsChanged() {
    bannerInputVersion.value++;
    if (bannerStatus.value == TournamentBannerStatus.initial &&
        canGenerateBanner) {
      bannerStatus.value = TournamentBannerStatus.ready;
    }
  }

  Future<void> generateBanner({bool regenerate = false}) async {
    if (!canGenerateBanner || _bannerRequestActive) return;
    if (bannerSource.value == TournamentBannerSource.uploaded &&
        bannerUrl.text.trim().isNotEmpty) {
      bannerError.value =
          'Remove the custom banner before generating an AI replacement.';
      return;
    }
    _bannerRequestActive = true;
    final startedAt = DateTime.now();
    unawaited(
      _analytics.onCustomEvent(
        regenerate
            ? 'Tournament Banner Regenerated'
            : 'Tournament Banner Generate Clicked',
        _bannerAnalyticsProperties(),
      ),
    );
    unawaited(
      _analytics.onCustomEvent(
        'Tournament Banner Generation Started',
        _bannerAnalyticsProperties(),
      ),
    );
    final request = ++bannerRequestVersion.value;
    bannerStatus.value = TournamentBannerStatus.generating;
    bannerError.value = null;
    try {
      final result = await _bannerRepository.generate(
        gameName: game.text,
        gameType: effectiveGameMode,
        tournamentFormat: tournamentType.value.replaceAll('_', ' '),
        teamSize: bannerTeamLabel,
        tournamentName: title.text,
      );
      if (request != bannerRequestVersion.value || isClosed) return;
      final imageClient = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      var provider = result.provider;
      late Response<List<int>> response;
      try {
        response = await imageClient.get<List<int>>(
          result.imageUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {
              if (result.authorizationHeader != null)
                'Authorization': result.authorizationHeader,
            },
          ),
        );
      } on DioException catch (exception) {
        final canFallback =
            result.fallbackImageUrl != null &&
            const {401, 402, 403, 429}.contains(exception.response?.statusCode);
        if (!canFallback) rethrow;
        debugPrint(
          '[TournamentBanner] authenticated provider unavailable '
          'status=${exception.response?.statusCode}; using safe fallback',
        );
        response = await imageClient.get<List<int>>(
          result.fallbackImageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        provider = 'pollinations_legacy';
      }
      final bytes = response.data;
      final contentType =
          response.headers.value(Headers.contentTypeHeader) ?? 'image/jpeg';
      if (bytes == null ||
          bytes.length < 1024 ||
          !contentType.toLowerCase().startsWith('image/')) {
        throw const TournamentBannerException(
          'The image provider returned an invalid banner. Please regenerate.',
          type: 'invalid_image',
        );
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Sign in to generate a banner.');
      final key = 'tournament_banners/$uid/ai_${result.seed}.jpg';
      final ref = FirebaseStorage.instance.ref(key);
      await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: contentType),
      );
      final permanentUrl = await ref.getDownloadURL();
      final asset = await _api.createFileAsset(
        purpose: 'banner',
        fileUrl: permanentUrl,
        storageKey: key,
        mimeType: contentType,
        fileSizeBytes: bytes.length,
        metadata: {
          'source': 'generated',
          'provider': provider,
          'seed': result.seed,
        },
      );
      if (request != bannerRequestVersion.value || isClosed) return;
      bannerUrl.text = permanentUrl;
      bannerAssetId.text = asset.id;
      bannerGenerationPrompt.value = result.prompt;
      bannerGenerationSeed.value = result.seed;
      bannerSource.value = TournamentBannerSource.generated;
      bannerStatus.value = TournamentBannerStatus.generated;
      unawaited(
        _analytics.onCustomEvent('Tournament Banner Generation Succeeded', {
          ..._bannerAnalyticsProperties(),
          'provider': provider,
          'generation_duration_ms': DateTime.now()
              .difference(startedAt)
              .inMilliseconds,
        }),
      );
    } on TournamentBannerException catch (exception) {
      if (request != bannerRequestVersion.value || isClosed) return;
      bannerError.value = exception.message;
      bannerStatus.value = TournamentBannerStatus.failure;
      unawaited(
        _analytics.onCustomEvent('Tournament Banner Generation Failed', {
          ..._bannerAnalyticsProperties(),
          'failure_type': exception.type,
        }),
      );
    } on DioException catch (exception) {
      if (request != bannerRequestVersion.value || isClosed) return;
      final statusCode = exception.response?.statusCode;
      final failureType = switch (statusCode) {
        401 || 403 => 'unauthorized',
        402 => 'payment_required',
        429 => 'rate_limited',
        _ => 'provider_error',
      };
      bannerError.value = switch (statusCode) {
        401 || 403 =>
          'Banner generation is not authorized. Try again or upload your own banner.',
        402 =>
          'AI banner credits are unavailable. Try again later or upload your own banner.',
        429 =>
          'You have generated several banners recently. Please try again shortly.',
        _ =>
          'Banner generation is temporarily unavailable. Try again or upload your own banner.',
      };
      bannerStatus.value = TournamentBannerStatus.failure;
      debugPrint(
        '[TournamentBanner] provider request failed '
        'status=$statusCode type=${exception.type} message=${exception.message}',
      );
      unawaited(
        _analytics.onCustomEvent('Tournament Banner Generation Failed', {
          ..._bannerAnalyticsProperties(),
          'failure_type': failureType,
          if (statusCode != null) 'status_code': statusCode,
        }),
      );
    } catch (exception, stackTrace) {
      if (request != bannerRequestVersion.value || isClosed) return;
      bannerError.value =
          'Banner generation is temporarily unavailable. Try again or upload your own banner.';
      bannerStatus.value = TournamentBannerStatus.failure;
      debugPrint('[TournamentBanner] generation failed: $exception');
      debugPrintStack(stackTrace: stackTrace);
      unawaited(
        _analytics.onCustomEvent('Tournament Banner Generation Failed', {
          ..._bannerAnalyticsProperties(),
          'failure_type': 'unexpected',
        }),
      );
    } finally {
      _bannerRequestActive = false;
    }
  }

  void confirmGeneratedBanner() {
    if (bannerUrl.text.trim().isEmpty) return;
    bannerStatus.value = TournamentBannerStatus.selected;
    unawaited(
      _analytics.onCustomEvent(
        'Tournament Generated Banner Selected',
        _bannerAnalyticsProperties(),
      ),
    );
  }

  void generatedBannerFailedToLoad() {
    bannerError.value =
        'The generated image could not be loaded. Try regenerating it.';
    bannerStatus.value = TournamentBannerStatus.failure;
  }

  Future<void> uploadCustomBanner() async {
    if (_bannerRequestActive) return;
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1536,
      maxHeight: 1152,
    );
    if (selected == null || isClosed) return;
    bannerStatus.value = TournamentBannerStatus.uploading;
    bannerError.value = null;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Sign in to upload a banner.');
      final key =
          'tournament_banners/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref(key);
      await ref.putData(
        await selected.readAsBytes(),
        SettableMetadata(contentType: selected.mimeType ?? 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      final asset = await _api.createFileAsset(
        purpose: 'banner',
        fileUrl: url,
        storageKey: key,
        mimeType: selected.mimeType ?? 'image/jpeg',
        fileSizeBytes: await selected.length(),
        metadata: const {'source': 'host_upload'},
      );
      if (isClosed) return;
      bannerUrl.text = url;
      bannerAssetId.text = asset.id;
      bannerSource.value = TournamentBannerSource.uploaded;
      bannerGenerationPrompt.value = null;
      bannerGenerationSeed.value = null;
      bannerStatus.value = TournamentBannerStatus.selected;
      unawaited(
        _analytics.onCustomEvent(
          'Tournament Custom Banner Uploaded',
          _bannerAnalyticsProperties(),
        ),
      );
    } catch (_) {
      bannerError.value =
          'Could not upload that banner. Check your connection and try again.';
      bannerStatus.value = TournamentBannerStatus.failure;
    }
  }

  void removeBanner() {
    bannerRequestVersion.value++;
    bannerUrl.clear();
    bannerAssetId.clear();
    bannerSource.value = null;
    bannerGenerationPrompt.value = null;
    bannerGenerationSeed.value = null;
    bannerError.value = null;
    bannerStatus.value = canGenerateBanner
        ? TournamentBannerStatus.ready
        : TournamentBannerStatus.initial;
  }

  Map<String, dynamic> _bannerAnalyticsProperties() => {
    'game': game.text.trim(),
    'game_type': effectiveGameMode,
    'team_size': bannerTeamLabel,
    'tournament_format': tournamentType.value,
    'provider': 'pollinations',
  };

  Future<void> _loadSmartDefaults() async {
    try {
      Tournament? template;
      final argument = Get.arguments;
      if (argument is Tournament) {
        template = argument;
      } else {
        final hosted = await _api.myTournaments(role: 'hosted');
        if (hosted.isNotEmpty) template = hosted.first.tournament;
      }
      if (template != null && title.text.isEmpty && game.text.isEmpty) {
        _applyTournamentTemplate(template);
        reusedPreviousSetup.value = true;
      }
    } catch (_) {
      // Smart defaults are optional; tournament creation remains available.
    } finally {
      loadingDefaults.value = false;
    }
  }

  void _applyTournamentTemplate(Tournament template) {
    _updatingSchedule = true;
    title.text = template.title;
    selectGame(template.game);
    tournamentType.value = template.tournamentType ?? 'single_elimination';
    setTeamMode(template.teamMode ?? 'solo');
    entryFee.text = ctNumber(template.entryFee);
    maxPlayers.text = template.maxPlayers > 0
        ? template.maxPlayers.toString()
        : '16';
    description.text = template.description?.trim() ?? description.text;
    rules.text = template.rules?.trim() ?? '';
    bannerUrl.text = template.bannerUrl?.trim() ?? '';
    bannerAssetId.text = template.bannerAssetId?.trim() ?? '';
    discordLink.text = template.discordLink?.trim() ?? '';
    whatsappLink.text = template.whatsappLink?.trim() ?? '';
    visibility.value = template.visibility;
    registrationStart.value = template.registrationStartAt?.toLocal();
    registrationEnd.value = template.registrationEndAt?.toLocal();
    tournamentStart.value = template.tournamentStartAt?.toLocal();
    tournamentEnd.value = template.tournamentEndAt?.toLocal();
    matchDuration.text = (template.matchDurationMinutes ?? 45).toString();
    breakDuration.text = (template.breakDurationMinutes ?? 15).toString();
    concurrentMatches.text = template.concurrentMatches.toString();
    gameMode.text = template.gameMode ?? '';
    platform.text = template.platform ?? '';
    organizationName.text = template.organizationName ?? '';
    if (fixedTeamSize == null) {
      teamSize.text = (template.teamSize ?? 4).toString();
    }
    substituteLimit.text = (template.substituteLimit ?? 0).toString();
    minimumAge.text = template.minimumAge?.toString() ?? '';
    region.text = template.region ?? '';
    registrationPolicy.value = template.registrationPolicy ?? 'automatic';
    isPrivate.value = template.isPrivate;
    inviteCode.text = template.inviteCode ?? '';
    minEntries.text = (template.minEntries ?? 2).toString();
    rosterLockAt.value = template.rosterLockAt?.toLocal();
    checkInStartAt.value = template.checkInStartAt?.toLocal();
    checkInEndAt.value = template.checkInEndAt?.toLocal();
    maxMatchesPerTeamPerDay.text =
        template.maxMatchesPerTeamPerDay?.toString() ?? '';
    resultSubmissionWindow.text = (template.resultSubmissionWindowMinutes ?? 15)
        .toString();
    disputeWindow.text = (template.disputeWindowMinutes ?? 30).toString();
    evidenceRequired.value = template.evidenceRequired;
    if (template.prizeDistribution.isNotEmpty) {
      final values = [firstPrizePercent, secondPrizePercent, thirdPrizePercent];
      for (final value in values) {
        value.text = '0';
      }
      for (final prize in template.prizeDistribution) {
        if (prize.rank >= 1 && prize.rank <= values.length) {
          values[prize.rank - 1].text = ctNumber(prize.percent.toDouble());
        }
      }
      _syncPrizePercents();
    }
    _updatingSchedule = false;
    _recalculateSchedule(preserveExistingEnd: true);
  }

  String ctNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  void selectGame(String value) {
    game.text = value;
    if (title.text.trim().isEmpty) title.text = '$value Community Cup';
    if (description.text.trim().isEmpty) {
      description.text =
          'Compete in the $value Community Cup on HASH. Register, play, and claim your spot at the top.';
    }
  }

  void setEntryFee(num value) => entryFee.text = value.toString();

  void setCapacity(int value) => maxPlayers.text = value.toString();

  void setPrizePreset(String preset) {
    switch (preset) {
      case 'top_3':
        firstPrizePercent.text = '60';
        secondPrizePercent.text = '30';
        thirdPrizePercent.text = '10';
      case 'balanced':
        firstPrizePercent.text = '50';
        secondPrizePercent.text = '30';
        thirdPrizePercent.text = '20';
      default:
        firstPrizePercent.text = '100';
        secondPrizePercent.text = '0';
        thirdPrizePercent.text = '0';
    }
    _syncPrizePercents();
  }

  void setPrizePercent(int index, double rawValue) {
    final value = ((rawValue / 5).round() * 5).clamp(0, 100).toDouble();
    final next = prizePercents.toList();
    final otherIndexes = [0, 1, 2].where((item) => item != index).toList();
    final remaining = 100 - value;
    final otherTotal = otherIndexes.fold<double>(
      0,
      (sum, item) => sum + next[item],
    );
    next[index] = value;
    if (otherTotal <= 0) {
      next[otherIndexes.first] = remaining;
      next[otherIndexes.last] = 0;
    } else {
      next[otherIndexes.first] =
          remaining * next[otherIndexes.first] / otherTotal;
      next[otherIndexes.last] = 100 - value - next[otherIndexes.first];
    }
    prizePercents.assignAll(next);
    _syncPrizeFields();
  }

  void _syncPrizePercents() {
    prizePercents.assignAll([
      double.tryParse(firstPrizePercent.text) ?? 0,
      double.tryParse(secondPrizePercent.text) ?? 0,
      double.tryParse(thirdPrizePercent.text) ?? 0,
    ]);
  }

  void _syncPrizeFields() {
    final fields = [firstPrizePercent, secondPrizePercent, thirdPrizePercent];
    for (var index = 0; index < fields.length; index++) {
      fields[index].text = ctNumber(prizePercents[index]);
    }
  }

  void setSchedulePreset({required bool nextWeekend}) {
    _applySchedulePreset(nextWeekend: nextWeekend);
  }

  void _applySchedulePreset({required bool nextWeekend}) {
    final now = DateTime.now();
    var daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    if (nextWeekend) daysUntilSaturday += 7;
    var eventStart = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSaturday,
      18,
    );
    if (!eventStart.isAfter(now.add(const Duration(hours: 3)))) {
      eventStart = eventStart.add(const Duration(days: 7));
    }
    _updatingSchedule = true;
    registrationStart.value = now.add(const Duration(minutes: 15));
    registrationEnd.value = eventStart.subtract(const Duration(hours: 2));
    tournamentStart.value = eventStart;
    rosterLockAt.value = eventStart.subtract(const Duration(minutes: 15));
    checkInStartAt.value = eventStart.subtract(const Duration(minutes: 30));
    checkInEndAt.value = eventStart.subtract(const Duration(minutes: 5));
    _updatingSchedule = false;
    _recalculateSchedule();
  }

  Future<void> pickDateTime(BuildContext context, Rxn<DateTime> target) async {
    final initial =
        target.value ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (identical(target, tournamentStart)) {
      _setTournamentStart(selected);
    } else {
      target.value = selected;
      _validateSchedule();
    }
  }

  void _setTournamentStart(DateTime next) {
    if (scheduleLocked.value) return;
    final previous = tournamentStart.value;
    final offset = previous == null ? Duration.zero : next.difference(previous);
    _updatingSchedule = true;
    tournamentStart.value = next;
    if (previous == null) {
      rosterLockAt.value = next.subtract(const Duration(minutes: 15));
      checkInStartAt.value = next.subtract(const Duration(minutes: 30));
      checkInEndAt.value = next.subtract(const Duration(minutes: 5));
    } else {
      rosterLockAt.value = rosterLockAt.value?.add(offset);
      checkInStartAt.value = checkInStartAt.value?.add(offset);
      checkInEndAt.value = checkInEndAt.value?.add(offset);
      tournamentEnd.value = tournamentEnd.value?.add(offset);
    }
    _updatingSchedule = false;
    _recalculateSchedule();
  }

  void _recalculateSchedule({bool preserveExistingEnd = false}) {
    if (_updatingSchedule || scheduleLocked.value) return;
    final teams = estimatedTeamCount;
    final rounds = estimatedRounds;
    final matchMinutes = int.tryParse(matchDuration.text.trim());
    final breakMinutes = int.tryParse(breakDuration.text.trim());
    final concurrency = int.tryParse(concurrentMatches.text.trim());
    if (teams < 2 ||
        rounds == 0 ||
        matchMinutes == null ||
        matchMinutes < 1 ||
        breakMinutes == null ||
        breakMinutes < 0 ||
        concurrency == null ||
        concurrency < 1) {
      estimatedDuration.value = Duration.zero;
      _validateSchedule();
      return;
    }

    estimatedDuration.value = TournamentSchedule.estimateDuration(
      numberOfTeams: teams,
      concurrentMatches: concurrency,
      matchDurationMinutes: matchMinutes,
      breakDurationMinutes: breakMinutes,
    );
    final start = tournamentStart.value;
    if (!preserveExistingEnd && start != null) {
      _updatingSchedule = true;
      tournamentEnd.value = start.add(estimatedDuration.value);
      _updatingSchedule = false;
    }
    _validateSchedule();
  }

  void _validateSchedule() {
    if (_updatingSchedule) return;
    scheduleValidationError.value = schedule.validate();
  }

  Future<void> _resolveScheduleLock() async {
    final tournament = _editingTournament;
    if (tournament == null) return;
    const immutableStatuses = {'live', 'in_progress', 'completed', 'cancelled'};
    if (immutableStatuses.contains(tournament.status.toLowerCase())) {
      scheduleLocked.value = true;
      return;
    }
    scheduleLockChecking.value = true;
    try {
      final matches = await _api.tournamentMatches(
        tournament.id,
        private: tournament.isPrivate,
      );
      scheduleLocked.value = matches.isNotEmpty;
    } catch (_) {
      // The backend remains the final authority if match lookup is unavailable.
    } finally {
      scheduleLockChecking.value = false;
    }
  }

  String? validate() {
    final name = title.text.trim();
    if (name.length < 3 || name.length > 200) {
      return 'Title must be 3–200 characters.';
    }
    if (game.text.trim().isEmpty) return 'Game is required.';
    final fee = double.tryParse(entryFee.text.trim());
    if (fee == null || fee < 0) return 'Enter a valid entry fee.';
    final capacity = int.tryParse(maxPlayers.text.trim());
    if (capacity == null || capacity < 1 || capacity > 10000) {
      return 'Maximum players must be between 1 and 10,000.';
    }
    final regStart = registrationStart.value;
    final regEnd = registrationEnd.value;
    final eventStart = tournamentStart.value;
    final eventEnd = tournamentEnd.value;
    _validateSchedule();
    if (scheduleValidationError.value != null) {
      return scheduleValidationError.value;
    }
    if (regStart == null ||
        regEnd == null ||
        eventStart == null ||
        eventEnd == null) {
      return 'Complete the tournament schedule.';
    }
    final matchMinutes = int.tryParse(matchDuration.text.trim());
    if (matchMinutes == null || matchMinutes < 1) {
      return 'Match duration must be at least 1 minute.';
    }
    final breakMinutes = int.tryParse(breakDuration.text.trim());
    if (breakMinutes == null || breakMinutes < 0) {
      return 'Break duration cannot be negative.';
    }
    final parallelMatches = int.tryParse(concurrentMatches.text.trim());
    if (parallelMatches == null || parallelMatches < 1) {
      return 'Concurrent matches must be at least 1.';
    }
    final size = int.tryParse(teamSize.text.trim());
    if (size == null || size < 1) return 'Team size must be at least 1.';
    final fixedSize = fixedTeamSize;
    if (fixedSize != null && size != fixedSize) {
      return '${teamMode.value.capitalizeFirst} tournaments require $fixedSize player${fixedSize == 1 ? '' : 's'} per team.';
    }
    final substitutes = int.tryParse(substituteLimit.text.trim());
    if (substitutes == null || substitutes < 0) {
      return 'Substitute limit cannot be negative.';
    }
    final minimum = int.tryParse(minEntries.text.trim());
    if (minimum == null || minimum < 2 || minimum > capacity) {
      return 'Minimum entries must be between 2 and maximum players.';
    }
    if (checkInStartAt.value != null &&
        checkInEndAt.value != null &&
        !checkInEndAt.value!.isAfter(checkInStartAt.value!)) {
      return 'Check-in must end after it starts.';
    }
    final resultWindow = int.tryParse(resultSubmissionWindow.text.trim());
    final disputeMinutes = int.tryParse(disputeWindow.text.trim());
    if (resultWindow == null || resultWindow < 1) {
      return 'Result submission window must be at least 1 minute.';
    }
    if (disputeMinutes == null || disputeMinutes < 1) {
      return 'Dispute window must be at least 1 minute.';
    }
    final prizes = _prizeDistribution();
    final total = prizes.fold<double>(
      0,
      (sum, item) => sum + (item['percent'] as num),
    );
    if (prizes.isEmpty || (total - 100).abs() > .01) {
      return 'Prize percentages must total 100%.';
    }
    return null;
  }

  List<Map<String, dynamic>> _prizeDistribution() {
    final values = [firstPrizePercent, secondPrizePercent, thirdPrizePercent];
    final result = <Map<String, dynamic>>[];
    for (var index = 0; index < values.length; index++) {
      final percent = double.tryParse(values[index].text.trim()) ?? 0;
      if (percent > 0) result.add({'rank': index + 1, 'percent': percent});
    }
    return result;
  }

  Future<void> submit({required bool publish}) async {
    final validationError = validate();
    if (validationError != null) {
      error.value = validationError;
      return;
    }
    submitting.value = true;
    error.value = null;
    try {
      final body = _editablePayload(publish: publish);
      if (isEditing && body.isEmpty) {
        _returnToPreviousScreen(_editingTournament);
        return;
      }
      final Tournament tournament = _editingTournament == null
          ? await _api.createTournament(body)
          : await _api.updateTournament(_editingTournament!.id, body);
      if (_editingTournament == null) {
        await TournamentAnalytics.log(
          'tournament_created',
          tournament,
          sourceScreen: 'create_tournament',
          teamStatus: 'host',
        );
      }
      if (publish && _editingTournament?.status != 'published') {
        await TournamentAnalytics.log(
          'tournament_published',
          tournament,
          sourceScreen: 'create_tournament',
          teamStatus: 'host',
        );
      }
      _returnToPreviousScreen(tournament);
    } on DioException catch (e) {
      final data = e.response?.data;
      error.value = data is Map && data['message'] != null
          ? data['message'].toString()
          : e.response?.statusCode == 403
          ? 'Paid tournaments require a verified host account.'
          : 'Could not save the tournament. Please try again.';
    } catch (_) {
      error.value = 'Could not save the tournament. Please try again.';
    } finally {
      submitting.value = false;
    }
  }

  void _returnToPreviousScreen(Tournament? result) {
    final context = Get.context;
    if (context != null && Navigator.of(context).canPop()) {
      // Bypass Get.back: GetX attempts to close any queued snackbar first.
      // A failed snackbar initialization elsewhere can otherwise throw after a
      // successful tournament mutation and leave this screen visible.
      Navigator.of(context).pop(result);
      return;
    }
    Get.offNamed(AppRoutes.TOURNAMENTS_DISCOVERY);
  }

  Map<String, dynamic> _editablePayload({required bool publish}) {
    final candidate = <String, dynamic>{
      'title': title.text.trim(),
      'description': _nullableText(description.text),
      'banner_url': _nullableText(bannerUrl.text),
      'banner_asset_id': _nullableText(bannerAssetId.text),
      'banner_source': bannerSource.value?.name,
      'banner_generation_seed': bannerGenerationSeed.value,
      'game': game.text.trim(),
      'tournament_type': tournamentType.value,
      'team_mode': teamMode.value,
      'entry_fee': double.parse(entryFee.text.trim()),
      'currency': 'INR',
      'max_players': int.parse(maxPlayers.text.trim()),
      'registration_start_at': registrationStart.value!
          .toUtc()
          .toIso8601String(),
      'registration_end_at': registrationEnd.value!.toUtc().toIso8601String(),
      'tournament_start_at': tournamentStart.value!.toUtc().toIso8601String(),
      'tournament_end_at': tournamentEnd.value?.toUtc().toIso8601String(),
      'match_duration_minutes': int.parse(matchDuration.text.trim()),
      'break_duration_minutes': int.parse(breakDuration.text.trim()),
      'schedule_config': {
        'concurrent_matches': int.parse(concurrentMatches.text.trim()),
      },
      'game_mode': _nullableText(gameMode.text),
      'platform': _nullableText(platform.text),
      'organization_name': _nullableText(organizationName.text),
      'team_size': int.parse(teamSize.text.trim()),
      'substitute_limit': int.parse(substituteLimit.text.trim()),
      'minimum_age': int.tryParse(minimumAge.text.trim()),
      'region': _nullableText(region.text),
      'registration_policy': registrationPolicy.value,
      'is_private': isPrivate.value,
      'invite_code': isPrivate.value ? _nullableText(inviteCode.text) : null,
      'min_entries': int.parse(minEntries.text.trim()),
      'roster_lock_at': rosterLockAt.value?.toUtc().toIso8601String(),
      'check_in_start_at': checkInStartAt.value?.toUtc().toIso8601String(),
      'check_in_end_at': checkInEndAt.value?.toUtc().toIso8601String(),
      'max_matches_per_team_per_day': int.tryParse(
        maxMatchesPerTeamPerDay.text.trim(),
      ),
      'result_submission_window_minutes': int.parse(
        resultSubmissionWindow.text.trim(),
      ),
      'dispute_window_minutes': int.parse(disputeWindow.text.trim()),
      'rules_config': {'evidence_required': evidenceRequired.value},
      'rules': _nullableText(rules.text),
      'prize_distribution': _prizeDistribution(),
      'discord_link': _nullableText(discordLink.text),
      'whatsapp_link': _nullableText(whatsappLink.text),
      'visibility': visibility.value,
    };

    final existing = _editingTournament;
    if (existing == null) {
      candidate.removeWhere((_, value) => value == null);
      candidate['status'] = publish ? 'published' : 'draft';
      return candidate;
    }

    final baseline = <String, dynamic>{
      'title': existing.title.trim(),
      'description': _nullableText(existing.description),
      'banner_url': _nullableText(existing.bannerUrl),
      'banner_asset_id': _nullableText(existing.bannerAssetId),
      'game': existing.game.trim(),
      'tournament_type': existing.tournamentType ?? 'single_elimination',
      'team_mode': existing.teamMode ?? 'solo',
      'entry_fee': existing.entryFee,
      'currency': existing.currency,
      'max_players': existing.maxPlayers,
      'registration_start_at': existing.registrationStartAt
          ?.toUtc()
          .toIso8601String(),
      'registration_end_at': existing.registrationEndAt
          ?.toUtc()
          .toIso8601String(),
      'tournament_start_at': existing.tournamentStartAt
          ?.toUtc()
          .toIso8601String(),
      'tournament_end_at': existing.tournamentEndAt?.toUtc().toIso8601String(),
      'match_duration_minutes': existing.matchDurationMinutes,
      'break_duration_minutes': existing.breakDurationMinutes,
      'schedule_config': {'concurrent_matches': existing.concurrentMatches},
      'game_mode': _nullableText(existing.gameMode),
      'platform': _nullableText(existing.platform),
      'organization_name': _nullableText(existing.organizationName),
      'team_size': existing.teamSize,
      'substitute_limit': existing.substituteLimit,
      'minimum_age': existing.minimumAge,
      'region': _nullableText(existing.region),
      'registration_policy': existing.registrationPolicy,
      'is_private': existing.isPrivate,
      'invite_code': _nullableText(existing.inviteCode),
      'min_entries': existing.minEntries,
      'roster_lock_at': existing.rosterLockAt?.toUtc().toIso8601String(),
      'check_in_start_at': existing.checkInStartAt?.toUtc().toIso8601String(),
      'check_in_end_at': existing.checkInEndAt?.toUtc().toIso8601String(),
      'max_matches_per_team_per_day': existing.maxMatchesPerTeamPerDay,
      'result_submission_window_minutes':
          existing.resultSubmissionWindowMinutes,
      'dispute_window_minutes': existing.disputeWindowMinutes,
      'rules_config': {'evidence_required': existing.evidenceRequired},
      'rules': _nullableText(existing.rules),
      'prize_distribution': existing.prizeDistribution
          .map((item) => item.toJson())
          .toList(),
      'discord_link': _nullableText(existing.discordLink),
      'whatsapp_link': _nullableText(existing.whatsappLink),
      'visibility': existing.visibility,
    };

    final changed = <String, dynamic>{};
    for (final entry in candidate.entries) {
      if (!_sameJsonValue(entry.value, baseline[entry.key])) {
        changed[entry.key] = entry.value;
      }
    }
    if (existing.status == 'draft' && publish) {
      changed['status'] = 'published';
    }
    return changed;
  }

  String? _nullableText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _sameJsonValue(dynamic left, dynamic right) {
    if (left is num && right is num) return left.toDouble() == right.toDouble();
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_sameJsonValue(left[index], right[index])) return false;
      }
      return true;
    }
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_sameJsonValue(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }

  @override
  void onClose() {
    for (final controller in [
      title,
      description,
      game,
      entryFee,
      maxPlayers,
      matchDuration,
      breakDuration,
      concurrentMatches,
      gameMode,
      platform,
      organizationName,
      teamSize,
      substituteLimit,
      minimumAge,
      region,
      inviteCode,
      minEntries,
      maxMatchesPerTeamPerDay,
      resultSubmissionWindow,
      disputeWindow,
      rules,
      bannerUrl,
      bannerAssetId,
      discordLink,
      whatsappLink,
      firstPrizePercent,
      secondPrizePercent,
      thirdPrizePercent,
    ]) {
      controller.dispose();
    }
    super.onClose();
  }
}
