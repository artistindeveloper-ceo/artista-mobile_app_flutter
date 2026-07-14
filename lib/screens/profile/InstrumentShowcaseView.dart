import 'package:flutter/material.dart';

import '../../model/InstrumentModel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/showAddInstrumentSheet.dart';
import 'InstrumentCard.dart';


/// A "showcase" style header that puts the user's Primary and Secondary
/// instrument side-by-side as product cards over a dark gradient backdrop —
/// instead of a plain stacked list. All data (image, name, type) is real,
/// pulled from whatever InstrumentsView/ProfileScreen already loaded from
/// the API, so it stays live/real-time with no separate fetch needed.
///
/// Any instruments beyond the featured Primary/Secondary pair are still
/// rendered below as a normal list (via InstrumentCard), so nothing is lost.
class InstrumentShowcaseView extends StatelessWidget {
  final List<InstrumentModel> instruments;
  final bool isLoading;
  final bool isOwnProfile;
  final VoidCallback onInstrumentAdded;

  const InstrumentShowcaseView({
    super.key,
    required this.instruments,
    required this.isLoading,
    required this.isOwnProfile,
    required this.onInstrumentAdded,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (instruments.isEmpty) {
      return _EmptyState(isOwnProfile: isOwnProfile, onAdd: onInstrumentAdded);
    }

    final InstrumentModel? primary =
        instruments.where((i) => i.isPrimary).isNotEmpty
            ? instruments.firstWhere((i) => i.isPrimary)
            : null;

    final secondaryList = instruments.where((i) => !i.isPrimary).toList();
    final InstrumentModel? featuredSecondary =
        secondaryList.isNotEmpty ? secondaryList.first : null;
    final extras = secondaryList.length > 1 ? secondaryList.sublist(1) : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Showcase backdrop ──
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgSurfaceElevated,
                AppColors.bgSurface,
                AppColors.bgBase,
              ],
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Gear',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isOwnProfile)
                    TextButton.icon(
                      onPressed: () => showAddInstrumentSheet(
                        context,
                        onAdded: onInstrumentAdded,
                      ),
                      icon: const Icon(Icons.add,
                          size: 16, color: AppColors.gold),
                      label: const Text('Add',
                          style: TextStyle(color: AppColors.gold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ShowcaseCard(
                      instrument: primary,
                      label: 'Primary Instrument',
                      isOwnProfile: isOwnProfile,
                      onAdd: onInstrumentAdded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShowcaseCard(
                      instrument: featuredSecondary,
                      label: 'Secondary Instrument',
                      isOwnProfile: isOwnProfile,
                      onAdd: onInstrumentAdded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Any additional instruments beyond the featured pair ──
        if (extras.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('More Instruments',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ...extras.map((ins) => InstrumentCard(instrument: ins)),
                const SizedBox(height: 12),
              ],
            ),
          ),
      ],
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final InstrumentModel? instrument;
  final String label;
  final bool isOwnProfile;
  final VoidCallback onAdd;

  const _ShowcaseCard({
    required this.instrument,
    required this.label,
    required this.isOwnProfile,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (instrument == null) {
      return _EmptySlot(
        label: label,
        isOwnProfile: isOwnProfile,
        onAdd: onAdd,
      );
    }

    final ins = instrument!;
    final details = ins.userInstrumentDetails;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1.4,
              child: ins.displayImageUrl != null
                  ? Image.network(
                      ins.displayImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, s) => Container(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        child: const Icon(Icons.music_note,
                            color: AppColors.gold, size: 32),
                      ),
                    )
                  : Container(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      child: const Icon(Icons.music_note,
                          color: AppColors.gold, size: 32),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ins.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary),
          ),
          if (ins.typeName.isNotEmpty)
            Text(
              ins.typeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.gold),
            ),
          ),
          if (details?.proficiencyLevel != null) ...[
            const SizedBox(height: 4),
            Text(
              details!.proficiencyLevel!,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String label;
  final bool isOwnProfile;
  final VoidCallback onAdd;

  const _EmptySlot({
    required this.label,
    required this.isOwnProfile,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.music_off_outlined,
              size: 26, color: AppColors.textGrey),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
          if (isOwnProfile) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => showAddInstrumentSheet(context, onAdded: onAdd),
              child: const Text('+ Add',
                  style: TextStyle(color: AppColors.gold, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isOwnProfile;
  final VoidCallback onAdd;

  const _EmptyState({required this.isOwnProfile, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off_outlined,
                size: 40, color: AppColors.textGrey),
            const SizedBox(height: 10),
            const Text('No instruments added yet',
                style: TextStyle(color: AppColors.textGrey)),
            if (isOwnProfile) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    showAddInstrumentSheet(context, onAdded: onAdd),
                icon: const Icon(Icons.add, size: 16, color: AppColors.gold),
                label: const Text('Add Instrument',
                    style: TextStyle(color: AppColors.gold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
