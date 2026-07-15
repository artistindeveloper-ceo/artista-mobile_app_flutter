import 'package:flutter/material.dart';

import '../../model/InstrumentModel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/showAddInstrumentSheet.dart';
import 'InstrumentCard.dart';

/// Studio background const — change here if the CDN path ever moves.
const String kStudioBackgroundUrl =
    'https://artistin-instruments-images.s3.ap-south-1.amazonaws.com/studio.jpg';

/// A "showcase" style header that puts the user's Primary and Secondary
/// instrument side-by-side directly on top of a real studio-desk photo
/// background — like a product shot with the instrument image large and
/// clean, and the name/label sitting underneath as plain typography
/// (no boxed card, no border, no pill badge, no gradient panel).
///
/// All data (image, name, type) is real, pulled from whatever
/// InstrumentsView/ProfileScreen already loaded from the API, so it stays
/// live/real-time with no separate fetch needed. Only the backdrop image
/// is a static asset (the studio photo); everything drawn on top of it is
/// live app data.
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
        // ── Studio backdrop — real photo, no box/border/gradient panel ──
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Real background image (network, cached by Flutter's
                // default ImageCache so it doesn't re-download on rebuild).
                Positioned.fill(
                  child: Image.network(
                    kStudioBackgroundUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.bgSurface,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (ctx, e, s) =>
                        Container(color: AppColors.bgSurface),
                  ),
                ),
                // Subtle dark scrim so white/gold captions stay readable
                // over a bright photo — not a box, just contrast.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                // Live content on top of the photo.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                              color: Colors.white,
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
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
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
                            const SizedBox(width: 20),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

/// No box, no border, no pill badge — just the instrument photo floating
/// on the studio backdrop, with name/label as clean captioned typography
/// underneath (matches the reference screenshot).
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BoxFit.contain (not cover, not a boxed tile) so the instrument
        // reads as a real object sitting on the desk, with a soft drop
        // shadow instead of a card outline.
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Ground shadow — a soft dark ellipse "under" the instrument
              // so it reads as resting on the desk instead of floating.
              Positioned(
                bottom: 4,
                child: FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: RadialGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Instrument photo, bottom-aligned so its base sits right
              // above the shadow — this is what actually fixes the
              // "floating" look instead of centering in the box.
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: (ins.displayImageUrl != null &&
                          ins.displayImageUrl!.isNotEmpty)
                      ? Image.network(
                          ins.displayImageUrl!,
                          fit: BoxFit.contain,
                          height: 130,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.gold,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          // TEMP DEBUG: shows *why* the image failed
                          // instead of silently falling back to an icon
                          // that blends into the dark backdrop. Remove
                          // once the real cause (bad URL / 403 / null
                          // field) is confirmed fixed.
                          errorBuilder: (ctx, error, s) {
                            debugPrint(
                                '[InstrumentShowcase] image load failed for '
                                '"${ins.displayName}" url=${ins.displayImageUrl} '
                                'error=$error');
                            return Container(
                              width: 100,
                              height: 100,
                              alignment: Alignment.center,
                              color: Colors.red.withValues(alpha: 0.15),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.broken_image_outlined,
                                      color: Colors.redAccent, size: 26),
                                  const SizedBox(height: 4),
                                  const Text('image failed',
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 9)),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          alignment: Alignment.center,
                          color: Colors.blueGrey.withValues(alpha: 0.15),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_note,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 32),
                              const SizedBox(height: 4),
                              const Text('no image url',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 9)),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Name + label styled like a caption under a product photo:
        // bold white name, gold label separated by a thin divider dot.
        Text(
          ins.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 3),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (ins.typeName.isNotEmpty) ...[
                TextSpan(
                  text: '  ·  ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
                TextSpan(
                  text: ins.typeName,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        if (details?.proficiencyLevel != null) ...[
          const SizedBox(height: 2),
          Text(
            details!.proficiencyLevel!,
            style: TextStyle(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ],
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
    return AspectRatio(
      aspectRatio: 1.1,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_outlined,
                size: 26, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
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
