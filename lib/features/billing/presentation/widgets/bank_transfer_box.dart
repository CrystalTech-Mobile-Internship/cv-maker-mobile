import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/env_constants.dart';

/// VietQR code for the configured receiving account, pre-filled with the
/// amount and transfer note. Shows a notice when no account is configured.
class BankTransferBox extends StatelessWidget {
  const BankTransferBox({
    super.key,
    required this.amount,
    required this.transferCode,
  });

  final int amount;
  final String transferCode;

  @override
  Widget build(BuildContext context) {
    final account = EnvConstants.paymentAccount;
    if (account == null) {
      return Container(
        key: const ValueKey('bank-transfer-unavailable'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.amberSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Thông tin chuyển khoản đang được cập nhật. Vui lòng quay lại sau.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final qrUrl = Uri.https(
      'img.vietqr.io',
      '/image/${account.bankId}-${account.accountNumber}-compact2.png',
      {
        'amount': '$amount',
        'addInfo': transferCode,
        'accountName': account.accountName,
      },
    ).toString();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            qrUrl,
            key: const ValueKey('bank-transfer-qr'),
            width: 220,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 220,
              height: 80,
              child: Center(child: Text('Không tải được mã QR.')),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${account.bankId} • ${account.accountNumber}\n${account.accountName}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
        ),
      ],
    );
  }
}
