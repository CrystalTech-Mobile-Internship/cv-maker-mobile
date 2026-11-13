import 'package:flutter/material.dart';

/// Width from which sheets open as centred dialogs instead of sliding up
/// from the bottom.
const double appSheetDialogBreakpoint = 900;

/// Tells sheet content whether it is shown as a centred dialog (computers)
/// or as a bottom sheet (phones), e.g. to hide the drag handle.
class AppSheetScope extends InheritedWidget {
  const AppSheetScope({
    super.key,
    required this.isDialog,
    required super.child,
  });

  final bool isDialog;

  static bool isDialogOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSheetScope>()?.isDialog ??
      false;

  @override
  bool updateShouldNotify(AppSheetScope oldWidget) =>
      oldWidget.isDialog != isDialog;
}

/// Shows [builder] as a bottom sheet on phones and as a centred dialog on
/// computers, so the same content fits both.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = false,
  Color? backgroundColor,
}) {
  final size = MediaQuery.sizeOf(context);
  if (size.width < appSheetDialogBreakpoint) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor,
      builder: (sheetContext) =>
          AppSheetScope(isDialog: false, child: builder(sheetContext)),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
        ),
        child: AppSheetScope(
          isDialog: true,
          // Sheet content assumes a bottom-sheet surface; keep its own
          // rounded white panels from showing a second frame.
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: builder(dialogContext),
          ),
        ),
      ),
    ),
  );
}

/// The small grab bar shown at the top of bottom sheets; hidden when the
/// sheet is shown as a dialog.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (AppSheetScope.isDialogOf(context)) return const SizedBox(height: 8);
    return Center(
      child: Container(
        margin: margin ?? const EdgeInsets.only(top: 10, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
