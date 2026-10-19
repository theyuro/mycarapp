import 'package:flutter/material.dart';

/// Abre o conteúdo como bottom sheet em celulares e como diálogo centralizado
/// em tablets, onde o bottom sheet ficaria preso no canto inferior da tela.
Future<T?> showResponsiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool showDragHandle = false,
  Color? backgroundColor,
}) {
  if (MediaQuery.sizeOf(context).shortestSide < 600) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: backgroundColor,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          // Sem a alça do bottom sheet, o conteúdo precisa de respiro no topo.
          padding: EdgeInsets.only(top: showDragHandle ? 20 : 0),
          child: builder(dialogContext),
        ),
      ),
    ),
  );
}
