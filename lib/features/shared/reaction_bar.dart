import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/reaction_service.dart';

class ReactionBar extends StatefulWidget {
  final String couponId;
  const ReactionBar({super.key, required this.couponId});

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  ReactionCounts? _counts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.couponId.isEmpty) return;
    try {
      final counts = await ReactionService.instance.getReactions(widget.couponId);
      if (mounted) setState(() { _counts = counts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _tap(String type) async {
    if (widget.couponId.isEmpty) return;
    final prev = _counts;
    final wasReaction = prev?.userReaction;
    int likes = prev?.likes ?? 0;
    int dislikes = prev?.dislikes ?? 0;
    String? newReaction = type;

    if (wasReaction == type) {
      if (type == 'like') likes--;
      if (type == 'dislike') dislikes--;
      newReaction = null;
    } else {
      if (wasReaction == 'like') likes--;
      if (wasReaction == 'dislike') dislikes--;
      if (type == 'like') likes++;
      if (type == 'dislike') dislikes++;
    }

    setState(() {
      _counts = ReactionCounts(likes: likes, dislikes: dislikes, userReaction: newReaction);
    });

    try {
      await ReactionService.instance.setReaction(widget.couponId, type);
    } catch (_) {
      if (mounted) setState(() => _counts = prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final counts = _counts ?? ReactionCounts(likes: 0, dislikes: 0, userReaction: null);
    final isLiked = counts.userReaction == 'like';
    final isDisliked = counts.userReaction == 'dislike';

    return Row(
      children: [
        GestureDetector(
          onTap: () => _tap('like'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isLiked ? AppColors.green.withOpacity(0.12) : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isLiked ? AppColors.green : AppColors.border, width: isLiked ? 1.2 : 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                  size: 16,
                  color: isLiked ? AppColors.green : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${counts.likes}',
                  style: TextStyle(
                    color: isLiked ? AppColors.green : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _tap('dislike'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDisliked ? AppColors.red.withOpacity(0.12) : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDisliked ? AppColors.red : AppColors.border, width: isDisliked ? 1.2 : 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                  size: 16,
                  color: isDisliked ? AppColors.red : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${counts.dislikes}',
                  style: TextStyle(
                    color: isDisliked ? AppColors.red : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
