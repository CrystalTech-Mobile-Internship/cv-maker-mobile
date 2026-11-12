enum ProPlan {
  monthly('monthly', 'Theo tháng', '49.000đ'),
  lifetime('lifetime', 'Trọn đời', '99.000đ');

  const ProPlan(this.value, this.label, this.price);

  final String value;
  final String label;
  final String price;

  static ProPlan fromValue(String? value) =>
      value == 'monthly' ? ProPlan.monthly : ProPlan.lifetime;
}

enum ProRequestStatus { pending, approved, rejected }

class ProUpgradeRequest {
  const ProUpgradeRequest({
    required this.id,
    required this.plan,
    required this.transferCode,
    required this.status,
    required this.createdAt,
    this.adminNote,
  });

  final String id;
  final ProPlan plan;
  final String transferCode;
  final ProRequestStatus status;
  final DateTime createdAt;
  final String? adminNote;
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

/// Bank transfer reference tied to the account so the administrator can
/// match the payment, e.g. `CVPRO-LIFETIME-1A2B3C4D`.
String proTransferCode(String userId, ProPlan plan) {
  final compact = userId.replaceAll('-', '').toUpperCase();
  final suffix = compact.length >= 8 ? compact.substring(0, 8) : compact;
  return 'CVPRO-${plan.value.toUpperCase()}-$suffix';
}

class BillingFailure implements Exception {
  const BillingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class BillingRepository {
  Future<BillingStatus> fetchStatus();

  Future<ProUpgradeRequest> submitRequest(ProPlan plan);
}
