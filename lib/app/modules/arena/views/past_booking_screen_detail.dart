import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ViewDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String endTime;
  final String startTime;

  const ViewDetailScreen({
    super.key,
    required this.booking,
    required this.startTime,
    required this.endTime,
  });

  static const Color _bgColor = Color(0xFF060606);
  static const Color _cardColor = Color(0xFF131313);

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  String _readString(dynamic value, {String fallback = 'N/A'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _prettyStatus(String rawStatus) {
    return rawStatus
        .split('_')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map(_capitalize)
        .join(' ');
  }

  Color _statusColor(String rawStatus) {
    final status = rawStatus.toLowerCase();
    if (status.contains('confirm') || status.contains('success')) {
      return const Color(0xff00DC00);
    }
    if (status.contains('cancel') || status.contains('fail')) {
      return const Color(0xFFE45858);
    }
    return const Color(0xFFF7B731);
  }

  String _formatDate(dynamic rawDate) {
    final value = _readString(rawDate, fallback: '');
    if (value.isEmpty) return 'N/A';

    DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      for (final format in ['yyyy-MM-dd', 'dd-MM-yyyy', 'yyyy/MM/dd']) {
        try {
          parsed = DateFormat(format).parseStrict(value);
          break;
        } catch (_) {
          // keep trying
        }
      }
    }

    if (parsed == null) return value;
    return DateFormat('EEE, dd MMM yyyy').format(parsed);
  }

  String _formatSingleTime(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 'N/A';

    for (final format in ['HH:mm:ss', 'HH:mm', 'h:mm a']) {
      try {
        final parsed = DateFormat(format).parseStrict(raw);
        return DateFormat('h:mm a').format(parsed);
      } catch (_) {
        // keep trying
      }
    }

    return raw;
  }

  String _formatTimeRange(String start, String end) {
    final formattedStart = _formatSingleTime(start);
    final formattedEnd = _formatSingleTime(end);

    if (formattedStart == 'N/A' && formattedEnd == 'N/A') return 'N/A';
    if (formattedEnd == 'N/A') return formattedStart;
    if (formattedStart == 'N/A') return formattedEnd;
    return '$formattedStart - $formattedEnd';
  }

  Widget _sectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
    bool divider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: divider
            ? Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 17),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Short names like "pc" read as acronyms; longer ones get title case.
  String _prettyGame(String name) =>
      name.length <= 3 ? name.toUpperCase() : _prettyStatus(name);

  Widget _buildServiceRow(dynamic service) {
    final serviceMap = _asMap(service);
    final name = _readString(serviceMap['name'], fallback: 'Unknown Service');
    final quantity = _readString(serviceMap['quantity'], fallback: '0');
    final unitPrice = _readDouble(serviceMap['price']);
    final totalPrice = _readDouble(serviceMap['total_price']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: $quantity x Rs ${unitPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            'Rs ${totalPrice.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: const Color(0xff00DC00),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot = _asMap(booking['slot']);
    final gamingType = _asMap(slot['gaming_type_id']);
    final cafeName =
        CybercafesController.cafeNameForBooking(booking) ?? 'Your booking';
    final gameName = _prettyGame(
      _readString(gamingType['game_name'], fallback: 'Game'),
    );
    final statusRaw = _readString(booking['status'], fallback: 'pending');
    final statusLabel = _prettyStatus(statusRaw);
    final statusColor = _statusColor(statusRaw);
    final location = _readString(slot['location'], fallback: '');
    final bookingId = _readString(booking['booking_id'], fallback: '--');
    final accessCode = _readString(booking['access_code'], fallback: '');
    final formattedDate = _formatDate(booking['book_date']);
    final formattedTime = _formatTimeRange(startTime, endTime);
    final price = _readDouble(gamingType['single_slot_price']);
    final extraServices = _asList(booking['extra_services']);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Booking Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080808), Color(0xFF020202)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B1B1B), Color(0xFF101010)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              cafeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_esports_rounded,
                            size: 16,
                            color: Color(0xff00DC00),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            gameName,
                            style: GoogleFonts.inter(
                              color: const Color(0xff00DC00),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedTime,
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _detailRow(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Booking ID',
                        value: '#$bookingId',
                      ),
                      if (accessCode.isNotEmpty)
                        _detailRow(
                          icon: Icons.password_rounded,
                          label: 'Access code',
                          value: accessCode,
                        ),
                      _detailRow(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Amount',
                        value: 'Rs ${price.toStringAsFixed(0)}',
                        valueColor: const Color(0xff00DC00),
                        divider: false,
                      ),
                    ],
                  ),
                ),
                if (extraServices.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Services',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...extraServices.map<Widget>(_buildServiceRow),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _sectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFF7B731),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Important Notes',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• Please arrive 15 minutes early.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '• Booking amount is non-refundable.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '• Contact the cafe directly for booking changes.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '#HashforGamers',
                        style: GoogleFonts.inter(
                          color: const Color(0xff00DC00),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For Gamers, By Gamers',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
