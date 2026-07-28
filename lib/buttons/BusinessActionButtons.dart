import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/BusinessModel.dart';
import '../../service/BusinessService.dart';
import '../../theme/app_theme.dart';

class BusinessActionButtons extends StatefulWidget {
  final BusinessModel business;
  final ValueChanged<BusinessModel>? onBusinessUpdated;

  const BusinessActionButtons({
    super.key,
    required this.business,
    this.onBusinessUpdated,
  });

  @override
  State<BusinessActionButtons> createState() => _BusinessActionButtonsState();
}

class _BusinessActionButtonsState extends State<BusinessActionButtons> {
  bool _isFollowLoading = false;

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);
    final wasFollowing = widget.business.isFollowedByViewer;
    try {
      if (wasFollowing) {
        await BusinessService.unfollow(widget.business.id);
      } else {
        await BusinessService.follow(widget.business.id);
      }
      final updated = widget.business.copyWith(
        isFollowedByViewer: !wasFollowing,
        followerCount: widget.business.followerCount + (wasFollowing ? -1 : 1),
      );
      widget.onBusinessUpdated?.call(updated);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  Future<void> _message() async {
    // Simple starter message — swap for an actual compose dialog/screen if you have one
    try {
      final conversationId = await BusinessService.messageBusiness(
        widget.business.id,
        'Hi, I\'m interested in your ${widget.business.businessType.toLowerCase()}.',
      );
      if (!mounted) return;
      if (conversationId != null) {
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => ChatScreen(conversationId: conversationId),
        // ));
      }
      _showSnack('Message sent');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    }
  }

  Future<void> _call() async {
    final phone = widget.business.contactPhone;
    if (phone == null || phone.isEmpty) {
      _showSnack('No phone number listed for this business');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      _showSnack('Could not open dialer');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppFonts.body(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgSurfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing = widget.business.isFollowedByViewer;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isFollowLoading ? null : _toggleFollow,
            style: isFollowing
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgSurfaceElevated,
                  )
                : null,
            child: _isFollowLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isFollowing ? 'Following' : 'Follow'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _message,
            child: const Text('Message'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _call,
            child: const Text('Call'),
          ),
        ),
      ],
    );
  }
}
