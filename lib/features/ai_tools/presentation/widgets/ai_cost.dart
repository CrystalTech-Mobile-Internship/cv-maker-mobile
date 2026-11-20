import '../../../../core/i18n/app_language.dart';

/// "3 lượt AI" / "3 AI uses": the price of an AI action, shown on its
/// button so nobody spends uses by surprise.
String aiCostText(int uses) =>
    tr('$uses lượt AI', uses == 1 ? '1 AI use' : '$uses AI uses');

/// Button label with its AI price, e.g. "Viết lại · 1 lượt AI".
String withAiCost(String label, int uses) => '$label · ${aiCostText(uses)}';
