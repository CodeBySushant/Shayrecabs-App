import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/ride_model.dart';

class RidesRepository {
  RidesRepository(this._api);
  final ApiClient _api;

  /// GET /rides — filters mirror the web board: route, womenOnly, hotspot, openOnly.
  Future<List<Ride>> list({
    String? route,
    bool? womenOnly,
    String? hotspot,
    bool openOnly = false,
  }) async {
    final res = await _api.get('/rides', query: {
      if (route != null && route != 'all') 'route': route,
      if (womenOnly == true) 'womenOnly': 'true',
      if (hotspot != null && hotspot != 'all') 'hotspot': hotspot,
      if (openOnly) 'openOnly': 'true',
    });
    return (res['rides'] as List)
        .map((e) => Ride.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /rides/:id — accepts rideCode (SHY-N06) or Mongo _id.
  Future<Ride> get(String idOrCode) async {
    final res = await _api.get('/rides/$idOrCode');
    return Ride.fromJson(res['ride'] as Map<String, dynamic>);
  }
}

final ridesRepositoryProvider =
    Provider((ref) => RidesRepository(ApiClient.instance));

/// Filter state for the Live Rides board.
class RideFilters {
  final String route; // all | noida | gurugram | noida-gurugram | gurugram-noida
  final bool womenOnly;
  final bool openOnly;
  const RideFilters(
      {this.route = 'all', this.womenOnly = false, this.openOnly = true});

  RideFilters copyWith({String? route, bool? womenOnly, bool? openOnly}) =>
      RideFilters(
        route: route ?? this.route,
        womenOnly: womenOnly ?? this.womenOnly,
        openOnly: openOnly ?? this.openOnly,
      );
}

final rideFiltersProvider =
    StateProvider<RideFilters>((ref) => const RideFilters());

final ridesListProvider = FutureProvider<List<Ride>>((ref) {
  final f = ref.watch(rideFiltersProvider);
  return ref.watch(ridesRepositoryProvider).list(
        route: f.route,
        womenOnly: f.womenOnly,
        openOnly: f.openOnly,
      );
});

final rideDetailsProvider = FutureProvider.family<Ride, String>(
    (ref, id) => ref.watch(ridesRepositoryProvider).get(id));
