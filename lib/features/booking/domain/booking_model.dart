import '../../rides/domain/ride_model.dart';

/// Mirrors the backend Booking schema (populated with ride + driver
/// by GET /bookings).
class Booking {
  final String id;
  final Ride? ride;
  final String? terminal;
  final String? flightNumber;
  final String? airline;
  final String? pickupHotspot;
  final int passengers; // sharing type chosen (2 or 3)
  final String? dropHotspot;
  final bool womenOnly;
  final num? fareCharged;
  final String status; // pending_payment | confirmed | cancelled | completed
  final bool paid;
  final String? txnid;
  final DateTime? holdExpiresAt;
  final DateTime? departureAt;
  final DateTime? cancelledAt;
  final int? rating;
  final String? feedback;
  final DateTime? createdAt;

  const Booking({
    required this.id,
    this.ride,
    this.terminal,
    this.flightNumber,
    this.airline,
    this.pickupHotspot,
    this.passengers = 1,
    this.dropHotspot,
    this.womenOnly = false,
    this.fareCharged,
    this.status = 'pending_payment',
    this.paid = false,
    this.txnid,
    this.holdExpiresAt,
    this.departureAt,
    this.cancelledAt,
    this.rating,
    this.feedback,
    this.createdAt,
  });

  bool get isPendingPayment => status == 'pending_payment' && !paid;
  bool get canCancel => status == 'confirmed' || status == 'pending_payment';
  bool get departed =>
      departureAt != null && departureAt!.isBefore(DateTime.now());

  /// Rating unlocks on completed rides — or confirmed+paid rides whose
  /// departure has passed (backend flips them lazily).
  bool get canRate =>
      rating == null &&
      (status == 'completed' || (status == 'confirmed' && paid && departed));

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: (j['_id'] ?? '').toString(),
        ride: j['ride'] is Map<String, dynamic>
            ? Ride.fromJson(j['ride'] as Map<String, dynamic>)
            : null,
        terminal: j['terminal'] as String?,
        flightNumber: j['flightNumber'] as String?,
        airline: j['airline'] as String?,
        pickupHotspot: j['pickupHotspot'] as String?,
        passengers: (j['passengers'] as num?)?.toInt() ?? 1,
        dropHotspot: j['dropHotspot'] as String?,
        womenOnly: j['womenOnly'] as bool? ?? false,
        fareCharged: j['fareCharged'] as num?,
        status: j['status'] as String? ?? 'pending_payment',
        paid: j['paid'] as bool? ?? false,
        txnid: j['txnid'] as String?,
        holdExpiresAt: DateTime.tryParse(j['holdExpiresAt']?.toString() ?? ''),
        departureAt: DateTime.tryParse(j['departureAt']?.toString() ?? ''),
        cancelledAt: DateTime.tryParse(j['cancelledAt']?.toString() ?? ''),
        rating: (j['rating'] as num?)?.toInt(),
        feedback: j['feedback'] as String?,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

/// Refund created on cancellation of a paid booking (policy bands mirror
/// the backend: >24h ₹200 flat · 12–24h 50% · <12h no refund).
class Refund {
  final String refundCode;
  final num amount;
  final num? originalFare;
  final num? deduction;
  final String? policyBand;
  final String status;

  const Refund({
    required this.refundCode,
    required this.amount,
    this.originalFare,
    this.deduction,
    this.policyBand,
    this.status = 'Pending',
  });

  factory Refund.fromJson(Map<String, dynamic> j) => Refund(
        refundCode: j['refundCode'] as String? ?? '',
        amount: j['amount'] as num? ?? 0,
        originalFare: j['originalFare'] as num?,
        deduction: j['deduction'] as num?,
        policyBand: j['policyBand'] as String?,
        status: j['status'] as String? ?? 'Pending',
      );
}
