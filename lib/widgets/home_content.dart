import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar inside dark header
        Container(
          color: AppColors.bgAppBar,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceElevated,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Text(
                  'Search',
                  style: AppFonts.body(
                    color: AppColors.textTertiary,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.search,
                    color: AppColors.textTertiary, size: 22),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner/Featured
                _FeaturedBanner(),
                const SizedBox(height: 20),

                // Categories title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: AppFonts.body(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'See all',
                      style: AppFonts.body(
                        fontSize: 13,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: const [
                    _CategoryCard(
                      label: 'Community\nServices',
                      icon: Icons.people_outline,
                      iconColor: Color(0xFF64B5F6),
                    ),
                    _CategoryCard(
                      label: 'Sports\nFacility',
                      icon: Icons.sports_soccer_outlined,
                      iconColor: Color(0xFF81C784),
                    ),
                    _CategoryCard(
                      label: 'Recruitments',
                      icon: Icons.work_outline,
                      iconColor: Color(0xFFFFB74D),
                    ),
                    _CategoryCard(
                      label: 'Real Estate',
                      icon: Icons.home_outlined,
                      iconColor: Color(0xFFBA68C8),
                    ),
                    _CategoryCard(
                      label: 'Events',
                      icon: Icons.event_outlined,
                      iconColor: Color(0xFFE57373),
                    ),
                    _CategoryCard(
                      label: 'Education',
                      icon: Icons.school_outlined,
                      iconColor: Color(0xFF4DB6AC),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Upcoming concerts
                Text(
                  'Upcoming Concerts',
                  style: AppFonts.body(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _ConcertCard(index: i),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgSurfaceElevated, Color(0xFF3A2E12)],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern — subtle gold glow instead of white circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.magenta,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'FEATURED',
                    style: AppFonts.body(
                      color: AppColors.textOnMagenta,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'City Music Festival\n2024',
                  style: AppFonts.heading(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ).copyWith(height: 1.3),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.goldLight, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Dec 25 - Dec 31, 2024',
                      style: AppFonts.body(
                          color: AppColors.textSecondary, fontSize: 12),
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

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.body(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ).copyWith(height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ConcertCard extends StatelessWidget {
  final int index;

  const _ConcertCard({required this.index});

  static const _data = [
    {'title': 'Rock Night', 'date': 'Dec 20', 'venue': 'City Arena'},
    {'title': 'Jazz Evening', 'date': 'Dec 22', 'venue': 'Music Hall'},
    {'title': 'Folk Fest', 'date': 'Dec 25', 'venue': 'Open Ground'},
    {'title': 'Classical', 'date': 'Dec 28', 'venue': 'Grand Theatre'},
  ];

  // Deep jewel tones instead of bright saturated ones — read as premium
  // accent tiles against the charcoal background rather than clashing
  // with the gold/magenta palette.
  static const _colors = [
    Color(0xFF4A2E6B),
    Color(0xFF1F3A5F),
    Color(0xFF1F4D3A),
    Color(0xFF6B3416),
  ];

  @override
  Widget build(BuildContext context) {
    final d = _data[index];
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: _colors[index],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.music_note,
              color: AppColors.goldLight.withOpacity(0.7), size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d['title']!,
                style: AppFonts.body(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                d['date']!,
                style:
                    AppFonts.body(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                d['venue']!,
                style:
                    AppFonts.body(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
