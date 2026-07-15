import 'package:artist_in/screens/community/requests_tab.dart';
import 'package:artist_in/screens/community/search_tab.dart';
import 'package:flutter/material.dart';

import '../../model/UserModel.dart';
import '../../service/FollowUserService.dart';
import '../../service/HelperService.dart';
import '../../service/UserService.dart';
import '../../theme/app_theme.dart';
import 'discover_tab.dart';


class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadAllUsers();
    _loadFollowRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
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
      final results = await UserService.searchUsers(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
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
      final requests = await FollowUserservice.getPendingFollowRequests();
      setState(() {
        _followRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      setState(() => _isLoadingRequests = false);
    }
  }

  // ─── Accept/Reject ────────────────────────────────────
  Future<void> _acceptRequest(int requestId) async {
    try {
      await FollowUserservice.acceptFollowRequest(requestId);
      _showSnack('Request accepted!');
      _loadFollowRequests();
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      await FollowUserservice.rejectFollowRequest(requestId);
      _showSnack('Request rejected!');
      _loadFollowRequests();
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ─── Follow User ──────────────────────────────────────
  Future<void> _followUser(int userId) async {
    try {
      final status = await FollowUserservice.followUser(userId);

      final bool nowFollowing = status == 'FOLLOWING';
      final bool nowPending = status == 'REQUEST_PENDING';

      if (nowPending) {
        _showSnack('Follow request sent!');
      } else if (nowFollowing) {
        _showSnack('Followed!');
      }
      // ALREADY_FOLLOWING → no snack needed, just resync state below.

      setState(() {
        _allUsers = _allUsers.map((u) {
          if (u.id != userId) return u;
          return u.copyWith(
            isFollowing: nowFollowing || u.isFollowing,
            hasPendingFollowRequest: nowPending,
          );
        }).toList();
        _searchResults = _searchResults.map((u) {
          if (u.id != userId) return u;
          return u.copyWith(
            isFollowing: nowFollowing || u.isFollowing,
            hasPendingFollowRequest: nowPending,
          );
        }).toList();
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      _showSnack(e.toString(), isError: true);
    }
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
              Tab(text: 'Discover'),
              Tab(text: 'Search'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              DiscoverTab(
                isLoading: _isLoadingUsers,
                users: _allUsers,
                onRefresh: _loadAllUsers,
                onFollow: _followUser,
              ),
              SearchTab(
                isSearching: _isSearching,
                searchError: _searchError,
                searchResults: _searchResults,
                onSearch: _searchUsers,
                onFollow: _followUser,
              ),
              RequestsTab(
                isLoading: _isLoadingRequests,
                requests: _followRequests,
                onRefresh: _loadFollowRequests,
                onAccept: _acceptRequest,
                onReject: _rejectRequest,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
