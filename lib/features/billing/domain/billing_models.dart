import '../../../core/i18n/app_language.dart';

enum ProPlan {
  monthly('monthly', 49000),
  lifetime('lifetime', 99000);

  const ProPlan(this.value, this.amount);

  final String value;

  /// Price in VND; the server checks the paid amount against its own table.
  final int amount;

  String get label => switch (this) {
    ProPlan.monthly => tr('1 tháng', '1 month'),
    ProPlan.lifetime => tr('Trọn đời', 'Lifetime'),
  };

  String get price => formatVnd(amount);

  static ProPlan fromValue(String? value) =>
      value == 'monthly' ? ProPlan.monthly : ProPlan.lifetime;
}

/// `99000` → `99.000đ`.
String formatVnd(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$bufferđ';
}

enum ProRequestStatus { pending, approved, rejected, expired }

class ProUpgradeRequest {
  const ProUpgradeRequest({
    required this.id,
    required this.plan,
    required this.transferCode,
    required this.status,
    required this.createdAt,
    this.amount,
    this.adminNote,
  });

  final String id;
  final ProPlan plan;
  final String transferCode;
  final ProRequestStatus status;
  final DateTime createdAt;

  /// Amount set by the server for this checkout.
  final int? amount;
  final String? adminNote;

  int get amountDue => amount ?? plan.amount;
}

class BillingStatus {
  const BillingStatus({required this.isPro, this.proUntil, this.latestRequest});

  final bool isPro;

  /// Null for lifetime Pro.
  final DateTime? proUntil;
  final ProUpgradeRequest? latestRequest;

  bool get hasPendingRequest =>
      latestRequest?.status == ProRequestStatus.pending;
}

class BillingFailure implements Exception {
  const BillingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class BillingRepository {
  Future<BillingStatus> fetchStatus();

  /// Creates (or reuses) the checkout for [plan] with its transfer code.
  Future<ProUpgradeRequest> startCheckout(ProPlan plan);
}
