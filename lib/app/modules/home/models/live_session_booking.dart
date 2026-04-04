class LiveSessionBooking {
  LiveSessionBooking({
    required this.bookingId,
    required this.arenaName,
    required this.vendorId,
    required this.rawBooking,
    required this.startAt,
    required this.endAt,
  });

  final String bookingId;
  final String arenaName;
  final String vendorId;
  final Map<String, dynamic> rawBooking;
  final DateTime startAt;
  final DateTime endAt;

  static LiveSessionBooking? fromPastBooking(Map<String, dynamic> booking) {
    if (!_isConfirmedBooking(booking)) return null;

    final slot = booking['slot'] is Map
        ? Map<String, dynamic>.from(booking['slot'] as Map)
        : <String, dynamic>{};
    final timeMap = slot['time'] is Map
        ? Map<String, dynamic>.from(slot['time'] as Map)
        : <String, dynamic>{};

    final rawStart =
        (timeMap['start_time'] ??
                slot['start_time'] ??
                booking['start_time'] ??
                '')
            .toString()
            .trim();
    final rawEnd =
        (timeMap['end_time'] ?? slot['end_time'] ?? booking['end_time'] ?? '')
            .toString()
            .trim();

    if (rawStart.isEmpty || rawEnd.isEmpty) return null;

    final baseDate = _resolveBaseDate(booking);
    if (baseDate == null) return null;

    final startAt = _parseTimeOnDate(baseDate, rawStart);
    var endAt = _parseTimeOnDate(baseDate, rawEnd);

    // Overnight session support (e.g. 23:00 -> 01:00)
    if (endAt.isBefore(startAt)) {
      endAt = endAt.add(const Duration(days: 1));
    }

    final bookingId = (booking['booking_id'] ?? booking['id'] ?? '')
        .toString()
        .trim();

    final rawArenaName = _resolveArenaName(slot, booking);
    final vendorId = _resolveVendorId(slot, booking);

    final arenaName = rawArenaName.trim().isEmpty
        ? 'Arena Session'
        : rawArenaName.trim();

    return LiveSessionBooking(
      bookingId: bookingId,
      arenaName: arenaName,
      vendorId: vendorId,
      rawBooking: Map<String, dynamic>.from(booking),
      startAt: startAt,
      endAt: endAt,
    );
  }

  static bool _isConfirmedBooking(Map<String, dynamic> booking) {
    final rawStatus =
        (booking['status'] ??
                booking['booking_status'] ??
                booking['payment_status'] ??
                '')
            .toString()
            .toLowerCase()
            .trim();

    if (rawStatus.isEmpty) return false;
    if (rawStatus.contains('pending_verified')) return false;
    return rawStatus.contains('confirm') || rawStatus.contains('success');
  }

  static DateTime _parseTimeOnDate(DateTime date, String rawTime) {
    final parts = rawTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  static DateTime? _resolveBaseDate(Map<String, dynamic> booking) {
    final rawBookDate = (booking['book_date'] ?? '').toString().trim();
    final rawCreatedAt = (booking['created_at'] ?? '').toString().trim();
    final rawUpdatedAt = (booking['updated_at'] ?? '').toString().trim();

    DateTime? createdAtDate;
    if (rawCreatedAt.isNotEmpty) {
      final createdAt = DateTime.tryParse(rawCreatedAt);
      if (createdAt != null) {
        createdAtDate = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );
      }
    }

    DateTime? updatedAtDate;
    if (rawUpdatedAt.isNotEmpty) {
      final updatedAt = DateTime.tryParse(rawUpdatedAt);
      if (updatedAt != null) {
        updatedAtDate = DateTime(
          updatedAt.year,
          updatedAt.month,
          updatedAt.day,
        );
      }
    }

    if (rawBookDate.isNotEmpty) {
      // Supports "yyyy-MM-dd"
      DateTime? parsed = DateTime.tryParse(rawBookDate);
      if (parsed == null && rawBookDate.length == 8) {
        // Supports "yyyyMMdd"
        final year = int.tryParse(rawBookDate.substring(0, 4));
        final month = int.tryParse(rawBookDate.substring(4, 6));
        final day = int.tryParse(rawBookDate.substring(6, 8));
        if (year != null && month != null && day != null) {
          parsed = DateTime(year, month, day);
        }
      }
      if (parsed != null) {
        final bookDate = DateTime(parsed.year, parsed.month, parsed.day);

        // Backend may send stale `book_date` while slot/timestamps are from next day.
        // If created/updated timestamps are later than bookDate, prefer the fresher date.
        if (createdAtDate != null && createdAtDate.isAfter(bookDate)) {
          return createdAtDate;
        }
        if (updatedAtDate != null && updatedAtDate.isAfter(bookDate)) {
          return updatedAtDate;
        }
        return bookDate;
      }
    }

    if (createdAtDate != null) {
      return createdAtDate;
    }
    if (updatedAtDate != null) {
      return updatedAtDate;
    }

    return null;
  }

  static String _resolveArenaName(
    Map<String, dynamic> slot,
    Map<String, dynamic> booking,
  ) {
    final gamingType = slot['gaming_type_id'] is Map
        ? Map<String, dynamic>.from(slot['gaming_type_id'] as Map)
        : <String, dynamic>{};
    final nestedCafe = gamingType['cafe_name'];

    if (nestedCafe is Map) {
      final cafe = (nestedCafe['cafe_name'] ?? '').toString().trim();
      if (cafe.isNotEmpty) return cafe;
    } else if (nestedCafe != null) {
      final cafe = nestedCafe.toString().trim();
      if (cafe.isNotEmpty) return cafe;
    }

    final fallback =
        (slot['cafe_name'] ?? gamingType['cafe'] ?? booking['cafe_name'] ?? '')
            .toString()
            .trim();
    return fallback.isEmpty ? 'Arena Session' : fallback;
  }

  static String _resolveVendorId(
    Map<String, dynamic> slot,
    Map<String, dynamic> booking,
  ) {
    final gamingType = slot['gaming_type_id'] is Map
        ? Map<String, dynamic>.from(slot['gaming_type_id'] as Map)
        : <String, dynamic>{};
    final nestedCafe = gamingType['cafe_name'] is Map
        ? Map<String, dynamic>.from(gamingType['cafe_name'] as Map)
        : <String, dynamic>{};
    final candidates = [
      booking['vendor_id'],
      booking['vendorId'],
      booking['cafe_id'],
      slot['vendor_id'],
      slot['vendorId'],
      slot['cafe_id'],
      gamingType['vendor_id'],
      gamingType['vendorId'],
      gamingType['cafe_id'],
      nestedCafe['vendor_id'],
      nestedCafe['vendorId'],
      nestedCafe['id'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }
}
