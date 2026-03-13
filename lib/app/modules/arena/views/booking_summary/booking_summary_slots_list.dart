import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Slots',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${sortedSlots.length} slots • ${widget.selectedDate}',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
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
                  color: const Color(0xFF00DC00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00DC00),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _expanded ? 280 : 176),
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
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              consoleLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${slot['start_time']} - ${slot['end_time']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${slotPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF00DC00),
                          fontSize: 12,
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
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show Less'
                          : 'Show All ${sortedSlots.length} Slots',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
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
