import "package:intl/intl.dart";

final inr = NumberFormat.currency(locale: "en_IN", symbol: "\u20B9", decimalDigits: 0);

String formatInr(num? v) => v == null ? "\u2014" : inr.format(v);

String formatDate(DateTime? d) =>
    d == null ? "\u2014" : DateFormat("d MMM yyyy").format(d.toLocal());

String formatDateTime(DateTime? d) =>
    d == null ? "\u2014" : DateFormat("d MMM, h:mm a").format(d.toLocal());

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  return "${diff.inDays}d ago";
}
