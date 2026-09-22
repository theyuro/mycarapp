import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64, this.showBorder = true});

  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final decodedSize = (size * MediaQuery.devicePixelRatioOf(context)).ceil();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .24),
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: .22))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .35),
            blurRadius: size * .24,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/mycarapp_icon.png',
        fit: BoxFit.cover,
        cacheWidth: decodedSize,
        cacheHeight: decodedSize,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
