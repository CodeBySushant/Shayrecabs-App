import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_client.dart";

class SupportRepository {
  SupportRepository(this._api);
  final ApiClient _api;

  /// Public contact form — POST /support/contact.
  Future<void> contact({
    required String name,
    required String email,
    String? subject,
    required String message,
  }) =>
      _api.post("/support/contact", body: {
        "name": name,
        "email": email,
        if (subject != null && subject.isNotEmpty) "subject": subject,
        "message": message,
      });

  /// Authenticated complaint — POST /support/complaints.
  Future<void> fileComplaint({required String category, required String details}) =>
      _api.post("/support/complaints",
          body: {"category": category, "details": details}, auth: true);
}

final supportRepositoryProvider =
    Provider((ref) => SupportRepository(ApiClient.instance));
