import 'package:flutter/material.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['Buy', 'Rent', 'Commercial', 'PG/Co-Living', 'Plots'];

  // Feminine light color palette
  static const Color _rosePrimary = Color(0xFFE91E8C);
  static const Color _roseSoft = Color(0xFFF48FB1);
  static const Color _lavender = Color(0xFFCE93D8);
  static const Color _peachLight = Color(0xFFFCE4EC);
  static const Color _lilacLight = Color(0xFFF3E5F5);
  static const Color _white = Colors.white;
  static const Color _textDark = Color(0xFF37003C);
  static const Color _textMid = Color(0xFF7B1FA2);
  static const Color _cardBg = Color(0xFFFFF0F6);
  static const Color _tabBg = Color(0xFFFCE4EC);
  static const Color _tabSelected = Color(0xFFE91E8C);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFCE4EC), // peach-pink
            Color(0xFFF3E5F5), // lilac
            Color(0xFFFFFFFF), // white
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs / circles for depth
          Positioned(
            top: -60,
            left: -60,
            child: _decorativeCircle(200, _roseSoft.withOpacity(0.18)),
          ),
          Positioned(
            top: 40,
            right: -40,
            child: _decorativeCircle(160, _lavender.withOpacity(0.20)),
          ),
          Positioned(
            bottom: -40,
            left: 80,
            child: _decorativeCircle(120, _roseSoft.withOpacity(0.12)),
          ),

          // Main content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 64 : 20,
              vertical: 48,
            ),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: _buildLeftContent()),
                      const SizedBox(width: 40),
                      Expanded(flex: 4, child: _buildIllustrationCard()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftContent(),
                      const SizedBox(height: 36),
                      _buildIllustrationCard(),
                    ],
                  ),
          ),

          // Bottom banner
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftContent() {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _roseSoft.withOpacity(0.18),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _roseSoft.withOpacity(0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: _rosePrimary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '8K+ listings added daily · 72K+ verified',
                    style: TextStyle(
                      color: _rosePrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Headline
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: _textDark,
                  letterSpacing: -0.5,
                ),
                children: [
                  const TextSpan(text: 'Your trusted place\nto '),
                  TextSpan(
                    text: 'find a home',
                    style: TextStyle(
                      color: _rosePrimary,
                      decoration: TextDecoration.underline,
                      decorationColor: _roseSoft,
                      decorationThickness: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Designed with women's safety & comfort in mind.\nDiscover spaces that feel truly yours.",
              style: TextStyle(
                fontSize: 15,
                color: _textMid.withOpacity(0.75),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),

            // Search card
            _buildSearchCard(),

            const SizedBox(height: 28),

            // Stats row
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _roseSoft.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: _tabBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) => _buildTab(i)),
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: _roseSoft, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: _textDark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search locality, landmark, project, or builder',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rosePrimary,
                    foregroundColor: _white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final bool selected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _tabSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _tabs[index],
          style: TextStyle(
            color: selected ? _white : _textMid,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {'icon': Icons.home_rounded, 'value': '72K+', 'label': 'Verified Homes'},
      {'icon': Icons.shield_rounded, 'value': '100%', 'label': 'Safe Listings'},
      {'icon': Icons.people_alt_rounded, 'value': '2M+', 'label': 'Happy Users'},
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stats.map((s) {
        return Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _peachLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s['icon'] as IconData, color: _rosePrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['value'] as String,
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      color: _textMid.withOpacity(0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIllustrationCard() {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF48FB1), Color(0xFFCE93D8)],
          ),
          boxShadow: [
            BoxShadow(
              color: _roseSoft.withOpacity(0.35),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative inner circle
            Positioned(
              top: -30,
              right: -30,
              child: _decorativeCircle(140, Colors.white.withOpacity(0.12)),
            ),
            Positioned(
              bottom: 20,
              left: -20,
              child: _decorativeCircle(80, Colors.white.withOpacity(0.10)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cottage_rounded, color: Colors.white, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Find your dream home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Safe · Verified · Trusted',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Feature chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _chip(Icons.verified_user_rounded, 'Women Friendly'),
                      _chip(Icons.location_on_rounded, 'Geotagged'),
                      _chip(Icons.star_rounded, 'Top Rated'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _textDark.withOpacity(0.90),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _rosePrimary.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFF48FB1), size: 16),
          const SizedBox(width: 8),
          const Text(
            'Are you a Property Owner?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Sell / Rent for FREE →',
              style: TextStyle(
                color: _roseSoft,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: _roseSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}