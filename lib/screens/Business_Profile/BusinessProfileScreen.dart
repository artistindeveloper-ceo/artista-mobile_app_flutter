import 'package:flutter/material.dart';

import '../../Exception/ApiException.dart';
import '../../config/Session.dart';
import '../../model/BusinessModel.dart';
import '../../model/PostModel.dart';
import '../../service/BusinessService.dart';
import '../../service/FollowUserService.dart';
import '../../service/PostService.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';
import 'EditBusinessProfileScreen.dart';
import '../auth/login_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  final int businessId;

  // Jab ye screen bottom-nav "Profile" tab ke andar dikhayi jaati hai
  // (HomeScreen._buildBody se, push nahi hua), to back button dikhana
  // galat hai — pop karne layak koi route hota hi nahi, aur
  // Navigator.pop() poore HomeScreen ko pop kar deta hai -> black screen.
  // Jab ye screen kisi doosre business ka profile dekhne ke liye push
  // karke khola jaata hai (search/list se), to showBackButton true
  // (default) rakhein.
  final bool showBackButton;

  const BusinessProfileScreen({
    super.key,
    required this.businessId,
    this.showBackButton = true,
  });

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen>
    with SingleTickerProviderStateMixin {
  BusinessModel? _business;
  bool _isLoading = true;
  String? _error;
  bool _isFollowActionInProgress = false;
  late TabController _tabController;

  // ── Posts state ──
  List<PostModel> _posts = [];
  bool _isPostsLoading = true;
  String? _postsError;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navyDark = AppColors.bgBase;
  static const _navyCard = AppColors.bgSurface;
  static const _orange = AppColors.gold;

  bool get _isOwnBusiness => Session().userId == widget.businessId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBusiness();
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final business = await BusinessService.getById(widget.businessId);
      setState(() => _business = business);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isPostsLoading = true;
      _postsError = null;
    });
    try {
      final posts = await PostService.getUserPosts(widget.businessId);
      setState(() => _posts = posts);
    } on ApiException catch (e) {
      setState(() => _postsError = e.message);
    } catch (e) {
      setState(() => _postsError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isPostsLoading = false);
    }
  }

  // ✅ FOLLOW/UNFOLLOW — ab FollowUserservice use karta hai (users table
  // wala endpoint), kyunki business ka id hi user.id hai. Response se
  // seedha backend ka canonical followersCount leta hai — koi manual
  // +1/-1 nahi.
  Future<void> _toggleFollow() async {
    final business = _business;
    if (business == null || _isFollowActionInProgress) return;

    setState(() => _isFollowActionInProgress = true);
    try {
      final FollowActionResult result;
      if (business.isFollowedByViewer) {
        result = await FollowUserservice.unfollowUser(widget.businessId);
      } else {
        result = await FollowUserservice.followUser(widget.businessId);
      }
      setState(() {
        _business = business.copyWith(
          isFollowedByViewer: result.following,
          followerCount: result.followersCount,
        );
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isFollowActionInProgress = false);
    }
  }

  // ✅ MESSAGE — ab seedha chat screen khulega, koi text popup nahi.
  // Agar aapke BusinessService me "getOrCreateConversation" jaisa
  // dedicated endpoint hai (bina message bheje), to use ka use karo —
  // zyada clean rahega. Filhal messageBusiness(id, '') call kar rahe
  // hain; agar backend empty content accept nahi karta to us endpoint
  // ko update karna padega.
  Future<void> _openMessageDialog() async {
    final business = _business;
    if (business == null) return;

    try {
      final result =
          await BusinessService.messageBusiness(widget.businessId, '');
      if (result == null || !mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: result['conversationId'],
            otherUserId: result['otherUserId'],
            username: business.name,
            avatarUrl: business.profilePhotoUrl,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  // ✅ INQUIRY — text box khulega jaha user apna sawaal type kar sakta
  // hai, phir woh message business ko bhej ke chat khol dega.
  Future<void> _openInquiryDialog() async {
    final business = _business;
    if (business == null) return;

    final controller = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _navyCard,
        title: Text('Inquiry to ${business.name}',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Type your inquiry...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (content == null || content.isEmpty) return;

    try {
      final result =
          await BusinessService.messageBusiness(widget.businessId, content);
      if (result == null || !mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: result['conversationId'],
            otherUserId: result['otherUserId'],
            username: business.name,
            avatarUrl: business.profilePhotoUrl,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _call() async {
    final phone = _business?.contactPhone;
    if (phone == null) return;
    // launchUrl(Uri.parse('tel:$phone')); // url_launcher package chahiye
  }

  void _openEditBusiness() async {
    final business = _business;
    if (business == null) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditBusinessProfileScreen(business: business),
      ),
    );
    if (saved == true) {
      _loadBusiness();
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _navyCard,
        title: const Text('Log out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: _orange)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Session().clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildDrawer() {
    final business = _business;
    return Drawer(
      backgroundColor: _navyDark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _navyCard, width: 1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _navyCard,
                    backgroundImage: business?.profilePhotoUrl != null
                        ? NetworkImage(business!.profilePhotoUrl!)
                        : null,
                    child: business?.profilePhotoUrl == null
                        ? const Icon(Icons.storefront,
                            color: Colors.white38, size: 26)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      business?.name ?? 'Business',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.storefront_outlined,
              label: 'Business Profile',
              onTap: () => Navigator.pop(context),
              selected: true,
            ),
            if (_isOwnBusiness)
              _drawerItem(
                icon: Icons.edit_outlined,
                label: 'Edit Business Profile',
                onTap: () {
                  Navigator.pop(context);
                  _openEditBusiness();
                },
              ),
            _drawerItem(
              icon: Icons.receipt_long_outlined,
              label: 'Bookings',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              icon: Icons.insights_outlined,
              label: 'Analytics',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(color: _navyCard, height: 1),
            _drawerItem(
              icon: Icons.logout,
              label: 'Log out',
              iconColor: _orange,
              textColor: _orange,
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Color iconColor = Colors.white70,
    Color textColor = Colors.white,
  }) {
    return Material(
      color: selected ? _navyCard : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: selected ? _orange : iconColor),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _navyDark,
      endDrawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadBusiness, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final business = _business!;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          backgroundColor: _navyDark,
          pinned: true,
          elevation: 0,
          // ✅ Ye screen do jagah use hoti hai:
          //  1) HomeScreen ke bottom-nav "Profile" tab me — direct body
          //     swap hota hai, push nahi. Waha back icon dikhana galat
          //     hai kyunki Navigator.pop poore HomeScreen ko pop kar
          //     deta hai -> black screen.
          //  2) Kisi doosre business ka profile dekhne ke liye push
          //     karke khola jaata hai — waha back icon chahiye.
          automaticallyImplyLeading: widget.showBackButton,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(business.name,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(
                height: 130,
                width: double.infinity,
                child: business.coverPhotoUrl != null
                    ? Image.network(business.coverPhotoUrl!, fit: BoxFit.cover)
                    : Container(color: _navyCard),
              ),
              Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 37,
                        backgroundColor: _navyCard,
                        backgroundImage: business.profilePhotoUrl != null
                            ? NetworkImage(business.profilePhotoUrl!)
                            : null,
                        child: business.coverPhotoUrl == null
                            ? Icon(Icons.storefront,
                                color: _orange.withValues(alpha: 0.8), size: 32)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          business.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        if (business.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: _orange, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (business.cityName != null) ...[
                          const Icon(Icons.location_on,
                              color: Colors.white54, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            business.countryName != null
                                ? '${business.cityName}, ${business.countryName}'
                                : business.cityName!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    if (business.contactPhone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone,
                              color: Colors.white54, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            business.contactPhone!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    Text(
                      business.businessType,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isOwnBusiness
                          ? SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _openEditBusiness,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _orange,
                                  side: const BorderSide(color: _orange),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Edit Business Profile'),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          business.isFollowedByViewer
                                              ? Colors.white24
                                              : _orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Text(business.isFollowedByViewer
                                        ? 'Following'
                                        : 'Follow'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton(
                                    onPressed: _openMessageDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white24),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Message'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton(
                                    onPressed: _openInquiryDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white24),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Inquiry'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (business.avgRating != null) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            '${business.avgRating!.toStringAsFixed(1)} (${business.ratingCount ?? 0} Reviews)',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(width: 18),
                        ],
                        Text(
                          '${_formatCount(business.followerCount)} Followers',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 18),
                        Text(
                          '${_formatCount(business.followingCount)} Following',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (business.description != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          business.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              indicatorColor: _orange,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Products'),
                Tab(text: 'Classes'),
                Tab(text: 'Reviews'),
              ],
            ),
            backgroundColor: _navyDark,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildProductsTab(),
          _buildPlaceholderTab('No classes yet'),
          _buildPlaceholderTab('No reviews yet'),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  Widget _buildPostsTab() {
    if (_isPostsLoading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }
    if (_postsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_postsError!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadPosts, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Text('No posts yet', style: TextStyle(color: Colors.white38)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _posts.length,
      itemBuilder: (ctx, i) {
        final post = _posts[i];
        return Stack(
          fit: StackFit.expand,
          children: [
            post.imageUrl != null
                ? Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: _navyCard),
                  )
                : Container(color: _navyCard),
            if (post.isVideo)
              const Positioned(
                top: 6,
                right: 6,
                child:
                    Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (ctx, i) => Card(
        color: _navyCard,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          title:
              const Text('Product name', style: TextStyle(color: Colors.white)),
          subtitle:
              const Text('₹0.00', style: TextStyle(color: Colors.white54)),
          trailing: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            child: const Text('Add to Cart'),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.white38)),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
