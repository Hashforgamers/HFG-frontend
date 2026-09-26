import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';
import 'package:hash/core/localization/app_region.dart';

class BookingSummarySlotsList extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSlots;
  final String selectedDate;
  final String consoleType;

  const BookingSummarySlotsList({
    super.key,
    required this.selectedSlots,
    required this.selectedDate,
    required this.consoleType,
  });

  @override
  State<BookingSummarySlotsList> createState() =>
      _BookingSummarySlotsListState();
}

class _BookingSummarySlotsListState extends State<BookingSummarySlotsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sortedSlots = [...widget.selectedSlots]
      ..sort((a, b) {
        final aStart = (a['start_time'] ?? '').toString();
        final bStart = (b['start_time'] ?? '').toString();
        final byTime = aStart.compareTo(bStart);
        if (byTime != 0) return byTime;
        final aConsole = (a['console_label'] ?? '').toString();
        final bConsole = (b['console_label'] ?? '').toString();
        return aConsole.compareTo(bConsole);
      });

    final visibleSlots = _expanded ? sortedSlots : sortedSlots.take(4).toList();
    final hasOverflow = sortedSlots.length > 4;
    final totalPrice = sortedSlots.fold<double>(
      0,
      (sum, slot) => sum + ((slot['price'] ?? 50.0) as num).toDouble(),
    );

    return BookingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BookingColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_seat_rounded,
                  size: 18,
                  color: BookingColors.accentBright,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected slots', style: BookingText.title(context)),
                    const SizedBox(height: 3),
                    Text(
                      '${sortedSlots.length} slots • ${widget.selectedDate}',
                      style: BookingText.muted(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: BookingColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BookingRadius.pill),
                ),
                child: Text(
                  '${Money.symbol}${totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: BookingColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _expanded ? 280 : 200),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: visibleSlots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final slot = visibleSlots[index];
                final slotPrice = ((slot['price'] ?? 50.0) as num).toDouble();
                final consoleLabel =
                    (slot['console_label'] ??
                            '${widget.consoleType} ${slot['pc_index']}')
                        .toString();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: BookingColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BookingColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: BookingColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: BookingColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              consoleLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: BookingColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: BookingColors.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${slot['start_time']} - ${slot['end_time']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: BookingText.muted(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${Money.symbol}${slotPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: BookingColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (hasOverflow) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: BookingColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BookingColors.borderSoft),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'Show all ${sortedSlots.length} slots',
                      style: GoogleFonts.inter(
                        color: BookingColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: BookingColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
