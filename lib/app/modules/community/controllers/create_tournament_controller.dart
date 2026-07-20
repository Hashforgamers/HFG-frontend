import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/tournament.dart';
import '../services/community_api.dart';

class CreateTournamentController extends GetxController {
  final CommunityApi _api = CommunityApi();

  static const popularGames = ['BGMI', 'Free Fire', 'Valorant', 'COD Mobile'];

  final title = TextEditingController();
  final description = TextEditingController();
  final game = TextEditingController();
  final entryFee = TextEditingController(text: '0');
  final maxPlayers = TextEditingController(text: '16');
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
  final submitting = false.obs;
  final loadingDefaults = true.obs;
  final reusedPreviousSetup = false.obs;
  final advancedExpanded = false.obs;
  final error = RxnString();
  Tournament? _editingTournament;

  bool get isEditing => _editingTournament != null;
  String get screenTitle => isEditing ? 'Edit Tournament' : 'Create Tournament';
  bool get canPublish => !isEditing || _editingTournament?.status == 'draft';
  String get saveLabel => isEditing ? 'Save changes' : 'Save draft';

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Tournament) {
      _editingTournament = Get.arguments as Tournament;
    }
    _applySchedulePreset(nextWeekend: false);
    _loadSmartDefaults();
  }

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
    title.text = template.title;
    selectGame(template.game);
    tournamentType.value = template.tournamentType ?? 'single_elimination';
    teamMode.value = template.teamMode ?? 'solo';
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
    registrationStart.value = now.add(const Duration(minutes: 15));
    registrationEnd.value = eventStart.subtract(const Duration(hours: 2));
    tournamentStart.value = eventStart;
    tournamentEnd.value = eventStart.add(const Duration(hours: 4));
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
    target.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
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
    if (regStart == null || regEnd == null || eventStart == null) {
      return 'Registration start, registration end, and tournament start are required.';
    }
    if (!regEnd.isAfter(regStart)) {
      return 'Registration must end after it starts.';
    }
    if (eventStart.isBefore(regEnd)) {
      return 'Tournament must start after registration closes.';
    }
    if (eventEnd != null && !eventEnd.isAfter(eventStart)) {
      return 'Tournament end must be after its start.';
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
        Get.back(result: _editingTournament);
        return;
      }
      final Tournament tournament = _editingTournament == null
          ? await _api.createTournament(body)
          : await _api.updateTournament(_editingTournament!.id, body);
      Get.back(result: tournament);
      Get.snackbar(
        isEditing
            ? 'Tournament updated'
            : publish
            ? 'Tournament published'
            : 'Draft saved',
        tournament.title,
        snackPosition: SnackPosition.BOTTOM,
      );
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

  Map<String, dynamic> _editablePayload({required bool publish}) {
    final candidate = <String, dynamic>{
      'title': title.text.trim(),
      'description': _nullableText(description.text),
      'banner_url': _nullableText(bannerUrl.text),
      'banner_asset_id': _nullableText(bannerAssetId.text),
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
