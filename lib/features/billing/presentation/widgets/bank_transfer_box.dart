import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/env_constants.dart';
import '../../../../core/i18n/app_language.dart';
import '../../domain/billing_models.dart';

/// SePay QR code plus the transfer details, each with a copy button.
/// The QR fills in the amount and note so people only need to confirm.
class BankTransferBox extends StatelessWidget {
  const BankTransferBox({
    super.key,
    required this.amount,
    required this.transferCode,
  });

  final int amount;
  final String transferCode;

  /// SePay's QR image for the receiving account.
  static String qrUrl(PaymentAccount account, int amount, String code) =>
      Uri.https('qr.sepay.vn', '/img', {
        'acc': account.accountNumber,
        'bank': account.bankId,
        'amount': '$amount',
        'des': code,
        'template': 'compact',
      }).toString();

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
        child: Text(
          tr(
            'Thanh toán đang tạm dừng. Vui lòng quay lại sau.',
            'Payment is paused for now. Please come back later.',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final qr = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        qrUrl(account, amount, transferCode),
        key: const ValueKey('bank-transfer-qr'),
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: Text(
              tr('Không tải được mã QR.', 'Could not load the QR code.'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(label: tr('Ngân hàng', 'Bank'), value: account.bankId),
        _DetailRow(
          label: tr('Số tài khoản', 'Account number'),
          value: account.accountNumber,
          copyable: true,
        ),
        _DetailRow(
          label: tr('Chủ tài khoản', 'Account name'),
          value: account.accountName,
        ),
        _DetailRow(
          label: tr('Số tiền', 'Amount'),
          value: formatVnd(amount),
          copyValue: '$amount',
          copyable: true,
          strong: true,
        ),
        _DetailRow(
          key: const ValueKey('pro-transfer-code'),
          label: tr('Nội dung', 'Transfer note'),
          value: transferCode,
          copyable: true,
          strong: true,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [qr, const SizedBox(height: 14), details]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            qr,
            const SizedBox(width: 20),
            Expanded(child: details),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.copyValue,
    this.copyable = false,
    this.strong = false,
  });

  final String label;
  final String value;
  final String? copyValue;
  final bool copyable;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.softBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              tooltip: tr('Sao chép', 'Copy'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 17),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copyValue ?? value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('Đã sao chép.', 'Copied.')),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
