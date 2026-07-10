/// Mirrors the backend Community schema (WhatsApp groups) and the
/// anonymized activity feed from GET /communities/activity.
class Community {
  final String id;
  final String key;
  final String category; // destination | area | special
  final String name;
  final String? city;
  final String? description;
  final int members;
  final bool featured;
  final bool women;
  final String? whatsappLink;

  const Community({
    required this.id,
    required this.key,
    required this.category,
    required this.name,
    this.city,
    this.description,
    this.members = 0,
    this.featured = false,
    this.women = false,
    this.whatsappLink,
  });

  factory Community.fromJson(Map<String, dynamic> j) => Community(
        id: (j["_id"] ?? "").toString(),
        key: j["key"] as String? ?? "",
        category: j["category"] as String? ?? "area",
        name: j["name"] as String? ?? "",
        city: j["city"] as String?,
        description: j["description"] as String?,
        members: (j["members"] as num?)?.toInt() ?? 0,
        featured: j["featured"] as bool? ?? false,
        women: j["women"] as bool? ?? false,
        whatsappLink: j["whatsappLink"] as String?,
      );
}

class ActivityItem {
  final String id;
  final String user;
  final String text;
  final DateTime? time;

  const ActivityItem({required this.id, required this.user, required this.text, this.time});

  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
        id: (j["id"] ?? "").toString(),
        user: j["user"] as String? ?? "A traveller",
        text: j["text"] as String? ?? "",
        time: DateTime.tryParse(j["time"]?.toString() ?? ""),
      );
}
