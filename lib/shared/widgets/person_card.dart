import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';

class PersonCard extends StatelessWidget {
  final NetworkContact contact;

  const PersonCard({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    if (contact.sosActive) {
      return Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: AppColors.secondaryContainer, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryContainer.withOpacity(0.2),
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.sos_rounded,
                        color: AppColors.secondaryContainer,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'SOS Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: contact.isSafe ? AppColors.tertiary : AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceContainer,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      contact.isSafe
                          ? Icons.shield_rounded
                          : Icons.warning_rounded,
                      color: contact.isSafe
                          ? AppColors.tertiary
                          : AppColors.warning,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      contact.isSafe ? 'Safe' : 'Verifying',
                      style: TextStyle(
                        fontSize: 12,
                        color: contact.isSafe
                            ? AppColors.tertiary
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
