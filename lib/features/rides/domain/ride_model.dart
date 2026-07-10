/// Mirrors the backend Ride schema + the `fare` breakdown attached by
/// GET /rides and GET /rides/:id.
class Ride {
  final String id;
  final String rideCode; // e.g. SHY-N06
  final String route; // noida | gurugram | noida-gurugram | gurugram-noida
  final String origin; // "IGI Airport" or intercity origin
  final String routeType; // airport | intercity
  final String? dest;
  final int? depHour;
  final String? departure; // "06:00 AM"
  final String? arrival;
  final String? eta;
  final int capacity;
  final int occupancy;
  final num baseFare;
  final bool women;
  final String status; // scheduled | boarding | progress | completed | cancelled
  final String vehicleType;
  final String? mainHotspot;
  final List<String> covers;
  final List<String> pickups; // intercity only
  final List<RiderSnapshot> riders;
  final Driver? driver;
  final FareBreakdown? fare;
  final DateTime? expiresAt;

  const Ride({
    required this.id,
    required this.rideCode,
    required this.route,
    required this.origin,
    required this.routeType,
    this.dest,
    this.depHour,
    this.departure,
    this.arrival,
    this.eta,
    this.capacity = 3,
    this.occupancy = 0,
    this.baseFare = 0,
    this.women = false,
    this.status = 'scheduled',
    this.vehicleType = 'Sedan',
    this.mainHotspot,
    this.covers = const [],
    this.pickups = const [],
    this.riders = const [],
    this.driver,
    this.fare,
    this.expiresAt,
  });

  bool get isAirport => routeType == 'airport';
  bool get isOpen => status == 'scheduled' || status == 'boarding';
  int get seatsLeft => (capacity - occupancy).clamp(0, capacity);

  String get routeLabel => isAirport
      ? 'IGI Airport → ${dest ?? _cityFromRoute()}'
      : '${origin} → ${dest ?? _cityFromRoute()}';

  String _cityFromRoute() => switch (route) {
        'gurugram' || 'noida-gurugram' => 'Gurugram',
        _ => 'Noida',
      };

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
        id: (j['_id'] ?? '').toString(),
        rideCode: j['rideCode'] as String? ?? '',
        route: j['route'] as String? ?? 'noida',
        origin: j['origin'] as String? ?? 'IGI Airport',
        routeType: j['routeType'] as String? ?? 'airport',
        dest: j['dest'] as String?,
        depHour: (j['depHour'] as num?)?.toInt(),
        departure: j['departure'] as String?,
        arrival: j['arrival'] as String?,
        eta: j['eta'] as String?,
        capacity: (j['capacity'] as num?)?.toInt() ?? 3,
        occupancy: (j['occupancy'] as num?)?.toInt() ?? 0,
        baseFare: j['baseFare'] as num? ?? 0,
        women: j['women'] as bool? ?? false,
        status: j['status'] as String? ?? 'scheduled',
        vehicleType: j['vehicleType'] as String? ?? 'Sedan',
        mainHotspot: j['mainHotspot'] as String?,
        covers: (j['covers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        pickups: (j['pickups'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        riders: (j['riders'] as List?)
                ?.map((e) => RiderSnapshot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        driver: j['driver'] is Map<String, dynamic>
            ? Driver.fromJson(j['driver'] as Map<String, dynamic>)
            : null,
        fare: j['fare'] is Map<String, dynamic>
            ? FareBreakdown.fromJson(j['fare'] as Map<String, dynamic>)
            : null,
        expiresAt: DateTime.tryParse(j['expiresAt']?.toString() ?? ''),
      );
}

class RiderSnapshot {
  final String? firstName;
  final String? gender;
  final String? ageRange;
  final bool verified;
  final num? rating;
  final List<String> langs;
  final String? avatar;

  const RiderSnapshot({
    this.firstName,
    this.gender,
    this.ageRange,
    this.verified = false,
    this.rating,
    this.langs = const [],
    this.avatar,
  });

  factory RiderSnapshot.fromJson(Map<String, dynamic> j) => RiderSnapshot(
        firstName: j['firstName'] as String?,
        gender: j['gender'] as String?,
        ageRange: j['ageRange'] as String?,
        verified: j['verified'] as bool? ?? false,
        rating: j['rating'] as num?,
        langs: (j['langs'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        avatar: j['avatar'] as String?,
      );
}

class Driver {
  final String id;
  final String name;
  final bool female;
  final String? vehicle;
  final String? plate;
  final num rating;
  final int trips;
  final String status;

  const Driver({
    required this.id,
    required this.name,
    this.female = false,
    this.vehicle,
    this.plate,
    this.rating = 4.8,
    this.trips = 0,
    this.status = 'available',
  });

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
        id: (j['_id'] ?? '').toString(),
        name: j['name'] as String? ?? 'Driver',
        female: j['female'] as bool? ?? false,
        vehicle: j['vehicle'] as String?,
        plate: j['plate'] as String?,
        rating: j['rating'] as num? ?? 4.8,
        trips: (j['trips'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? 'available',
      );
}

/// `fare` block from the rides API: current per-person split + projected.
class FareBreakdown {
  final num current;
  final num projected;
  final num savings;
  const FareBreakdown(
      {required this.current, required this.projected, required this.savings});

  factory FareBreakdown.fromJson(Map<String, dynamic> j) => FareBreakdown(
        current: j['current'] as num? ?? 0,
        projected: j['projected'] as num? ?? 0,
        savings: j['savings'] as num? ?? 0,
      );
}
