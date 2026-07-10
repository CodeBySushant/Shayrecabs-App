import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/booking_model.dart';

/// Razorpay order returned by POST /payments/create-order.
class PaymentOrder {
  final String orderId;
  final int amount; // paise
  final String currency;
  final String keyId;
  const PaymentOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> j) => PaymentOrder(
        orderId: j['order_id'] as String,
        amount: (j['amount'] as num).toInt(),
        currency: j['currency'] as String? ?? 'INR',
        keyId: j['key_id'] as String? ?? '',
      );
}

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  /// POST /bookings — creates a pending booking; fare computed server-side.
  Future<Booking> create({
    required String rideId,
    String? terminal,
    String? flightNumber,
    String? airline,
    String? pickupHotspot,
    required int passengers, // sharing type: 2 or 3
    String? dropHotspot,
    bool womenOnly = false,
  }) async {
    final res = await _api.post('/bookings', auth: true, body: {
      'rideId': rideId,
      if (terminal != null) 'terminal': terminal,
      if (flightNumber != null && flightNumber.isNotEmpty)
        'flightNumber': flightNumber,
      if (airline != null && airline.isNotEmpty) 'airline': airline,
      if (pickupHotspot != null) 'pickupHotspot': pickupHotspot,
      'passengers': passengers,
      if (dropHotspot != null) 'dropHotspot': dropHotspot,
      'womenOnly': womenOnly,
    });
    return Booking.fromJson(res['booking'] as Map<String, dynamic>);
  }

  Future<List<Booking>> listMine() async {
    final res = await _api.get('/bookings', auth: true);
    return (res['bookings'] as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /bookings/:id/cancel — releases seats; paid bookings get a Refund
  /// per policy (>24h ₹200 flat · 12–24h 50% · <12h none).
  Future<Refund?> cancel(String bookingId) async {
    final res = await _api.post('/bookings/$bookingId/cancel',
        body: const {}, auth: true);
    return res['refund'] is Map<String, dynamic>
        ? Refund.fromJson(res['refund'] as Map<String, dynamic>)
        : null;
  }

  Future<Booking> rate(String bookingId,
      {required int rating, String? feedback}) async {
    final res = await _api.post('/bookings/$bookingId/rate', auth: true, body: {
      'rating': rating,
      if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
    });
    return Booking.fromJson(res['booking'] as Map<String, dynamic>);
  }

  // ── Payments (Razorpay Standard Checkout, same backend endpoints) ──

  Future<PaymentOrder> createOrder(String bookingId) async {
    final res = await _api.post('/payments/create-order',
        body: {'bookingId': bookingId}, auth: true);
    return PaymentOrder.fromJson(res);
  }

  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String? bookingId,
  }) =>
      _api.post('/payments/verify', auth: true, body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        if (bookingId != null) 'bookingId': bookingId,
      });
}

final bookingRepositoryProvider =
    Provider((ref) => BookingRepository(ApiClient.instance));

final myBookingsProvider = FutureProvider<List<Booking>>(
    (ref) => ref.watch(bookingRepositoryProvider).listMine());
