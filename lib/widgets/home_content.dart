import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar inside blue header
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Text(
                  'Search',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Icon(Icons.search,
                    color: AppColors.white.withOpacity(0.7), size: 22),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryDark,
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
                      color: Color(0xFFE3F2FD),
                      iconColor: Color(0xFF1565C0),
                    ),
                    _CategoryCard(
                      label: 'Sports\nFacility',
                      icon: Icons.sports_soccer_outlined,
                      color: Color(0xFFE8F5E9),
                      iconColor: Color(0xFF2E7D32),
                    ),
                    _CategoryCard(
                      label: 'Recruitments',
                      icon: Icons.work_outline,
                      color: Color(0xFFFFF3E0),
                      iconColor: Color(0xFFE65100),
                    ),
                    _CategoryCard(
                      label: 'Real Estate',
                      icon: Icons.home_outlined,
                      color: Color(0xFFF3E5F5),
                      iconColor: Color(0xFF6A1B9A),
                    ),
                    _CategoryCard(
                      label: 'Events',
                      icon: Icons.event_outlined,
                      color: Color(0xFFFFEBEE),
                      iconColor: Color(0xFFC62828),
                    ),
                    _CategoryCard(
                      label: 'Education',
                      icon: Icons.school_outlined,
                      color: Color(0xFFE0F7FA),
                      iconColor: Color(0xFF00695C),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Upcoming concerts
                const Text(
                  'Upcoming Concerts',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
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
          colors: [AppColors.primaryDark, AppColors.primaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
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
                color: Colors.white.withOpacity(0.05),
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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'City Music Festival\n2024',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'Dec 25 - Dec 31, 2024',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
  final Color color;
  final Color iconColor;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(
              color: iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
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

  static const _colors = [
    Color(0xFF7B1FA2),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFBF360C),
  ];

  @override
  Widget build(BuildContext context) {
    final d = _data[index];
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: _colors[index],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.music_note, color: Colors.white54, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d['title']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                d['date']!,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                d['venue']!,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
