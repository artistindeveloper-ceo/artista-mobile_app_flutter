import 'package:flutter/material.dart';

import '../../../model/UserModel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_tile.dart';

class DiscoverTab extends StatefulWidget {
  final bool isLoading;
  final List<UserModel> users;
  final Future<void> Function() onRefresh;
  final void Function(int userId) onFollow;

  // ── Search (moved in from the old standalone Search tab) ──
  final bool isSearching;
  final String? searchError;
  final List<UserModel> searchResults;
  final void Function(String query) onSearch;

  const DiscoverTab({
    super.key,
    required this.isLoading,
    required this.users,
    required this.onRefresh,
    required this.onFollow,
    required this.isSearching,
    required this.searchError,
    required this.searchResults,
    required this.onSearch,
  });

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value.trim());
    widget.onSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearchMode = _query.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onChanged,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: const TextStyle(color: AppColors.textGrey),
              prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textGrey),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.bgSurfaceElevated,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: isSearchMode ? _buildSearchResults() : _buildDiscoverList(),
        ),
      ],
    );
  }

  Widget _buildDiscoverList() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.users.isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.users.length,
        itemBuilder: (ctx, i) {
          final user = widget.users[i];
          return UserTile(
            user: user,
            onFollow: () => widget.onFollow(user.id),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (widget.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.searchError != null) {
      return Center(
        child: Text(widget.searchError!,
            style: const TextStyle(color: Colors.grey)),
      );
    }
    if (widget.searchResults.isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.searchResults.length,
      itemBuilder: (ctx, i) {
        final user = widget.searchResults[i];
        return UserTile(
          user: user,
          onFollow: () => widget.onFollow(user.id),
        );
      },
    );
  }
}
