import 'package:flutter/material.dart';
import '../model/UserModel.dart';
import '../service/ApiService.dart';
import '../service/UserService.dart';
import '../theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  // Discover
  List<UserModel> _allUsers = [];
  bool _isLoadingUsers = true;

  // Search
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  // Follow Requests
  List<dynamic> _followRequests = [];
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ← 3 tabs
    _loadAllUsers();
    _loadFollowRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Load All Users ───────────────────────────────────
  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await UserService.getAllUsers();
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  // ─── Search Users ─────────────────────────────────────
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final results = await ApiService.searchUsers(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
      });
    }
  }

  // ─── Load Follow Requests ─────────────────────────────
  Future<void> _loadFollowRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final requests = await ApiService.getPendingFollowRequests();
      setState(() {
        _followRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() => _isLoadingRequests = false);
    }
  }

  // ─── Accept/Reject ────────────────────────────────────
  Future<void> _acceptRequest(int requestId) async {
    try {
      await ApiService.acceptFollowRequest(requestId);
      _showSnack('Request accepted!');
      _loadFollowRequests();
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      await ApiService.rejectFollowRequest(requestId);
      _showSnack('Request rejected!');
      _loadFollowRequests();
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primaryDark,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Discover'),       // ← New tab
              Tab(text: 'Search'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDiscoverTab(),
              _buildSearchTab(),
              _buildRequestsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Discover Tab ─────────────────────────────────────
  Widget _buildDiscoverTab() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allUsers.isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _allUsers.length,
        itemBuilder: (ctx, i) {
          final user = _allUsers[i];
          return _UserTile(
            user: user,
            onFollow: () => _followUser(user.id),
          );
        },
      ),
    );
  }

  // ─── Search Tab ───────────────────────────────────────
  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => _searchUsers(val),
            decoration: InputDecoration(
              hintText: 'Search by username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchResults = []);
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchError != null
              ? Center(child: Text(_searchError!,
              style: const TextStyle(color: Colors.grey)))
              : _searchResults.isEmpty
              ? const Center(
            child: Text('Search for people to follow',
                style: TextStyle(color: Colors.grey)),
          )
              : ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (ctx, i) {
              final user = _searchResults[i];
              return _UserTile(
                user: user,
                onFollow: () => _followUser(user.id),
              );
            },
          ),
        ),
      ],
    );
  }
// ─── Follow User ──────────────────────────────────────
  Future<void> _followUser(int userId) async {
    try {
      await ApiService.followUser(userId);
      _showSnack('Followed!');

      // ✅ Update only that user's isFollowing — no full reload
      setState(() {
        _allUsers = _allUsers.map((u) {
          return u.id == userId ? u.copyWith(isFollowing: true) : u;
        }).toList();
        _searchResults = _searchResults.map((u) {
          return u.id == userId ? u.copyWith(isFollowing: true) : u;
        }).toList();
      });
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }
  // ─── Requests Tab ─────────────────────────────────────
  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_followRequests.isEmpty) {
      return const Center(
        child: Text('No pending follow requests',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFollowRequests,
      child: ListView.builder(
        itemCount: _followRequests.length,
        itemBuilder: (ctx, i) {
          final req = _followRequests[i];
          final requestId = req['id'] ?? req['requestId'];
          final username = req['username'] ??
              req['requester']?['username'] ?? 'Unknown';
          final avatarUrl = req['avatarUrl'] ??
              req['requester']?['avatarUrl'];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white))
                  : null,
            ),
            title: Text(username,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Wants to follow you'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: Colors.green, size: 28),
                  onPressed: () => _acceptRequest(requestId),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel,
                      color: Colors.red, size: 28),
                  onPressed: () => _rejectRequest(requestId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onFollow;

  const _UserTile({required this.user, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white))
            : null,
      ),
      title: Text(user.name,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: user.username != null
          ? Text('@${user.username}',
          style: const TextStyle(color: Colors.grey))
          : null,
      trailing: user.isFollowing
      // ✅ Already following — grey outlined button
          ? OutlinedButton(
        onPressed: null, // disabled
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(90, 32),
        ),
        child: const Text('Following', style: TextStyle(fontSize: 12)),
      )
      // Not following — solid blue button
          : ElevatedButton(
        onPressed: onFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(80, 32),
        ),
        child: const Text('Follow', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
