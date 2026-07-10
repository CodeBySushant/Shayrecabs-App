import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/network/api_client.dart";
import "../domain/community_model.dart";

class CommunityRepository {
  CommunityRepository(this._api);
  final ApiClient _api;

  Future<List<Community>> list({String? category, bool featured = false}) async {
    final res = await _api.get("/communities", query: {
      if (category != null && category != "all") "category": category,
      if (featured) "featured": "true",
    });
    return (res["communities"] as List)
        .map((e) => Community.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityItem>> activity() async {
    final res = await _api.get("/communities/activity");
    return (res["activity"] as List)
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final communityRepositoryProvider =
    Provider((ref) => CommunityRepository(ApiClient.instance));

final communitiesProvider = FutureProvider<List<Community>>(
    (ref) => ref.watch(communityRepositoryProvider).list());

final communityActivityProvider = FutureProvider<List<ActivityItem>>(
    (ref) => ref.watch(communityRepositoryProvider).activity());
