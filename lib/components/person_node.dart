import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/person.dart';

/// Reusable tappable person node for the family tree.
/// Shows a circular avatar with name below; animates on tap.
/// Updated to dark + gold design system.
class PersonNode extends StatefulWidget {
  final Person person;
  final double size;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const PersonNode({
    super.key,
    required this.person,
    this.size = 70,
    this.accentColor = const Color(0xFF8B4513),
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<PersonNode> createState() => _PersonNodeState();
}

class _PersonNodeState extends State<PersonNode>
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
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: SizedBox(
          width: sz + 30,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
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
                        : AppTheme.accentGold.withValues(alpha: 0.45),
                    width: widget.isSelected ? 3.5 : 2.5,
                  ),
                  boxShadow: [
                    if (widget.isSelected)
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: 2,
                      )
                    else
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
                              _initialsWidget(initials, sz),
                        )
                      : _initialsWidget(initials, sz),
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

  Widget _initialsWidget(String initials, double sz) {
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
