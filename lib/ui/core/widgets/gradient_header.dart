import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      height: 82 + topInset,
      padding: EdgeInsets.only(top: topInset, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0, .86, 1],
          colors: [AppColors.brandBlue, AppColors.brandBlue, Color(0xFF2E6FB8)],
        ),
      ),
      child: Row(
        children: [
          ?leading,
          if (leading != null) const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
