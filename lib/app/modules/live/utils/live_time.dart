/// "Starts in 2h 15m" style label for a scheduled stream, relative to [now].
String startsInLabel(DateTime start, DateTime now) {
  final left = start.difference(now);
  if (left.inSeconds <= 60) return 'Starting now';
  if (left.inMinutes < 60) return 'Starts in ${left.inMinutes}m';
  if (left.inHours < 24) {
    final m = left.inMinutes % 60;
    return m == 0
        ? 'Starts in ${left.inHours}h'
        : 'Starts in ${left.inHours}h ${m}m';
  }
  final days = left.inDays;
  return days == 1 ? 'Starts tomorrow' : 'Starts in $days days';
}

/// "2h ago" style label for when a stream ended.
String agoLabel(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${d.inDays ~/ 7}w ago';
}
