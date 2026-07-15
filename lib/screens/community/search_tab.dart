import 'package:flutter/material.dart';

import '../../../model/UserModel.dart';
import '../../widgets/user_tile.dart';

class SearchTab extends StatefulWidget {
  final bool isSearching;
  final String? searchError;
  final List<UserModel> searchResults;
  final void Function(String query) onSearch;
  final void Function(int userId) onFollow;

  const SearchTab({
    super.key,
    required this.isSearching,
    required this.searchError,
    required this.searchResults,
    required this.onSearch,
    required this.onFollow,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              widget.onSearch(val);
              setState(() {}); // suffixIcon (clear button) refresh ke liye
            },
            decoration: InputDecoration(
              hintText: 'Search by username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.onSearch('');
                        setState(() {});
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
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildResults() {
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
        child: Text('Search for people to follow',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
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
