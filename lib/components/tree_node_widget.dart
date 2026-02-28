import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/person.dart';

/// Dark-themed tree node with gold glow border for the FamilyTreeScreen.
/// Circular avatar with name below; tap animation and selected glow effect.
class TreeNodeWidget extends StatefulWidget {
  final Person person;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const TreeNodeWidget({
    super.key,
    required this.person,
    this.size = 70,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<TreeNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final sz = widget.size;
    final hasImage = person.imageUrl != null && person.imageUrl!.isNotEmpty;
    final initials = person.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: child);
        },
        child: SizedBox(
          width: sz + 30,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with gold glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: sz,
                height: sz,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceLight,
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.accentGold
                        : AppTheme.accentGold.withOpacity(0.45),
                    width: widget.isSelected ? 3.5 : 2.5,
                  ),
                  boxShadow: [
                    if (widget.isSelected)
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.5),
                        blurRadius: 18,
                        spreadRadius: 3,
                      )
                    else
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.asset(
                          person.imageUrl!,
                          fit: BoxFit.cover,
                          width: sz,
                          height: sz,
                          errorBuilder: (_, __, ___) =>
                              _buildInitials(initials, sz),
                        )
                      : _buildInitials(initials, sz),
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                person.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.chip.copyWith(
                  fontSize: sz * 0.17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String initials, double sz) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: sz * 0.3,
          ),
        ),
      ),
    );
  }
}
