import 'package:flutter/material.dart';

import '../../model/InstrumentModel.dart';
import '../../theme/app_theme.dart';

/// A single instrument row shown inside the "Instruments" profile tab.
class InstrumentCard extends StatelessWidget {
  final InstrumentModel instrument;

  const InstrumentCard({super.key, required this.instrument});

  @override
  Widget build(BuildContext context) {
    final details = instrument.userInstrumentDetails;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: instrument.displayImageUrl != null
                ? Image.network(
                    instrument.displayImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, s) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.gold.withValues(alpha: 0.15),
                      child:
                          const Icon(Icons.music_note, color: AppColors.gold),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: AppColors.gold.withValues(alpha: 0.15),
                    child: const Icon(Icons.music_note, color: AppColors.gold),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Roland SPD-20" (brand + model)
                Text(instrument.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                // "Octapad" (instrument type)
                if (instrument.typeName.isNotEmpty)
                  Text(instrument.typeName,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12)),
                if (details?.proficiencyLevel != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      details!.proficiencyLevel!,
                      style:
                          const TextStyle(fontSize: 10, color: AppColors.gold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
