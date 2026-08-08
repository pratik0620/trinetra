import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leading ??
              IconButton(
                icon: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () {},
              ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.0,
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Row(children: actions!)
          else
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
