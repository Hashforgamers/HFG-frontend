import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/create_tournament_controller.dart';
import '../services/tournament_banner_service.dart';
import 'community_theme.dart';

class CreateTournamentView extends GetView<CreateTournamentController> {
  const CreateTournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      appBar: AppBar(
        backgroundColor: CT.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: CT.onSurface),
        title: Text(controller.screenTitle, style: CT.headline(18)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Obx(() => _smartDefaultsNote()),
                  const SizedBox(height: 20),
                  _section('BASIC DETAILS'),
                  _field(
                    'Tournament title',
                    controller.title,
                    hint: 'BGMI Friday Cup',
                  ),
                  _gamePicker(),
                  _field(
                    'Description',
                    controller.description,
                    maxLines: 3,
                    required: false,
                  ),
                  _dropdowns(),
                  const SizedBox(height: 13),
                  _field(
                    'Game mode',
                    controller.gameMode,
                    hint: 'Battle Royale, 5v5, Search and Destroy…',
                    required: false,
                  ),
                  _bannerPicker(context),
                  const SizedBox(height: 22),
                  _section('ENTRY & CAPACITY'),
                  Text('Entry fee', style: CT.body(12)),
                  const SizedBox(height: 8),
                  _numberPresets(
                    controller.entryFee,
                    const [0, 50, 100, 200],
                    prefix: '₹',
                    onSelected: controller.setEntryFee,
                  ),
                  const SizedBox(height: 12),
                  Text('Player capacity', style: CT.body(12)),
                  const SizedBox(height: 8),
                  _numberPresets(
                    controller.maxPlayers,
                    const [16, 32, 64, 100],
                    onSelected: (value) =>
                        controller.setCapacity(value.toInt()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Entry fee (₹)',
                          controller.entryFee,
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          formatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Maximum players',
                          controller.maxPlayers,
                          keyboard: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Paid tournaments require verified host status.',
                    style: CT.body(11, color: CT.muted),
                  ),
                  const SizedBox(height: 22),
                  _section('SCHEDULE'),
                  Row(
                    children: [
                      Expanded(
                        child: _presetButton(
                          'This weekend',
                          Icons.auto_awesome_rounded,
                          () =>
                              controller.setSchedulePreset(nextWeekend: false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _presetButton(
                          'Next weekend',
                          Icons.event_available_rounded,
                          () => controller.setSchedulePreset(nextWeekend: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dateTile(
                    context,
                    'Registration starts',
                    controller.registrationStart,
                  ),
                  _dateTile(
                    context,
                    'Registration ends',
                    controller.registrationEnd,
                  ),
                  _dateTile(
                    context,
                    'Tournament starts',
                    controller.tournamentStart,
                  ),
                  _dateTile(
                    context,
                    'Tournament ends (optional)',
                    controller.tournamentEnd,
                    optional: true,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Match duration (minutes)',
                          controller.matchDuration,
                          keyboard: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Break duration (minutes)',
                          controller.breakDuration,
                          keyboard: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  _field(
                    'Concurrent matches',
                    controller.concurrentMatches,
                    hint: 'Number of matches that can run at once',
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  Text(
                    'These settings are used when the bracket is generated.',
                    style: CT.body(11, color: CT.muted),
                  ),
                  const SizedBox(height: 22),
                  _section('PRIZE DISTRIBUTION'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _textPreset(
                        'Winner takes all',
                        () => controller.setPrizePreset('winner'),
                      ),
                      _textPreset(
                        'Top 3 · 60/30/10',
                        () => controller.setPrizePreset('top_3'),
                      ),
                      _textPreset(
                        'Top 3 · 50/30/20',
                        () => controller.setPrizePreset('balanced'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _prizeDials(),
                  const SizedBox(height: 10),
                  Text(
                    'Drag any ring to adjust. The other prizes rebalance automatically to keep the total at 100%.',
                    style: CT.body(11, color: CT.muted),
                  ),
                  const SizedBox(height: 22),
                  _advancedOptions(context),
                  Obx(
                    () => controller.error.value == null
                        ? const SizedBox.shrink()
                        : Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CT.error.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CT.error.withValues(alpha: .4),
                              ),
                            ),
                            child: Text(
                              controller.error.value!,
                              style: CT.body(12, color: CT.error),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _smartDefaultsNote() {
    if (controller.loadingDefaults.value) {
      return Row(
        children: [
          const AppLinearLoader(width: 36, height: 3),
          const SizedBox(width: 9),
          Text('Preparing smart defaults…', style: CT.body(12)),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: CT.primaryBright,
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            controller.reusedPreviousSetup.value
                ? 'Your previous tournament setup is already filled in. Review it and publish when ready.'
                : 'Smart schedule and tournament defaults are ready. Use the quick options to finish faster.',
            style: CT.body(12),
          ),
        ),
      ],
    );
  }

  Widget _gamePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Choose a game *', style: CT.body(12)),
      const SizedBox(height: 8),
      ListenableBuilder(
        listenable: controller.game,
        builder: (context, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final game in CreateTournamentController.popularGames)
              ChoiceChip(
                label: Text(game),
                selected: controller.game.text == game,
                onSelected: (_) => controller.selectGame(game),
                selectedColor: CT.primary,
                backgroundColor: CT.surface,
                side: const BorderSide(color: CT.outline),
                labelStyle: CT.body(
                  12,
                  color: controller.game.text == game
                      ? Colors.black
                      : CT.onSurface,
                  w: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _field('Other game', controller.game, hint: 'Type another game'),
    ],
  );

  Widget _numberPresets(
    TextEditingController textController,
    List<num> values, {
    String prefix = '',
    required ValueChanged<num> onSelected,
  }) => ListenableBuilder(
    listenable: textController,
    builder: (context, _) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text('$prefix$value'),
            selected: textController.text == value.toString(),
            onSelected: (_) => onSelected(value),
            selectedColor: CT.primary,
            backgroundColor: CT.surface,
            side: const BorderSide(color: CT.outline),
            labelStyle: CT.body(
              12,
              color: textController.text == value.toString()
                  ? Colors.black
                  : CT.onSurface,
              w: FontWeight.w600,
            ),
          ),
      ],
    ),
  );

  Widget _presetButton(String label, IconData icon, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, maxLines: 1),
        style: OutlinedButton.styleFrom(
          foregroundColor: CT.primaryBright,
          side: const BorderSide(color: CT.outline),
          minimumSize: const Size.fromHeight(44),
          textStyle: CT.body(11.5, w: FontWeight.w600),
        ),
      );

  Widget _textPreset(String label, VoidCallback onTap) => ActionChip(
    onPressed: onTap,
    label: Text(label),
    backgroundColor: CT.surface,
    side: const BorderSide(color: CT.outline),
    labelStyle: CT.body(11.5, color: CT.onSurface, w: FontWeight.w600),
  );

  Widget _bannerPicker(BuildContext context) => Obx(() {
    controller.bannerInputVersion.value;
    final status = controller.bannerStatus.value;
    final url = controller.bannerUrl.text.trim();
    final generating =
        status == TournamentBannerStatus.generating ||
        status == TournamentBannerStatus.uploading;
    final hasBanner = url.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CT.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: CT.primaryBright,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('AI TOURNAMENT BANNER', style: CT.mono(11))),
              if (controller.bannerSource.value ==
                  TournamentBannerSource.generated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CT.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AI generated',
                    style: CT.body(9.5, color: CT.primaryBright),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: generating
                  ? _bannerLoading(status)
                  : hasBanner
                  ? GestureDetector(
                      onTap: () => _previewBanner(context, url),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.generatedBannerFailedToLoad();
                          });
                          return _bannerPlaceholder(
                            'Banner preview failed to load.',
                          );
                        },
                      ),
                    )
                  : _bannerPlaceholder(
                      controller.canGenerateBanner
                          ? 'Generate a banner designed for\n'
                                '${controller.game.text} • ${controller.effectiveGameMode} • ${controller.bannerTeamLabel}'
                          : 'Select a game and game mode to generate a tournament banner.',
                    ),
            ),
          ),
          if (controller.bannerError.value != null) ...[
            const SizedBox(height: 9),
            Text(
              controller.bannerError.value!,
              style: CT.body(11, color: CT.error),
            ),
          ],
          const SizedBox(height: 11),
          if (!hasBanner)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.canGenerateBanner && !generating
                        ? controller.generateBanner
                        : null,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: const Text('Generate Banner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CT.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                OutlinedButton(
                  onPressed: generating ? null : controller.uploadCustomBanner,
                  child: const Text('Upload'),
                ),
              ],
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (controller.bannerSource.value ==
                    TournamentBannerSource.generated)
                  OutlinedButton.icon(
                    onPressed: generating
                        ? null
                        : () => controller.generateBanner(regenerate: true),
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Regenerate'),
                  ),
                ElevatedButton.icon(
                  onPressed: generating
                      ? null
                      : controller.confirmGeneratedBanner,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Use Banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CT.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton(
                  onPressed: generating ? null : controller.uploadCustomBanner,
                  child: const Text('Upload Instead'),
                ),
                IconButton(
                  tooltip: 'Remove banner',
                  onPressed: generating ? null : controller.removeBanner,
                  icon: const Icon(Icons.delete_outline, color: CT.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  });

  Widget _bannerLoading(TournamentBannerStatus status) {
    final uploading = status == TournamentBannerStatus.uploading;
    return Container(
      color: CT.surfaceHigh,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLinearLoader(width: 120, height: 4),
          const SizedBox(height: 14),
          Text(
            uploading
                ? 'Uploading your tournament banner…'
                : 'Creating your tournament banner…',
            textAlign: TextAlign.center,
            style: CT.body(12, color: CT.muted),
          ),
        ],
      ),
    );
  }

  Widget _bannerPlaceholder(String text) => Container(
    color: CT.surfaceHigh,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.image_outlined, color: CT.muted, size: 32),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: CT.body(11.5)),
      ],
    ),
  );

  void _previewBanner(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _advancedOptions(BuildContext context) => Obx(
    () => Column(
      children: [
        InkWell(
          onTap: () => controller.advancedExpanded.toggle(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Advanced options', style: CT.headline(15)),
                      const SizedBox(height: 2),
                      Text(
                        'Rules, banner and community links',
                        style: CT.body(11.5),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: controller.advancedExpanded.value ? .5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: CT.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: controller.advancedExpanded.value
              ? Column(
                  children: [
                    _section('ESPORTS OPERATIONS'),
                    _field(
                      'Platform',
                      controller.platform,
                      hint: 'e.g. mobile, pc',
                      required: false,
                    ),
                    _field(
                      'Organization name',
                      controller.organizationName,
                      required: false,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Team size',
                            controller.teamSize,
                            keyboard: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            'Substitute limit',
                            controller.substituteLimit,
                            keyboard: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Minimum age',
                            controller.minimumAge,
                            keyboard: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            required: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            'Minimum entries',
                            controller.minEntries,
                            keyboard: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    _field('Region', controller.region, required: false),
                    _dropdown(
                      'Registration policy',
                      controller.registrationPolicy.value,
                      const {
                        'automatic': 'Automatic',
                        'manual_approval': 'Manual approval',
                      },
                      (value) => controller.registrationPolicy.value = value,
                    ),
                    const SizedBox(height: 13),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: CT.primary,
                      title: Text('Private tournament', style: CT.headline(14)),
                      subtitle: Text(
                        'Require an invite code to view or join',
                        style: CT.body(12),
                      ),
                      value: controller.isPrivate.value,
                      onChanged: (value) => controller.isPrivate.value = value,
                    ),
                    if (controller.isPrivate.value)
                      _field(
                        'Invite code',
                        controller.inviteCode,
                        required: false,
                      ),
                    _dateTile(
                      context,
                      'Roster lock (optional)',
                      controller.rosterLockAt,
                      optional: true,
                    ),
                    _dateTile(
                      context,
                      'Check-in starts (optional)',
                      controller.checkInStartAt,
                      optional: true,
                    ),
                    _dateTile(
                      context,
                      'Check-in ends (optional)',
                      controller.checkInEndAt,
                      optional: true,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Result window (min)',
                            controller.resultSubmissionWindow,
                            keyboard: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            'Dispute window (min)',
                            controller.disputeWindow,
                            keyboard: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    _field(
                      'Max matches per team/day',
                      controller.maxMatchesPerTeamPerDay,
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      required: false,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: CT.primary,
                      title: Text(
                        'Require result evidence',
                        style: CT.headline(14),
                      ),
                      value: controller.evidenceRequired.value,
                      onChanged: (value) =>
                          controller.evidenceRequired.value = value,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Rules',
                      controller.rules,
                      maxLines: 4,
                      required: false,
                    ),
                    _field(
                      'Discord link',
                      controller.discordLink,
                      keyboard: TextInputType.url,
                      required: false,
                    ),
                    _field(
                      'WhatsApp link',
                      controller.whatsappLink,
                      keyboard: TextInputType.url,
                      required: false,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: CT.primary,
                      title: Text('Publicly visible', style: CT.headline(14)),
                      subtitle: Text(
                        'Show this tournament in discovery',
                        style: CT.body(12),
                      ),
                      value: controller.visibility.value,
                      onChanged: (value) => controller.visibility.value = value,
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
        Container(height: 1, color: CT.outline),
      ],
    ),
  );

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: CT.mono(11)),
  );

  Widget _field(
    String label,
    TextEditingController textController, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextField(
      controller: textController,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: CT.body(14, color: CT.onSurface),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        filled: true,
        fillColor: CT.surface,
        labelStyle: CT.body(13),
        hintStyle: CT.body(13, color: CT.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CT.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CT.primary),
        ),
      ),
    ),
  );

  Widget _dropdowns() => Row(
    children: [
      Expanded(
        child: Obx(
          () => _dropdown(
            'Format',
            controller.tournamentType.value,
            const {
              'single_elimination': 'Single elimination',
              'double_elimination': 'Double elimination',
              'round_robin': 'Round robin',
              'battle_royale': 'Battle royale',
            },
            (value) => controller.tournamentType.value = value,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Obx(
          () => _dropdown(
            'Team mode',
            controller.teamMode.value,
            const {
              'solo': 'Solo',
              'duo': 'Duo',
              'squad': 'Squad',
              'team': 'Team',
            },
            (value) => controller.teamMode.value = value,
          ),
        ),
      ),
    ],
  );

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> values,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    dropdownColor: CT.surfaceHigh,
    style: CT.body(13, color: CT.onSurface),
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: CT.surface,
      labelStyle: CT.body(12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CT.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CT.primary),
      ),
    ),
    items: values.entries
        .map(
          (item) => DropdownMenuItem(value: item.key, child: Text(item.value)),
        )
        .toList(),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );

  Widget _dateTile(
    BuildContext context,
    String label,
    Rxn<DateTime> value, {
    bool optional = false,
  }) => Obx(
    () => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => controller.pickDateTime(context, value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: CT.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CT.outline),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_outlined,
                color: CT.primaryBright,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(optional ? label : '$label *', style: CT.body(11)),
                    const SizedBox(height: 2),
                    Text(
                      value.value == null
                          ? 'Select date and time'
                          : _date(value.value!),
                      style: CT.headline(13),
                    ),
                  ],
                ),
              ),
              if (optional && value.value != null)
                IconButton(
                  onPressed: () => value.value = null,
                  icon: const Icon(Icons.close, color: CT.muted, size: 18),
                )
              else
                const Icon(Icons.chevron_right, color: CT.muted),
            ],
          ),
        ),
      ),
    ),
  );

  String _date(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }

  Widget _prizeDials() => Obx(
    () => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _PrizeDial(
          rank: '1ST',
          value: controller.prizePercents[0],
          color: const Color(0xFFFFD24C),
          onChanged: (value) => controller.setPrizePercent(0, value),
        ),
        _PrizeDial(
          rank: '2ND',
          value: controller.prizePercents[1],
          color: const Color(0xFFC0C0C0),
          onChanged: (value) => controller.setPrizePercent(1, value),
        ),
        _PrizeDial(
          rank: '3RD',
          value: controller.prizePercents[2],
          color: const Color(0xFFCD7F32),
          onChanged: (value) => controller.setPrizePercent(2, value),
        ),
      ],
    ),
  );

  Widget _actions() => Obx(
    () => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: CT.surfaceLow,
        border: Border(top: BorderSide(color: CT.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.submitting.value
                  ? null
                  : () => controller.submit(publish: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: CT.onSurface,
                side: const BorderSide(color: CT.outline),
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(controller.saveLabel),
            ),
          ),
          if (controller.canPublish) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.submitting.value
                    ? null
                    : () => controller.submit(publish: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CT.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: controller.submitting.value
                    ? const AppLinearLoader.button()
                    : const Text('Publish'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PrizeDial extends StatelessWidget {
  final String rank;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _PrizeDial({
    required this.rank,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const size = 88.0;
    void update(Offset position) {
      final delta = position - const Offset(size / 2, size / 2);
      var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
      if (angle < 0) angle += math.pi * 2;
      onChanged(angle / (math.pi * 2) * 100);
    }

    return Semantics(
      label: '$rank prize percentage',
      value: '${value.round()} percent',
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) => update(details.localPosition),
            onPanUpdate: (details) => update(details.localPosition),
            onTapDown: (details) => update(details.localPosition),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _PrizeDialPainter(value: value, color: color),
                child: Center(
                  child: Text(
                    '${value.round()}%',
                    style: CT.headline(16, color: color),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(rank, style: CT.mono(9, color: color)),
        ],
      ),
    );
  }
}

class _PrizeDialPainter extends CustomPainter {
  final double value;
  final Color color;

  const _PrizeDialPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = CT.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value / 100,
        false,
        progress,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrizeDialPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
